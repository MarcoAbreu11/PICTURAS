#!/usr/bin/env python3
"""Pipeline validation measurement through the public API.

For every scenario in scenarios.py it creates a premium user (permissions and
quota stay out of scope) and a project, runs the steps, and records where the
problem is first reported:

  setup    a step is refused (adding, reordering or deleting)
  editor   the project returned to the editor carries pipeline issues
  preview  the preview request is refused
  preview-worker / worker  a worker reports the error after the request was accepted
  process  the process request is refused
  none     nothing reports it (results are produced or the run hangs)

Early detection means setup or editor. A message is specific when it names an
offending tool and actionable when it says what to do (see scenarios.py).
Valid scenarios must have every step accepted, no issues and, when executed,
the expected number of results.

Usage: python3 bench/pipeline/measure_pipeline.py --label baseline [--only INV-01,VAL-03]
Writes results/<label>-api-<date>.csv.
"""

import argparse
import csv
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "upload"))
import picturas_api as api  # noqa: E402
from scenarios import FIX_WORDS, SCENARIOS, TOOL_NAMES  # noqa: E402

SAMPLES = os.path.join(HERE, "..", "upload", "samples")
MEDIA = {"image": os.path.join(SAMPLES, "image.png"), "video": os.path.join(SAMPLES, "small.mp4")}
ISSUE_KEYS = ("pipelineIssues", "pipeline_issues", "issues", "warnings")
EARLY = {"setup", "editor"}


def projects_container():
    out = subprocess.run(["docker", "ps", "--filter", "label=com.docker.compose.service=projects",
                          "--format", "{{.Names}}"], capture_output=True, text=True).stdout.split()
    if not out:
        sys.exit("projects container not found; is the stack up?")
    return out[0]


def worker_errors(container, since):
    """Error replies the projects service logged since `since` (worker failures)."""
    out = subprocess.run(["docker", "logs", "--since", since, container], capture_output=True, text=True)
    errs = []
    for line in (out.stdout + out.stderr).splitlines():
        if '"status":"error"' in line.replace(" ", ""):
            try:
                errs.append(json.loads(line[line.index("{"):])["error"]["msg"])
            except (ValueError, KeyError, TypeError):
                errs.append(line.strip()[:300])
    return errs


class Run:
    def __init__(self):
        self.user, self.token = api.register("premium")
        self.project, _ = api.create_project(self.user, self.token)
        self.media = {}

    def version(self):
        return api.get_project(self.user, self.token, self.project)["version"]

    def tools(self):
        p = api.get_project(self.user, self.token, self.project)
        return sorted(p.get("tools", []), key=lambda t: t.get("position", 0))

    def call(self, method, path, body=None):
        """Returns (ok, message) for a project mutation."""
        try:
            api.request(method, f"/projects/{self.user}/{self.project}{path}", body, self.token,
                        headers={"X-Project-Version": self.version()})
            return True, ""
        except api.ApiError as e:
            return False, e.body if isinstance(e.body, str) else json.dumps(e.body)

    def step(self, step):
        kind = step[0]
        if kind == "upload":
            before = {i["_id"] for i in api.get_project(self.user, self.token, self.project)["imgs"]}
            r = api.upload(self.user, self.token, self.project, self.version(), MEDIA[step[1]], step[1])
            if r["status"] != 204:
                return False, str(r["body"])
            new = [i["_id"] for i in api.get_project(self.user, self.token, self.project)["imgs"]
                   if i["_id"] not in before]
            self.media[step[1]] = new[0]
            return True, ""
        if kind == "add":
            params = {k: (self.media["video"] if v == "$video" else v) for k, v in step[2].items()}
            return self.call("POST", "/tool", {"procedure": step[1], "params": params})
        if kind == "delete_media":
            return self.call("DELETE", f"/img/{self.media[step[1]]}")
        if kind == "delete_tool":
            tool = next(t for t in self.tools() if t["procedure"] == step[1])
            return self.call("DELETE", f"/tool/{tool['_id']}")
        if kind == "reorder":
            by_name = {t["procedure"]: t for t in self.tools()}
            body = [{k: v for k, v in by_name[n].items() if k != "position"} for n in step[1]]
            return self.call("POST", "/reorder", body)
        raise ValueError(step)

    def issues(self):
        p = api.get_project(self.user, self.token, self.project)
        for k in ISSUE_KEYS:
            if p.get(k):
                return p[k]
        return []

    def results(self):
        return api.request("GET", f"/projects/{self.user}/{self.project}/process/url", token=self.token)[2]


def classify(message, offending):
    m = (message or "").lower()
    specific = any(alias in m for t in offending for alias in TOOL_NAMES.get(t, [t]))
    # tool names such as bg_remove_ai must not count as an instruction to remove
    for aliases in TOOL_NAMES.values():
        for alias in aliases:
            m = m.replace(alias, " ")
    actionable = any(w in m for w in FIX_WORDS)
    return specific, actionable


def run_scenario(sc, container):
    since = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    run = Run()
    row = {"id": sc["id"], "valid": sc["valid"], "title": sc["title"], "stage": "none", "message": "",
           "steps_refused": 0, "results": "", "expected_results": sc.get("results", "")}

    for st in sc["steps"]:
        ok, msg = run.step(st)
        if not ok:
            row["steps_refused"] += 1
            if row["stage"] == "none":
                row["stage"], row["message"] = "setup", f"{st[0]} {st[1] if len(st) > 1 else ''}: {msg}"

    if row["stage"] == "none":
        issues = run.issues()
        if issues:
            row["stage"], row["message"] = "editor", json.dumps(issues)

    if sc.get("ui_only"):
        row["stage"] = row["stage"] if row["stage"] != "none" else "n/a (ui only)"
    elif not sc["valid"] and row["stage"] == "none":
        target = run.media.get(sc["preview_on"]) or next(iter(run.media.values()), None)
        try:
            api.request("POST", f"/projects/{run.user}/{run.project}/preview/{target}", {}, run.token)
            deadline = time.time() + 20
            while time.time() < deadline and not worker_errors(container, since):
                time.sleep(2)
            errs = worker_errors(container, since)
            if errs:
                row["stage"], row["message"] = "preview-worker", errs[0]
        except api.ApiError as e:
            row["stage"], row["message"] = "preview", str(e.body)

    run_process = row["stage"] == "none" and (not sc["valid"] or sc.get("execute"))
    if sc["valid"] and row["stage"] not in ("none",):
        run_process = False
    if run_process:
        ok, msg = run.call("POST", "/process", {})
        if not ok:
            if not sc["valid"]:
                row["stage"], row["message"] = "process", msg
            else:
                row["message"] = f"process refused: {msg}"
        else:
            expected = sc.get("results", 1)
            deadline = time.time() + (180 if sc["valid"] else 60)
            got = 0
            while time.time() < deadline:
                got = len(run.results().get("imgs", [])) + len(run.results().get("texts", []))
                if got >= expected:
                    break
                errs = worker_errors(container, since)
                if errs:
                    if not sc["valid"]:
                        row["stage"], row["message"] = "worker", errs[0]
                    else:
                        row["message"] = f"worker error: {errs[0]}"
                    break
                time.sleep(3)
            row["results"] = got

    if sc["valid"]:
        accepted = row["steps_refused"] == 0 and row["stage"] == "none"
        executed = (not sc.get("execute")) or (row["results"] != "" and row["results"] >= sc["results"])
        row["valid_ok"] = int(accepted and executed and not row["message"])
        row["early"] = row["specific"] = row["actionable"] = row["useful_early_warning"] = ""
    else:
        specific, actionable = classify(row["message"], sc["offending"])
        early = row["stage"] in EARLY
        row.update(early=int(early), specific=int(specific), actionable=int(actionable),
                   useful_early_warning=int(early and specific and actionable), valid_ok="")
    return row


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--label", required=True)
    p.add_argument("--only", default="", help="comma-separated scenario ids")
    args = p.parse_args()

    container = projects_container()
    os.makedirs(os.path.join(HERE, "results"), exist_ok=True)
    out = os.path.join(HERE, "results", f"{args.label}-api-{datetime.now():%Y%m%d-%H%M%S}.csv")
    commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], capture_output=True, text=True,
                            cwd=HERE).stdout.strip()
    only = set(filter(None, args.only.split(",")))
    fields = ["label", "commit", "id", "valid", "title", "stage", "early", "specific", "actionable",
              "useful_early_warning", "valid_ok", "steps_refused", "results", "expected_results", "message"]
    rows = []
    with open(out, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for sc in SCENARIOS:
            if only and sc["id"] not in only:
                continue
            row = run_scenario(sc, container)
            row.update(label=args.label, commit=commit)
            w.writerow(row)
            f.flush()
            rows.append(row)
            flag = (f"valid_ok={row['valid_ok']}" if sc["valid"]
                    else f"early={row['early']} specific={row['specific']} actionable={row['actionable']}")
            print(f"{row['id']}: stage={row['stage']:<15} {flag}  {row['message'][:110]}", flush=True)

    inv = [r for r in rows if not r["valid"] and r["stage"] != "n/a (ui only)"]
    val = [r for r in rows if r["valid"]]
    if inv:
        print(f"\ninvalid (API): {sum(r['useful_early_warning'] for r in inv)}/{len(inv)} with a useful early warning")
    if val:
        print(f"valid: {sum(r['valid_ok'] for r in val)}/{len(val)} accepted and working")
    print(f"results: {out}")


if __name__ == "__main__":
    main()
