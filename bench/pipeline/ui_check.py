#!/usr/bin/env python3
"""Pipeline validation measurement in the editor (the user interface).

For every scenario it builds the project state through the API (as in
measure_pipeline.py, except the last step of the scenarios in UI_ACTIONS,
which is done in the browser), then opens the editor with Playwright, selects
the media named by `preview_on` and collects what the editor shows before any
preview or processing is requested:

  * warnings: notifications (role=alert / role=status, e.g. toasts) and
    inline error text (red / destructive text, e.g. form validation);
  * informative notes (role=note), e.g. why some tools are not offered;
  * the tools offered in the toolbar, with any title or description.

An invalid scenario counts as warned when a warning or note names an
offending tool (or comes from that tool's own form) and says what to do. A
valid scenario must show no warning; notes are allowed. Screenshots go to results/screens/ (not versioned).

The browser runs in the official Playwright image, on the host network:
  python3 bench/pipeline/ui_check.py --label baseline [--only INV-01]
Writes results/<label>-ui-<date>.csv.
"""

import argparse
import csv
import json
import os
import subprocess
import sys
import uuid
from datetime import datetime

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import measure_pipeline as mp  # noqa: E402
from scenarios import SCENARIOS, TOOL_NAMES, UI_ACTIONS, FIX_WORDS  # noqa: E402

api = mp.api
# Official Playwright image plus the matching Python package (see README.md)
PLAYWRIGHT_IMAGE = "picturasbench-playwright:1.49.0"


class UiRun(mp.Run):
    """A run whose user can also log in through the login form."""

    def __init__(self):
        self.email = f"ui-{uuid.uuid4().hex[:12]}@example.test"
        self.password = uuid.uuid4().hex
        api.request("POST", "/users/", {"name": "ui", "email": self.email, "password": self.password,
                                         "type": "premium"})
        _, _, data = api.request("POST", f"/users/{self.email}/login", {"password": self.password})
        self.user, self.token = str(data["user"]["_id"]), data["jwt"]
        self.project, _ = api.create_project(self.user, self.token)
        self.media = {}


def setup(sc):
    run = UiRun()
    action = UI_ACTIONS.get(sc["id"])
    steps = sc["steps"][:-1] if action else sc["steps"]
    refused = [st for st in steps if not run.step(st)[0]]
    imgs = [i["_id"] for i in api.get_project(run.user, run.token, run.project)["imgs"]]
    target = run.media.get(sc["preview_on"])
    ui_params = None
    if action == "trim":
        ui_params = {"start": sc["ui_trim"][0], "end": sc["ui_trim"][1]}
    if action == "reorder":
        ui_params = {"drag": sc["steps"][-1][1][0], "above": sc["steps"][-1][1][1]}
    return {
        "id": sc["id"], "email": run.email, "password": run.password, "project": run.project,
        "index": imgs.index(target) if target in imgs else 0, "action": action, "ui_params": ui_params,
        "setup_refused": len(refused),
    }


def warned(evidence, offending, own_form):
    """(specific, actionable) for the best piece of evidence."""
    best = (False, False)
    for text in evidence:
        spec, act = mp.classify(text, offending)
        spec = spec or own_form
        if (spec, act) > best:
            best = (spec, act)
    return best


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--label", required=True)
    p.add_argument("--only", default="")
    args = p.parse_args()
    only = set(filter(None, args.only.split(",")))
    scenarios = [s for s in SCENARIOS if not only or s["id"] in only]

    stamp = f"{datetime.now():%Y%m%d-%H%M%S}"
    work = os.path.join(HERE, "results", f".ui-{stamp}")
    screens = os.path.join(HERE, "results", "screens", f"{args.label}-{stamp}")
    os.makedirs(work, exist_ok=True)
    os.makedirs(screens, exist_ok=True)

    states = []
    for sc in scenarios:
        states.append(setup(sc))
        print(f"set up {sc['id']}", flush=True)
    with open(os.path.join(work, "states.json"), "w") as f:
        json.dump(states, f)

    # ":z" relabels the mounts on SELinux hosts (e.g. Fedora); elsewhere it is ignored.
    # Rootless Podman (behind the docker CLI) needs keep-id so that --user maps
    # to the host user and the browser can write the evidence and screenshots.
    version = subprocess.run(["docker", "--version"], capture_output=True, text=True).stdout.lower()
    userns = ["--userns=keep-id"] if "podman" in version else []
    cmd = ["docker", "run", "--rm", *userns, "--network", "host", "--user", f"{os.getuid()}:{os.getgid()}",
           "-e", "HOME=/tmp", "-v", f"{HERE}:/bench:ro,z", "-v", f"{work}:/work:z", "-v", f"{screens}:/screens:z",
           PLAYWRIGHT_IMAGE, "python", "-I", "/bench/ui_browse.py", "/work/states.json", "/work/evidence.json",
           "/screens"]
    subprocess.run(cmd, check=True)
    with open(os.path.join(work, "evidence.json")) as f:
        evidence = {e["id"]: e for e in json.load(f)}

    commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], capture_output=True, text=True,
                            cwd=HERE).stdout.strip()
    out = os.path.join(HERE, "results", f"{args.label}-ui-{stamp}.csv")
    fields = ["label", "commit", "id", "valid", "title", "ui_action", "warned", "specific", "actionable",
              "false_warning", "evidence", "notes", "toolbar", "error"]
    rows = []
    with open(out, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for sc in scenarios:
            ev = evidence.get(sc["id"], {})
            texts = ev.get("evidence", [])
            notes = ev.get("notes", [])
            row = {"label": args.label, "commit": commit, "id": sc["id"], "valid": sc["valid"],
                   "title": sc["title"], "ui_action": UI_ACTIONS.get(sc["id"], ""),
                   "evidence": " | ".join(texts), "notes": " | ".join(notes), "toolbar": ", ".join(ev.get("toolbar", [])),
                   "error": ev.get("error", "")}
            if sc["valid"]:
                row.update(false_warning=int(bool(texts)), warned="", specific="", actionable="")
            else:
                own_form = UI_ACTIONS.get(sc["id"]) == "trim" and bool(texts)
                spec, act = warned(texts + notes, sc["offending"], own_form)
                row.update(warned=int(spec and act), specific=int(spec), actionable=int(act), false_warning="")
            w.writerow(row)
            rows.append(row)
            print(f"{sc['id']}: " + (f"false_warning={row['false_warning']}" if sc["valid"]
                                    else f"warned={row['warned']}") + f"  {(row['evidence'] or row['notes'])[:110]}"
                  + (f"  ERROR {row['error']}" if row["error"] else ""), flush=True)

    inv = [r for r in rows if not r["valid"]]
    val = [r for r in rows if r["valid"]]
    if inv:
        print(f"\ninvalid (editor): {sum(r['warned'] for r in inv)}/{len(inv)} warned before preview/processing")
    if val:
        print(f"valid (editor): {sum(1 for r in val if not r['false_warning'])}/{len(val)} without a warning")
    print(f"results: {out}\nscreens: {screens}")


if __name__ == "__main__":
    main()
