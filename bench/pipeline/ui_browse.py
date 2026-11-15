"""Browser side of ui_check.py; runs inside the Playwright image.

Usage: python ui_browse.py states.json evidence.json screens_dir
"""

import json
import sys

from playwright.sync_api import sync_playwright

BASE = "https://localhost:8080"

# What the editor shows: warnings (notifications and inline error text) and
# informative notes (role=note, e.g. why some tools are not offered)
EVIDENCE_JS = """() => {
  const collect = (sel) => {
    const out = [];
    for (const el of document.querySelectorAll(sel)) {
      const t = (el.innerText || '').trim().replace(/\\s+/g, ' ');
      if (t && el.offsetParent !== null && !out.includes(t)) out.push(t);
    }
    return out;
  };
  // toasts are open <li> items of the toast viewport; destructive ones carry bg-destructive
  return {
    alerts: collect('[role=alert], [role=status], li[data-state=open], [class*="destructive"], [class*="text-red-"]'),
    notes: collect('[role=note]'),
  };
}"""

# The tools offered in the toolbar, with any explanation attached to them
TOOLBAR_JS = """() => {
  const bar = [...document.querySelectorAll('span')].find(s => s.innerText === 'Tools');
  if (!bar) return [];
  const out = [];
  for (const b of bar.parentElement.querySelectorAll('button')) {
    const name = (b.querySelector('.sr-only')?.innerText || '').trim();
    if (!name) continue;
    const extra = [b.disabled ? 'disabled' : '', b.title, b.getAttribute('aria-description') || ''];
    const desc = b.getAttribute('aria-describedby');
    if (desc) extra.push(document.getElementById(desc)?.innerText || '');
    out.push([name, ...extra.filter(Boolean)].join(' / '));
  }
  return out;
}"""


def browse(page, st, screens):
    page.goto(f"{BASE}/login")
    page.fill("#email", st["email"])
    page.fill("#password", st["password"])
    page.click("button[type=submit]")
    page.wait_for_url("**/dashboard**", timeout=30000)
    page.goto(f"{BASE}/dashboard/{st['project']}?view=carousel")
    page.get_by_text("Tools", exact=True).wait_for(timeout=30000)
    for _ in range(st["index"]):
        page.get_by_role("button", name="Next slide").click()
        page.wait_for_timeout(500)
    page.wait_for_timeout(2500)

    if st["action"] == "trim":
        page.get_by_role("button", name="Trim (this video)").click()
        # the trim form is a popover; its inputs follow the "Start (s)" / "End (s)" labels
        page.get_by_text("Start (s)", exact=True).locator("xpath=following::input[1]").fill(
            str(st["ui_params"]["start"]))
        page.get_by_text("End (s)", exact=True).locator("xpath=following::input[1]").fill(
            str(st["ui_params"]["end"]))
        page.wait_for_timeout(1000)
    elif st["action"] == "reorder":
        def grip(name):
            # drag handle of the applied-tools item whose label is `name`
            return page.locator(
                f"xpath=//span[normalize-space()='{name}']/ancestor::div[2]//*[contains(@class,'cursor-grab')]"
            ).first.bounding_box()
        src, dst = grip(st["ui_params"]["drag"]), grip(st["ui_params"]["above"])
        page.mouse.move(src["x"] + src["width"] / 2, src["y"] + src["height"] / 2)
        page.mouse.down()
        for i in range(1, 16):
            page.mouse.move(src["x"] + src["width"] / 2, src["y"] + (dst["y"] - 8 - src["y"]) * i / 15)
            page.wait_for_timeout(30)
        page.mouse.up()
        page.wait_for_timeout(3000)

    page.screenshot(path=f"{screens}/{st['id']}.png", full_page=True)
    ev = page.evaluate(EVIDENCE_JS)
    return {"evidence": ev["alerts"], "notes": ev["notes"], "toolbar": page.evaluate(TOOLBAR_JS)}


def main(states_path, out_path, screens):
    with open(states_path) as f:
        states = json.load(f)
    results = []
    with sync_playwright() as pw:
        browser = pw.chromium.launch()
        for st in states:
            ctx = browser.new_context(ignore_https_errors=True, viewport={"width": 1440, "height": 900})
            page = ctx.new_page()
            try:
                res = browse(page, st, screens)
            except Exception as e:  # keep going; the error is recorded
                try:
                    page.screenshot(path=f"{screens}/{st['id']}-error.png", full_page=True)
                except Exception:
                    pass
                res = {"evidence": [], "notes": [], "toolbar": [], "error": str(e).splitlines()[0][:300]}
            res["id"] = st["id"]
            results.append(res)
            print(f"browsed {st['id']}" + (f" ERROR {res['error']}" if res.get("error") else ""), flush=True)
            ctx.close()
        browser.close()
    with open(out_path, "w") as f:
        json.dump(results, f)


if __name__ == "__main__":
    main(*sys.argv[1:4])
