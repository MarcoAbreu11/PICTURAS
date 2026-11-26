# Pipeline validation: scenarios and measurement

Measurement material for the non-functional requirement **usability / user
error protection when building pipelines** (ISO/IEC 25010:2011): how many
invalid pipeline configurations the editor reports **before** the user asks
for a preview or runs the processing, with a specific message that says what
to do, without rejecting valid configurations.

Scope: compatibility between tools and media types and the order of the
pipeline. Permissions and quotas are out of scope; every scenario uses a
premium user.

## Scenario catalogue

Defined in `scenarios.py`. Media: one image (`image.png`) and one 5 s video
(`small.mp4`), from `bench/upload/samples/` (`bench/upload/make_samples.sh`).

| Id | Media | How the user gets there | Offending tool |
| --- | --- | --- | --- |
| INV-01 | image + video | AI background removal added to an image project, then a video is added | `bg_remove_ai` |
| INV-02 | image + video | Watermark added, then a video is added | `watermark` |
| INV-03 | image + video | Brightness and AI upgrade, then a video is added | `upgrade_ai` |
| INV-04 | video | AI text detection added to an empty project, then a video is added | `text_ai` |
| INV-05 | image + video | The user looks for an AI tool to use on the image (editor only) | `cut_ai` (any AI tool) |
| INV-06 | image | Trim on the video, then the video is deleted | `trim` |
| INV-07 | image | Subtitles, then the video is deleted | `subtitles` |
| INV-08 | image | Frame extraction, then the video is deleted | `extract_frames` |
| INV-09 | video | An effect is dragged below frame extraction | `extract_frames` |
| INV-10 | video | Trim end typed beyond the video duration | `trim` |
| VAL-01 | image | Brightness | |
| VAL-02 | image | Brightness and border | |
| VAL-03 | video | Brightness and trim | |
| VAL-04 | video | Contrast and speed | |
| VAL-05 | video | Brightness and frame extraction | |
| VAL-06 | image + video | Brightness and trim (the image skips trim) | |
| VAL-07 | image + video | Border and frame extraction (the image skips extraction) | |
| VAL-08 | image | AI background removal (accepted only; AI services are not started) | |
| VAL-09 | image + video | Brightness, then a video is added | |
| VAL-10 | image + video | INV-01 corrected: the AI tool is removed, brightness added | |
| VAL-11 | image | INV-06 corrected: trim is removed, brightness added | |

VAL-10 and VAL-11 check that a user can correct an incompatible pipeline:
earlier validation must not block those steps.

## Criteria

For an invalid scenario, a **useful early warning** must meet three
conditions:

1. **Early.** It appears while the pipeline is being built (a refused step, or
   a warning shown in the editor), before any preview or processing request.
2. **Specific.** It names the offending tool, or it is shown in that tool's
   own form.
3. **Actionable.** It says what to do or which limit to respect (the word lists
   are in `scenarios.py`).

For a valid scenario: every step is accepted, no warning is shown and, when
executed, the expected number of results is produced.

Main indicator: the percentage of invalid scenarios with a useful early
warning in the **editor** (`ui_check.py`). `measure_pipeline.py` measures the
same thing at the API, where the backend reports each problem, and runs the
valid scenarios end to end.

## Running

Start the stack with at least `nginx frontend api_gateway ws_gateway seaweedfs
img_storage rabbitmq projects projects_mongoDB users users_mongoDB
subscriptions subscriptions_mongoDB brightness_tool contrast_tool border_tool
video_tool`. Then run:

```bash
python3 bench/pipeline/measure_pipeline.py --label baseline   # API, ~3 min
python3 bench/pipeline/ui_check.py --label baseline           # editor, ~2 min
```

`ui_check.py` drives Chromium through Playwright in Docker (host network).
Build the image once:

```bash
printf 'FROM mcr.microsoft.com/playwright/python:v1.49.0-noble\nRUN pip install --no-cache-dir --break-system-packages playwright==1.49.0\n' \
  | docker build -t picturasbench-playwright:1.49.0 -
```

The scripts write `results/<label>-api-<date>.csv` and
`results/<label>-ui-<date>.csv`. The editor screenshots go to
`results/screens/` and are not versioned. Run the same commands with
`--label final` after the refactoring.

### What the editor check records

`ui_check.py` collects:

- warnings: toasts, `role=alert` / `role=status` elements and inline error
  text (red or destructive text, such as form validation);
- informative notes (`role=note`), such as why some tools are not offered;
- the tools offered in the toolbar, with any title or description.

For an invalid scenario, a warning or a note can count as the explanation. A
valid scenario must show no warning, but notes are allowed. A warning added by
the refactoring must use one of these forms; `role="alert"` is the natural
choice and also helps screen readers.

## Preview in a mixed project

`preview_mixed_check.py` checks the case the scenarios above do not cover: an
image-only tool (watermark) configured before a video is added. The video
preview and the processing must be refused with the pipeline message, while
the image preview must still run, as in the base version. It needs
`watermark_tool_ms` running besides the services above:

```bash
python3 bench/pipeline/preview_mixed_check.py   # exit code 0 when all 8 checks pass
```
