#!/usr/bin/env python3
"""End-to-end regression checks for media upload (functional preservation).

Runs against the running stack through the public entry point and checks the
behaviour that the streaming refactoring must keep: accepted uploads, the
stored bytes, the metadata, the existing rejections and a pipeline run over an
image and a video. Exit code 0 when every check passes.

Usage: python3 bench/upload/regression.py   (after make_samples.sh)
"""

import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import picturas_api as api  # noqa: E402

SAMPLES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "samples")
results = []


def check(name, cond, detail=""):
    results.append(cond)
    print(f"{'PASS' if cond else 'FAIL'}  {name}" + (f"  ({detail})" if detail and not cond else ""), flush=True)


def sample(name):
    path = os.path.join(SAMPLES, name)
    if not os.path.exists(path):
        sys.exit(f"missing {path}; run bench/upload/make_samples.sh first")
    return path


def media_url(user, token, project, img_id):
    return api.request("GET", f"/projects/{user}/{project}/img/{img_id}", token=token)[2]["url"]


def main():
    image, video = sample("image.png"), sample("small.mp4")
    user, token = api.register("premium")
    project, version = api.create_project(user, token)

    # Accepted uploads
    r = api.upload(user, token, project, version, image, "image")
    check("image upload is accepted (204)", r["status"] == 204, r)
    version = r["version"] or version + 1
    check("image upload returns the new project version", r["version"] is not None, r)

    r = api.upload(user, token, project, version, video, "video")
    check("video upload is accepted (204)", r["status"] == 204, r)
    version = r["version"] or version + 1

    proj = api.get_project(user, token, project)
    imgs = {os.path.basename(i.get("og_uri") or i.get("name", "")): i for i in proj["imgs"]}
    by_name = {i.get("name"): i for i in proj["imgs"]}
    vid = imgs.get("small.mp4") or by_name.get("small.mp4")
    img = imgs.get("image.png") or by_name.get("image.png")
    check("both media are in the project", vid is not None and img is not None, proj["imgs"])

    if vid is not None:
        meta = vid.get("video") or {}
        check("video is stored with media_type 'video'", vid.get("media_type") == "video", vid)
        check("video metadata has the probed codec and duration",
              meta.get("video_codec") == "h264" and 4 < (meta.get("duration") or 0) < 6, meta)
        check("video metadata has the exact file size", meta.get("size_bytes") == os.path.getsize(video), meta)
        if "og_sha256" in vid:
            check("stored SHA-256 matches the file", vid["og_sha256"] == api.sha256_file(video), vid["og_sha256"])
        got = api.sha256_url(media_url(user, token, project, vid["_id"]))
        check("downloaded video is byte-identical to the upload", got == api.sha256_file(video))
    if img is not None:
        check("image is stored with media_type 'image'", img.get("media_type", "image") == "image", img)
        got = api.sha256_url(media_url(user, token, project, img["_id"]))
        check("downloaded image is byte-identical to the upload", got == api.sha256_file(image))

    # Existing rejections
    def rejected(name, path, kind, expect_status, expect_text, who=(user, token, project), field=None):
        nonlocal version
        u, t, pr = who
        v = version if pr == project else api.get_project(u, t, pr)["version"]
        r = api.upload(u, t, pr, v, path, kind, field=field)
        body = r["body"] if isinstance(r["body"], str) else str(r["body"])
        check(name, r["status"] == expect_status and expect_text in body, f"{r['status']} {body}")

    rejected("video sent to the image endpoint is rejected", video, "image", 400, "must be uploaded through the /video")
    rejected("image sent to the video endpoint is rejected", image, "video", 400, "Only video files")
    rejected("a duplicated name is rejected", video, "video", 400, "already has a video with that name")
    rejected("an unsupported codec is rejected", sample("wrong_codec.mp4"), "video", 400, "Unsupported video codec")
    rejected("a corrupted video is rejected", sample("corrupted.mp4"), "video", 400, "Unreadable or corrupted")

    free_user, free_token = api.register("free")
    free_project, _ = api.create_project(free_user, free_token)
    rejected("a video above the free profile size limit is rejected", sample("over_free_limit.mp4"), "video", 400,
             "your profile limit is 100 MB", who=(free_user, free_token, free_project))

    r = api.upload(user, None, project, version, video, "video")
    check("an upload without a token is refused (401)", r["status"] == 401, r)

    proj = api.get_project(user, token, project)
    check("rejected uploads left the project unchanged", len(proj["imgs"]) == 2, len(proj["imgs"]))

    # A pipeline over the uploaded image and video still runs
    version = proj["version"]
    st, hdr, _ = api.request("POST", f"/projects/{user}/{project}/tool",
                             {"procedure": "brightness", "params": {"brightness": 1.3}}, token,
                             headers={"X-Project-Version": version})
    version = int(hdr.get("X-Project-Version") or hdr.get("x-project-version") or version + 1)
    try:
        api.request("POST", f"/projects/{user}/{project}/process", {}, token,
                    headers={"X-Project-Version": version})
        started = True
    except api.ApiError as e:
        started = False
        check("processing starts", False, e)
    if started:
        deadline, out = time.time() + 300, []
        while time.time() < deadline:
            out = api.request("GET", f"/projects/{user}/{project}/process/url", token=token)[2].get("imgs", [])
            if len(out) >= 2:
                break
            time.sleep(3)
        check("the pipeline produced a result for the image and the video", len(out) >= 2, out)

    passed = sum(results)
    print(f"\n{passed}/{len(results)} checks passed")
    sys.exit(0 if passed == len(results) else 1)


if __name__ == "__main__":
    main()
