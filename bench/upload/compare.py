#!/usr/bin/env python3
"""Summarises measure_upload.py results: for each label, file size and
concurrency, the median and maximum memory growth per service, the sum over
the upload path, the upload time and the success rate.

Usage: python3 bench/upload/compare.py results/baseline-*.csv results/final-*.csv
"""

import csv
import statistics
import sys
from collections import defaultdict

SERVICES = ["api_gateway", "projects", "img_storage"]


def main(paths):
    groups = defaultdict(list)
    for p in paths:
        with open(p) as f:
            for row in csv.DictReader(f):
                groups[(row["label"], int(row["size_mb"]), int(row["concurrency"]))].append(row)

    head = ["label", "size", "conc", "runs", "ok"]
    head += [f"{s} med/max MB" for s in SERVICES] + ["path total med MB", "time med s"]
    print("| " + " | ".join(head) + " |")
    print("|" + "---|" * len(head))
    for (label, size, conc), rows in sorted(groups.items(), key=lambda k: (k[0][1], k[0][2], k[0][0])):
        ok = sum(int(r["ok"]) for r in rows)
        total = sum(int(r["ok"]) + int(r["failed"]) for r in rows)
        cells = [label, f"{size} MB", str(conc), str(len(rows)), f"{ok}/{total}"]
        path_totals = [sum(float(r[f"{s}_rss_growth_mb"]) for s in SERVICES) for r in rows]
        for s in SERVICES:
            g = [float(r[f"{s}_rss_growth_mb"]) for r in rows]
            cells.append(f"{statistics.median(g):.0f} / {max(g):.0f}")
        cells.append(f"{statistics.median(path_totals):.0f}")
        cells.append(f"{statistics.median(float(r['time_s_mean']) for r in rows):.1f}")
        print("| " + " | ".join(cells) + " |")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    main(sys.argv[1:])
