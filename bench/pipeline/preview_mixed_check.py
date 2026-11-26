#!/usr/bin/env python3
"""Preview of an image in a mixed project whose pipeline has an image-only tool.

Scenario (functional preservation of the pipeline rules): an image project gets
an image-only tool (watermark), then a video is added. The pipeline is invalid
for the video, so previewing or running the video must be refused with the
pipeline message. Previewing the *image* only applies the image effects, and
the base version (0523102) accepted it: it must still be accepted and produce a
preview.

Needs the stack with `watermark_tool_ms` and the samples of bench/upload/samples.
Exit code 0 when every check passes.
"""
import pathlib
import sys
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "upload"))
import picturas_api as api  # noqa: E402

SAMPLES = pathlib.Path(__file__).resolve().parent.parent / "upload" / "samples"
failures = 0


def check(name, ok, detail=""):
    global failures
    failures += 0 if ok else 1
    print(f"{'PASS' if ok else 'FAIL'}  {name}" + (f"  ({detail})" if detail else ""))


def post(run, path, body=None, version=False):
    headers = {"X-Project-Version": api.get_project(*run)["version"]} if version else None
    user, token, project = run[0], run[1], run[2]
    try:
        status, _, data = api.request("POST", f"/projects/{user}/{project}{path}", body or {}, token, headers=headers)
        return status, data
    except api.ApiError as e:
        return e.status, e.body


def main():
    user, token = api.register("premium")
    project, _ = api.create_project(user, token)
    run = (user, token, project)

    def version():
        return api.get_project(user, token, project)["version"]

    r = api.upload(user, token, project, version(), SAMPLES / "image.png", "image")
    check("image uploaded", r["status"] == 204, r["status"])
    status, body = post(run, "/tool", {"procedure": "watermark", "params": {}}, version=True)
    check("image-only tool added to the image project", status in (200, 201, 204), f"{status} {body}")
    r = api.upload(user, token, project, version(), SAMPLES / "small.mp4", "video")
    check("video uploaded afterwards (media changes are never blocked)", r["status"] == 204, r["status"])

    p = api.get_project(user, token, project)
    img = next(i["_id"] for i in p["imgs"] if i.get("media_type") != "video")
    vid = next(i["_id"] for i in p["imgs"] if i.get("media_type") == "video")
    issues = p.get("pipelineIssues") or []
    check("editor gets the pipeline issue for the watermark",
          any(i.get("procedure") == "watermark" and i.get("severity") == "error" for i in issues),
          "; ".join(i.get("message", "") for i in issues))

    status, body = post(run, f"/preview/{vid}")
    check("video preview refused with the pipeline message",
          status == 400 and "Watermark" in str(body), f"{status} {body}")

    status, body = post(run, f"/preview/{img}")
    check("image preview accepted (as in the base)", status in (200, 201, 202, 204), f"{status} {body}")

    # The preview is delivered over the websocket; a finished preview is cached,
    # so a second identical request is answered from the cache.
    hit = False
    if status in (200, 201, 202, 204):
        for _ in range(30):
            time.sleep(2)
            _, body2 = post(run, f"/preview/{img}")
            # projects answers "Created" when it dispatches a new preview and
            # "OK" when the finished preview is served from the cache (the
            # gateway always replies 201 and forwards that body)
            if body2 == "OK":
                hit = True
                break
    check("image preview produced (second request served from the preview cache)", hit)

    status, body = post(run, "/process", version=True)
    check("processing the mixed project refused, as in the base",
          status == 400 and "Watermark" in str(body), f"{status} {body}")

    print(f"\n{'all checks passed' if failures == 0 else f'{failures} check(s) failed'}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
