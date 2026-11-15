# Upload benchmark and regression checks

Measurement and regression material for the non-functional requirement
**performance efficiency / resource utilisation when uploading large files**
(ISO/IEC 25010:2011).

## What changed (summary)

Before, every service on the upload path held the whole file in memory
(`multer.memoryStorage()`): `api_gateway`, `projects` (which also wrote a second
copy to disk for `ffprobe` and hashed the buffer) and `img_storage`. A 1 GB
video therefore needed at least 3 GB of RAM while it was being uploaded.

Now the file is streamed:

| Hop | Before | After |
| --- | --- | --- |
| nginx | body written to a temporary file, then sent | streamed (`proxy_request_buffering off`) |
| `api_gateway` | parsed into memory, rebuilt as a new form; token checked after the upload | token checked first, raw body piped to `projects` |
| `projects` | in memory + temp copy for `ffprobe` + hash of the buffer | one temporary file, SHA-256 computed while writing; size limit checked from `Content-Length` before reading; file piped from disk to `img_storage`; temp file always removed |
| `img_storage` | in memory, then `s3.upload` | piped into a multipart `s3.upload` (5 MB parts, at most 2 in memory) |
| frontend | no feedback | upload progress bar in the import dialog |

Internal axios calls that send large bodies use `maxRedirects: 0`: with
redirects enabled axios keeps a copy of the whole body to replay it.

## Requirements

- the stack running (`docker compose up -d --build`) and reachable at
  `https://localhost:8080`;
- on the host: `python3` (standard library only), `curl`, `ffmpeg`/`ffprobe`
  and the `docker` CLI (Podman's Docker emulation works).

## 1. Generate the samples

```bash
bench/upload/make_samples.sh            # 100, 500 and 950 MB + fixtures (950 MB stays under the 1 GiB premium limit)
```

Files go to `bench/upload/samples/` (not versioned). Sizes are approximate;
the benchmark records the real size.

## 2. Regression checks

```bash
python3 bench/upload/regression.py
```

Checks accepted image/video uploads, the stored bytes (download and compare
SHA-256), the video metadata, the existing rejections (wrong endpoint,
duplicate name, codec, corrupted file, free profile size limit, no token) and
that a pipeline still runs over an image and a video. Exit code 0 when every
check passes.

## 3. Memory and time measurement

```bash
# one upload at a time, 5 repetitions per size, services restarted between runs
python3 bench/upload/measure_upload.py --label baseline --sizes 100,500,950 --reps 5
# simultaneous uploads
python3 bench/upload/measure_upload.py --label baseline --sizes 500 --reps 3 --concurrency 4
```

Each row of `results/<label>-c<N>-<date>.csv` has, per service, the resident
memory of its Node processes before the upload (`*_rss_base_mb`), the peak
during it (`*_rss_peak_mb`) and the difference (`*_rss_growth_mb`, the main
metric), plus the container memory from `docker stats` (`*_cgroup_peak_mb`,
which also counts page cache), the HTTP statuses and the upload time.

Run the same commands with `--label final` after the refactoring, on the same
machine and with the same stack configuration, and compare.

### Optional: fixed memory limits

To measure capacity under a fixed memory budget, start the stack with the
override file, which caps the three services at 512 MB each:

```bash
docker compose -f docker-compose.yaml -f bench/upload/compose.memlimit.yaml up -d
```

## Unit tests

Each service has `node:test` tests, including one that streams 256 MB through
the component and fails if memory grows by more than 64 MB:

```bash
cd projects && npm test              # also apiGateway/ and imageStorageService/
```
