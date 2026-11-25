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
| Baseline commit | `7590c4a` (API run) and `6129bfd` (editor run): same `projects` and `frontend` code, unchanged since the official base `0523102` |
| Final commit | `087cc9f` |
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

| Indicator | Baseline: API | Final: API | Baseline: editor | Final: editor |
| --- | --- | --- | --- | --- |
| Invalid scenarios with a useful early warning | 1/9 (11%) | **9/9 (100%)** | 2/10 (20%) | **10/10 (100%)** |
| Valid scenarios accepted and working / without a warning | 11/11 | 11/11 | 11/11 | 11/11 |

### Target

The targets were proposed before the baseline and kept after it: the baseline
warned early in 1/9 (API) and 2/10 (editor) invalid scenarios, so they are
demanding but reachable without changing what users can do.

| Criterion | Target | Minimum acceptable | Final API | Final editor | Met |
| --- | --- | --- | --- | --- | --- |
| Invalid scenarios with a useful early warning | ≥ 90% | ≥ 80% | 100% | 100% | yes |
| Valid scenarios rejected or warned | 0 | 0 | 0/11 | 0/11 | yes |

With the action-word list used before the extension described in the
measurement note below, the final API result is 8/9 (89%; only INV-10 does
not match): above the minimum and just under the target.

Upload regression checks (`bench/upload/regression.py`, which includes a
pipeline over an image and a video): 19/19. Unit tests of `projects`: 21/21,
8 of them new for the rules.

Per invalid scenario, what the editor now shows before any preview or run
(every pipeline issue is a `role="alert"` line above the editor; the
explanation of hidden tools is a `role="note"` line):

| Id | Warning in the editor |
| --- | --- |
| INV-01 to INV-04 | `<tool> only works on images, and this project has videos. Remove <tool> from the pipeline, or keep the videos in a separate project.` |
| INV-05 | `Not offered in this project: Watermark, AI Background Removal, … These tools work on images only, and this project has videos. To use them on the images, remove the videos or keep them in a separate project.` |
| INV-06 to INV-08 | `<tool> only applies to videos, and this project has none, so the pipeline has nothing to apply to the images. Remove <tool> and add an image effect, or add a video to the project.` |
| INV-09 | toast: `Frame extraction must be the last tool in the pipeline. Move Extract frames to the end of the pipeline.`; the applied list returns to the accepted order |
| INV-10 | the trim form (unchanged): `End exceeds the video duration (5.0 s).`; the API now also refuses the tool when it is added: `Trim ends at 8 s, but the video lasts 5 s. Open Trim and set an end time up to 5 s.` |

The valid scenarios with a video show the `role="note"` line about hidden
tools. It is information, not a warning about their pipeline, and the editor
check does not count it as a false warning (see `README.md`).

### What changed

- `projects/utils/pipelineRules.js` holds the compatibility rules. It judges
  one tool when it is added or edited, and the whole pipeline before a
  preview or a run. Errors block those actions; warnings (a video-only tool
  next to image effects in a project without videos, or a trim whose video
  was deleted) do not.
- Adding or editing a tool judges only that tool, so issues elsewhere in the
  pipeline never block a correction. Uploading or deleting media is never
  blocked; the issues appear in the editor instead (VAL-10 and VAL-11).
- The project response carries `pipelineIssues` and `unavailableTools`. The
  editor hides the unavailable tools, as before, and shows both lists in
  `PipelineNotices`, so the rules are no longer repeated in the frontend.
- Preview and processing give the same messages as the editor. They replace
  `No tools selected` (when only video effects remain) and `Effects not
  available for video: …`.

### Measurement note

After the first final run, the action-word list in `scenarios.py` was
extended with `set`, `choose`, `open` and `select a`: the final INV-10 message
("set an end time up to 5 s") is actionable, but no listed word matched it.
The stored baseline messages were classified again with the extended list
and none changed (API 1/9). The final CSVs above were produced with the
extended list.
