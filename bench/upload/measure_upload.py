#!/usr/bin/env python3
"""Upload benchmark for PictuRAS (non-functional requirement: resource
utilisation when uploading large files).

For each file size and repetition it creates a fresh project, uploads one
video through the public entry point (nginx -> api_gateway -> projects ->
img_storage -> SeaweedFS) and samples, every SAMPLE_S seconds, the memory of
the three Node services on the upload path:

  * rss_mb   - resident memory of the service's node processes (/proc VmRSS),
               the main metric: it is what the file costs in memory;
  * cgroup_mb - container memory as reported by `docker stats` (includes the
               page cache of files the service writes, shown for context).

Output: one CSV row per upload with the peak of each metric per service, the
upload time and the result. Same script, same machine and same stack
configuration for the baseline and the final measurement.

Usage:
  python3 bench/upload/measure_upload.py --label baseline --sizes 100,500,950 --reps 5
  python3 bench/upload/measure_upload.py --label baseline --sizes 500 --concurrency 4
"""

import argparse
import csv
import os
import platform
import subprocess
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import picturas_api as api  # noqa: E402

SERVICES = ["api_gateway", "projects", "img_storage"]
SAMPLE_S = 0.25
HERE = os.path.dirname(os.path.abspath(__file__))


def container_of(service):
    out = subprocess.run(
        ["docker", "ps", "--filter", f"label=com.docker.compose.service={service}", "--format", "{{.Names}}"],
        capture_output=True, text=True,
    ).stdout.split()
    if not out:
        sys.exit(f"container for service '{service}' not found; is the stack up?")
    return out[0]


def node_rss_mb(container):
    """Sum of VmRSS of the node processes inside a container, in MB."""
    script = "for f in /proc/[0-9]*/status; do grep -E '^(Name|VmRSS):' $f 2>/dev/null; done"
    out = subprocess.run(["docker", "exec", container, "sh", "-c", script], capture_output=True, text=True).stdout
    total_kb, name = 0, None
    for line in out.splitlines():
        if line.startswith("Name:"):
            name = line.split()[1]
        elif line.startswith("VmRSS:") and name and name.startswith("node"):
            total_kb += int(line.split()[1])
    return total_kb / 1024


_UNITS = {"b": 1, "kb": 1e3, "kib": 1024, "mb": 1e6, "mib": 1024**2, "gb": 1e9, "gib": 1024**3}


def cgroup_mb(containers):
    out = subprocess.run(
        ["docker", "stats", "--no-stream", "--format", "{{.Name}};{{.MemUsage}}", *containers],
        capture_output=True, text=True,
    ).stdout
    res = {}
    for line in out.splitlines():
        if ";" not in line:
            continue
        name, usage = line.split(";", 1)
        used = usage.split("/")[0].strip().replace(" ", "")
        num = "".join(ch for ch in used if ch.isdigit() or ch == ".")
        unit = used[len(num):].lower() or "b"
        try:
            res[name] = float(num) * _UNITS.get(unit, 1) / 1024**2
        except ValueError:
            pass
    return res


class Sampler:
    """Samples memory of the upload-path containers in background threads."""

    def __init__(self, containers):
        self.containers = containers
        self.peak_rss = {c: 0.0 for c in containers}
        self.base_rss = {c: node_rss_mb(c) for c in containers}
        self.peak_cg = {c: 0.0 for c in containers}
        self._stop = threading.Event()
        self._threads = [threading.Thread(target=self._rss_loop, args=(c,), daemon=True) for c in containers]
        self._threads.append(threading.Thread(target=self._cg_loop, daemon=True))

    def _rss_loop(self, c):
        while not self._stop.is_set():
            self.peak_rss[c] = max(self.peak_rss[c], node_rss_mb(c))
            time.sleep(SAMPLE_S)

    def _cg_loop(self):
        while not self._stop.is_set():
            for c, v in cgroup_mb(self.containers).items():
                if c in self.peak_cg:
                    self.peak_cg[c] = max(self.peak_cg[c], v)

    def __enter__(self):
        for t in self._threads:
            t.start()
        return self

    def __exit__(self, *exc):
        self._stop.set()
        for t in self._threads:
            t.join(timeout=10)


def restart_services(services):
    subprocess.run(["docker", "compose", "restart", *services], check=True, capture_output=True)
    # nginx resolves its upstreams once at start; restarted containers may get
    # new addresses, so restart it too (otherwise every request is a 502)
    subprocess.run(["docker", "compose", "restart", "nginx"], check=True, capture_output=True)
    deadline = time.time() + 120
    while time.time() < deadline:
        try:
            api.register("free")
            return
        except Exception:
            time.sleep(2)
    sys.exit("stack did not come back after restart")


def one_upload(path):
    user, token = api.register("premium")
    project, version = api.create_project(user, token)
    return api.upload(user, token, project, version, path, "video")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--label", required=True, help="e.g. baseline or final")
    p.add_argument("--sizes", default="100,500,950", help="sample sizes in MB (see make_samples.sh)")
    p.add_argument("--reps", type=int, default=5)
    p.add_argument("--concurrency", type=int, default=1, help="simultaneous uploads per run")
    p.add_argument("--no-restart", action="store_true", help="do not restart the services between runs")
    p.add_argument("--out", default=None)
    args = p.parse_args()

    containers = {s: container_of(s) for s in SERVICES}
    os.makedirs(os.path.join(HERE, "results"), exist_ok=True)
    out = args.out or os.path.join(
        HERE, "results", f"{args.label}-c{args.concurrency}-{datetime.now():%Y%m%d-%H%M%S}.csv"
    )
    commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], capture_output=True, text=True).stdout.strip()

    fields = ["label", "commit", "host", "size_mb", "file_bytes", "rep", "concurrency", "ok", "failed",
              "statuses", "time_s_max", "time_s_mean"]
    for s in SERVICES:
        fields += [f"{s}_rss_base_mb", f"{s}_rss_peak_mb", f"{s}_rss_growth_mb", f"{s}_cgroup_peak_mb"]

    with open(out, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for size in [int(x) for x in args.sizes.split(",")]:
            path = os.path.join(HERE, "samples", f"video_{size}mb.mp4")
            if not os.path.exists(path):
                sys.exit(f"missing {path}; run make_samples.sh {size}")
            for rep in range(1, args.reps + 1):
                if not args.no_restart:
                    restart_services(SERVICES)
                    containers = {s: container_of(s) for s in SERVICES}
                    time.sleep(3)
                with Sampler(list(containers.values())) as sampler:
                    with ThreadPoolExecutor(args.concurrency) as pool:
                        results = list(pool.map(one_upload, [path] * args.concurrency))
                    time.sleep(1)  # catch the memory right after the reply
                ok = sum(1 for r in results if r["status"] == 204)
                row = {
                    "label": args.label, "commit": commit, "host": platform.node(), "size_mb": size,
                    "file_bytes": os.path.getsize(path), "rep": rep, "concurrency": args.concurrency,
                    "ok": ok, "failed": len(results) - ok,
                    "statuses": " ".join(str(r["status"]) for r in results),
                    "time_s_max": round(max(r["time_s"] for r in results), 2),
                    "time_s_mean": round(sum(r["time_s"] for r in results) / len(results), 2),
                }
                for s, c in containers.items():
                    row[f"{s}_rss_base_mb"] = round(sampler.base_rss[c], 1)
                    row[f"{s}_rss_peak_mb"] = round(sampler.peak_rss[c], 1)
                    row[f"{s}_rss_growth_mb"] = round(sampler.peak_rss[c] - sampler.base_rss[c], 1)
                    row[f"{s}_cgroup_peak_mb"] = round(sampler.peak_cg[c], 1)
                w.writerow(row)
                f.flush()
                print(
                    f"{size} MB rep {rep}: ok={ok}/{len(results)} t={row['time_s_max']} s  "
                    + "  ".join(f"{s} +{row[f'{s}_rss_growth_mb']} MB" for s in SERVICES),
                    flush=True,
                )
                for r in results:
                    if r["status"] != 204:
                        print(f"  failure: HTTP {r['status']} curl={r['curl_exit']} {r['body']}", flush=True)
    print(f"results: {out}")


if __name__ == "__main__":
    main()
