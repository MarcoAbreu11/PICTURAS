# Pipeline validation results

Non-functional requirement: **usability / user error protection when building
pipelines** (ISO/IEC 25010:2011). Scenarios and criteria are in `README.md`;
the raw data is in `results/*.csv` (one row per scenario).

## Environment

Same machine as `bench/upload/RESULTS.md`: Intel Core Ultra 7 356H, Ubuntu
26.04.1 LTS on WSL2, Docker Engine 29.9.2, Docker Compose v5.6.1. The editor
was checked in Chromium (Playwright 1.49.0), at 1440 × 900.

| Item | Value |
| --- | --- |
| Baseline commit | `7590c4a` (the pipeline code is unchanged since the official base `0523102`) |
| Final commit | _to be filled in after the refactoring_ |
| Date | 2026-11-15 |

## Baseline

| Indicator | API (`measure_pipeline.py`) | Editor (`ui_check.py`) |
| --- | --- | --- |
| Invalid scenarios with a useful early warning | **1/9 (11%)** | **2/10 (20%)** |
| Valid scenarios accepted and working | 11/11 | 11/11 without a warning |

Per scenario:

| Id | Where the problem is first reported (API) | Message | Editor, before preview/processing |
| --- | --- | --- | --- |
| INV-01 | preview request refused | `Effects not available for video: bg_remove_ai` | nothing; the AI tool stays in the applied list and the AI tools disappear from the toolbar |
| INV-02 | preview request refused | `Effects not available for video: watermark` | nothing |
| INV-03 | preview request refused | `Effects not available for video: upgrade_ai` | nothing |
| INV-04 | preview request refused | `Effects not available for video: text_ai` | nothing |
| INV-05 | (editor only) | | AI tools are not offered and nothing says why |
| INV-06 | preview request refused | `No tools selected` (the pipeline has `trim`) | nothing; `trim` stays in the list of an image-only project |
| INV-07 | preview request refused | `No tools selected` (the pipeline has `subtitles`) | nothing |
| INV-08 | preview request refused | `No tools selected` (the pipeline has `extract_frames`) | nothing |
| INV-09 | reorder refused | `Frame extraction must be the last tool in the pipeline` | toast with that message ✔ |
| INV-10 | video worker, after the preview was accepted | `Trim [1.0, 8.0] s is outside the video duration (5.00 s)` | the trim form shows `End exceeds the video duration (5.0 s).` ✔ |

The API and editor counts differ in one scenario, INV-10. The editor
validates the trim times in the form, so the user is warned before saving. The
backend accepts the same values and only the video worker rejects them.

### Other findings

- **Late, uninformative messages.** When a deleted video leaves only video
  effects in the pipeline (INV-06 to INV-08), the preview answers
  `No tools selected`, although the pipeline is not empty. `/process` gives a
  better message (`The pipeline only has video effects and the project has no
  videos`), but only when the user runs the pipeline.
- **No validation when adding a tool.** Of the tool rules, `POST /tool` checks
  only frame extraction. An AI tool is accepted in a project with videos, and a
  trim end beyond the duration is accepted, until a preview, the processing
  or the worker refuses it.
- **Stale order after a refused reorder.** In INV-09 the backend refuses the
  new order and the editor shows the error. The applied-tools list, however,
  still showed the refused order 3 s after the error, when the screenshot was
  taken: the optimistic update is not reverted on error.
- **Hidden tools.** In a project with videos the watermark and the 7 AI tools
  are removed from the toolbar, for the images as well, with no explanation.

## Final

_To be filled in after the refactoring, with `--label final`._
