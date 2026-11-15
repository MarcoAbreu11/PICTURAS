"""Scenario catalogue for the pipeline validation measurement (non-functional
requirement: usability / user error protection, ISO/IEC 25010:2011).

Each scenario is a state a user can reach through the editor: the media of the
project and the steps that build the pipeline, in order. Invalid scenarios
name the tools that make them invalid (`offending`), so a warning can be
checked for being specific. Valid scenarios must be accepted without warnings
and, when `execute` is true, must produce results.

Media: "image" is samples/image.png, "video" is samples/small.mp4 (5 s).

Step forms:
  ("upload", "image" | "video")
  ("add", procedure, params)       params may use "$video" for the video's id
  ("delete_media", "image" | "video")
  ("delete_tool", procedure)
  ("reorder", [procedure, ...])    the new order of the pipeline
"""

BRIGHT = ("add", "brightness", {"brightness": 1.3})
CONTRAST = ("add", "contrast", {"contrastFactor": 1.4})
BORDER = ("add", "border", {"borderWidth": 10, "r": 255, "g": 0, "b": 0})
TRIM_OK = ("add", "trim", {"start": 1, "end": 3, "imgId": "$video"})
SPEED = ("add", "speed", {"factor": 2, "imgId": "$video"})
FRAMES = ("add", "extract_frames", {"mode": "count", "count": 3, "format": "png"})

SCENARIOS = [
    # ---- invalid -------------------------------------------------------
    {
        "id": "INV-01", "valid": False, "offending": ["bg_remove_ai"], "preview_on": "video",
        "title": "Image project with an AI tool, then a video is added",
        "steps": [("upload", "image"), ("add", "bg_remove_ai", {}), ("upload", "video")],
    },
    {
        "id": "INV-02", "valid": False, "offending": ["watermark"], "preview_on": "video",
        "title": "Image project with watermark, then a video is added",
        "steps": [("upload", "image"), ("add", "watermark", {}), ("upload", "video")],
    },
    {
        "id": "INV-03", "valid": False, "offending": ["upgrade_ai"], "preview_on": "video",
        "title": "Compatible and AI tools mixed, then a video is added",
        "steps": [("upload", "image"), BRIGHT, ("add", "upgrade_ai", {}), ("upload", "video")],
    },
    {
        "id": "INV-04", "valid": False, "offending": ["text_ai"], "preview_on": "video",
        "title": "Empty project with an AI tool, then only a video is added",
        "steps": [("add", "text_ai", {}), ("upload", "video")],
    },
    {
        "id": "INV-05", "valid": False, "offending": ["cut_ai"], "preview_on": "image",
        "title": "Mixed project: the user looks for an AI tool to use on the image",
        "ui_only": True,  # the tool is not offered; the check is whether the editor explains why
        "steps": [("upload", "image"), ("upload", "video")],
    },
    {
        "id": "INV-06", "valid": False, "offending": ["trim"], "preview_on": "image",
        "title": "Trim on the video, then the video is deleted (only video effects remain)",
        "steps": [("upload", "image"), ("upload", "video"), TRIM_OK, ("delete_media", "video")],
    },
    {
        "id": "INV-07", "valid": False, "offending": ["subtitles"], "preview_on": "image",
        "title": "Subtitles, then the video is deleted",
        "steps": [("upload", "image"), ("upload", "video"), ("add", "subtitles", {}), ("delete_media", "video")],
    },
    {
        "id": "INV-08", "valid": False, "offending": ["extract_frames"], "preview_on": "image",
        "title": "Frame extraction, then the video is deleted",
        "steps": [("upload", "image"), ("upload", "video"), FRAMES, ("delete_media", "video")],
    },
    {
        "id": "INV-09", "valid": False, "offending": ["extract_frames"], "preview_on": "video",
        "title": "An effect is moved after frame extraction",
        "steps": [("upload", "video"), BRIGHT, FRAMES, ("reorder", ["extract_frames", "brightness"])],
    },
    {
        "id": "INV-10", "valid": False, "offending": ["trim"], "preview_on": "video",
        "title": "Trim end beyond the video duration",
        "steps": [("upload", "video"), ("add", "trim", {"start": 1, "end": 8, "imgId": "$video"})],
        "ui_trim": (1, 8),  # in the editor this is typed into the trim form
    },
    # ---- valid ---------------------------------------------------------
    {"id": "VAL-01", "valid": True, "execute": True, "results": 1, "preview_on": "image",
     "title": "Image: brightness", "steps": [("upload", "image"), BRIGHT]},
    {"id": "VAL-02", "valid": True, "execute": True, "results": 1, "preview_on": "image",
     "title": "Image: brightness and border", "steps": [("upload", "image"), BRIGHT, BORDER]},
    {"id": "VAL-03", "valid": True, "execute": True, "results": 1, "preview_on": "video",
     "title": "Video: brightness and trim", "steps": [("upload", "video"), BRIGHT, TRIM_OK]},
    {"id": "VAL-04", "valid": True, "execute": True, "results": 1, "preview_on": "video",
     "title": "Video: contrast and speed", "steps": [("upload", "video"), CONTRAST, SPEED]},
    {"id": "VAL-05", "valid": True, "execute": True, "results": 3, "preview_on": "video",
     "title": "Video: brightness and frame extraction", "steps": [("upload", "video"), BRIGHT, FRAMES]},
    {"id": "VAL-06", "valid": True, "execute": True, "results": 2, "preview_on": "video",
     "title": "Mixed: brightness and trim (the image skips trim)",
     "steps": [("upload", "image"), ("upload", "video"), BRIGHT, TRIM_OK]},
    {"id": "VAL-07", "valid": True, "execute": True, "results": 4, "preview_on": "video",
     "title": "Mixed: border and frame extraction (the image skips extraction)",
     "steps": [("upload", "image"), ("upload", "video"), BORDER, FRAMES]},
    {"id": "VAL-08", "valid": True, "execute": False, "preview_on": "image",
     "title": "Image: AI background removal (accepted, not executed: AI services not started)",
     "steps": [("upload", "image"), ("add", "bg_remove_ai", {})]},
    {"id": "VAL-09", "valid": True, "execute": True, "results": 2, "preview_on": "image",
     "title": "Image: brightness, then a video is added (compatible pipeline)",
     "steps": [("upload", "image"), BRIGHT, ("upload", "video")]},
    {"id": "VAL-10", "valid": True, "execute": True, "results": 2, "preview_on": "video",
     "title": "Correction of INV-01: the AI tool is removed and brightness added",
     "steps": [("upload", "image"), ("add", "bg_remove_ai", {}), ("upload", "video"),
               ("delete_tool", "bg_remove_ai"), BRIGHT]},
    {"id": "VAL-11", "valid": True, "execute": True, "results": 1, "preview_on": "image",
     "title": "Correction of INV-06: trim is removed and brightness added",
     "steps": [("upload", "image"), ("upload", "video"), TRIM_OK, ("delete_media", "video"),
               ("delete_tool", "trim"), BRIGHT]},
]

# Words that make a message specific to a tool (procedure name or UI label)
TOOL_NAMES = {
    "bg_remove_ai": ["bg_remove_ai", "background removal"],
    "watermark": ["watermark"],
    "upgrade_ai": ["upgrade_ai", "ai upgrade"],
    "text_ai": ["text_ai", "text detection"],
    "cut_ai": ["cut_ai", "ai crop", "ai tools", "ferramentas de ia"],
    "trim": ["trim", "corte"],
    "subtitles": ["subtitles", "legendas"],
    "extract_frames": ["extract_frames", "frame extraction", "extract frames", "extração"],
}

# Words that tell the user what to do (English and Portuguese). "exceed" counts
# because such a message states the limit to respect (e.g. the video duration).
FIX_WORDS = ["remove", "delete", "move", "replace", "must", "add a video", "upload a video",
             "exceed", "set ", "choose", "open ", "select a",
             "remov", "mov", "substitu", "adicion", "tem de", "deve", "exced", "defin", "escolh"]

# Scenarios checked in the editor perform their last step there, as a user
# would: INV-09 drags the extractor up the applied tools list and INV-10 types
# the times into the trim form. The other scenarios are set up through the API
# and the editor is opened on the resulting state.
UI_ACTIONS = {"INV-09": "reorder", "INV-10": "trim"}
