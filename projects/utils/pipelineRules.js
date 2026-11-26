// Pipeline compatibility rules: which media each tool works on, and the issues
// of a project's pipeline for the media it holds. This is the single source of
// these rules: the orchestrator uses it when a tool is added, edited or
// reordered and before a preview or a run, and the editor shows its output
// (`pipelineIssues` and `unavailableTools` in the project response) instead of
// repeating the rules in the frontend.
const {
  VIDEO_TOOLS,
  VIDEO_ONLY_TOOLS,
  PER_VIDEO_TOOLS,
  isVideoMedia,
  validateFrameExtraction,
} = require("./video");

// Names shown in the editor toolbar, so messages use the words the user sees
const TOOL_LABELS = {
  brightness: "Brightness",
  contrast: "Contrast",
  saturation: "Saturation",
  binarization: "Black & White",
  rotate: "Rotate",
  cut: "Crop",
  resize: "Resize",
  border: "Create Border",
  trim: "Trim",
  speed: "Speed",
  subtitles: "Automatic subtitles",
  extract_frames: "Extract frames",
  watermark: "Watermark",
  bg_remove_ai: "AI Background Removal",
  cut_ai: "AI Crop",
  obj_ai: "AI Object Detection",
  people_ai: "AI People Detection",
  text_ai: "AI Text Detection",
  expand_ai: "AI Expand",
  upgrade_ai: "AI Upgrade",
};

const MIN_SPEED = 0.25;
const MAX_SPEED = 5;
// Same tolerance as the trim form in the editor
const DURATION_TOLERANCE_S = 0.05;

const label = (procedure) => TOOL_LABELS[procedure] || procedure;
const isImageOnly = (procedure) => !VIDEO_TOOLS.includes(procedure);
const isVideoOnly = (procedure) => VIDEO_ONLY_TOOLS.includes(procedure);
const ordered = (tools) => [...(tools || [])].sort((a, b) => (a.position ?? 0) - (b.position ?? 0));
const fmt = (n) => Number(n.toFixed(2)).toString();

function issue(tool, code, severity, message, fix) {
  return {
    toolId: tool && tool._id ? String(tool._id) : null,
    procedure: tool ? tool.procedure : null,
    label: tool ? label(tool.procedure) : null,
    code,
    severity, // "error" blocks preview and processing; "warning" does not
    message,
    fix,
  };
}

// Trim times and speed factor, checked against the targeted video
function paramIssues(project, tool) {
  const p = tool.params || {};
  const L = label(tool.procedure);
  if (tool.procedure === "trim") {
    const start = Number(p.start);
    const end = Number(p.end);
    if (!Number.isFinite(start) || !Number.isFinite(end)) {
      return [issue(tool, "trim_times", "error", `${L} needs a start and an end time in seconds.`,
        `Open ${L} and set both times.`)];
    }
    if (start < 0 || end <= start) {
      return [issue(tool, "trim_times", "error", `${L} must end after it starts (start ${fmt(start)} s, end ${fmt(end)} s).`,
        `Open ${L} and set the end after the start.`)];
    }
    const video = (project.imgs || []).find((img) => String(img._id) === String(p.imgId));
    const duration = video && video.video && Number(video.video.duration);
    if (Number.isFinite(duration) && duration > 0 && end > duration + DURATION_TOLERANCE_S) {
      return [issue(tool, "trim_times", "error",
        `${L} ends at ${fmt(end)} s, but the video lasts ${fmt(duration)} s.`,
        `Open ${L} and set an end time up to ${fmt(duration)} s.`)];
    }
  }
  if (tool.procedure === "speed") {
    const f = Number(p.factor);
    if (!Number.isFinite(f) || f < MIN_SPEED || f > MAX_SPEED) {
      return [issue(tool, "speed_factor", "error", `${L} must be between ${MIN_SPEED}x and ${MAX_SPEED}x (got ${p.factor}x).`,
        `Open ${L} and choose a factor in that range.`)];
    }
  }
  return [];
}

// Issues of one tool against the media of the project. `onlyVideoEffects`
// tells whether the whole pipeline consists of video-only tools.
function toolIssues(project, tool, { onlyVideoEffects = true } = {}) {
  const hasVideos = (project.imgs || []).some(isVideoMedia);
  const L = label(tool.procedure);

  if (hasVideos && isImageOnly(tool.procedure)) {
    return [issue(tool, "image_only_tool", "error",
      `${L} only works on images, and this project has videos.`,
      `Remove ${L} from the pipeline, or keep the videos in a separate project.`)];
  }
  if (!hasVideos && isVideoOnly(tool.procedure)) {
    // Images skip video-only tools: harmless next to image effects, but a
    // pipeline made only of them has nothing to apply.
    return onlyVideoEffects
      ? [issue(tool, "video_only_tool", "error",
        `${L} only applies to videos, and this project has none, so the pipeline has nothing to apply to the images.`,
        `Remove ${L} and add an image effect, or add a video to the project.`)]
      : [issue(tool, "video_only_tool", "warning",
        `${L} only applies to videos, and this project has none, so it has no effect.`,
        `Remove ${L} from the pipeline.`)];
  }
  if (hasVideos && PER_VIDEO_TOOLS.includes(tool.procedure)) {
    const target = tool.params && tool.params.imgId;
    if (target && !(project.imgs || []).some((img) => String(img._id) === String(target) && isVideoMedia(img))) {
      return [issue(tool, "missing_video", "warning",
        `${L} belongs to a video that is no longer in the project, so it has no effect.`,
        `Remove ${L} from the pipeline.`)];
    }
  }
  return paramIssues(project, tool);
}

function frameExtractionFix(message) {
  const L = label("extract_frames");
  if (/last tool/.test(message)) return `Move ${L} to the end of the pipeline.`;
  if (/Only one/.test(message)) return `Remove the extra ${L} tool.`;
  return `Open ${L} and correct its settings.`;
}

// Order and settings of frame extraction (see validateFrameExtraction)
function frameExtractionIssue(tools) {
  const list = ordered(tools);
  const frameError = validateFrameExtraction(list);
  if (!frameError) return null;
  const extractor = list.find((t) => t.procedure === "extract_frames");
  // validateFrameExtraction answers without a final period
  return issue(extractor, "frame_extraction", "error", `${frameError}.`, frameExtractionFix(frameError));
}

// Every issue of the project's pipeline, in pipeline order
function pipelineIssues(project) {
  const tools = ordered(project.tools);
  const onlyVideoEffects = tools.length > 0 && tools.every((t) => isVideoOnly(t.procedure));
  const issues = tools.flatMap((tool) => toolIssues(project, tool, { onlyVideoEffects }));
  const frame = frameExtractionIssue(tools);
  if (frame) issues.push(frame);
  return issues;
}

// First issue that prevents a preview or a run, if any
function blockingIssue(issues) {
  return issues.find((i) => i.severity === "error") || null;
}

// Issue that prevents previewing one media item, if any. A video preview runs
// the whole pipeline, so every error counts. An image preview only runs the
// image effects: issues about the videos (image-only tools in a project with
// videos, trim and speed settings) do not stop it, as in the base version.
// Only an invalid frame extraction and a pipeline with nothing to apply to the
// images do.
const IMAGE_PREVIEW_BLOCKERS = ["frame_extraction", "video_only_tool"];

function previewBlockingIssue(issues, previewIsVideo) {
  if (previewIsVideo) return blockingIssue(issues);
  return blockingIssue(issues.filter((i) => IMAGE_PREVIEW_BLOCKERS.includes(i.code)));
}

// Text for an error reply: what is wrong and what to do
function describeIssue(i) {
  return `${i.message} ${i.fix}`;
}

// Errors a single tool would bring into the project if it were added or saved
// as given. Only the tool itself is judged, so existing issues never block a
// correction (removing or editing another tool).
function toolErrors(project, tool) {
  return toolIssues(project, tool).filter((i) => i.severity === "error");
}

// Tools the editor does not offer for this project, and why
function unavailableTools(project) {
  const hasVideos = (project.imgs || []).some(isVideoMedia);
  return Object.keys(TOOL_LABELS)
    .filter((p) => (hasVideos ? isImageOnly(p) : isVideoOnly(p)))
    .map((p) => ({
      procedure: p,
      label: label(p),
      reason: hasVideos
        ? "These tools work on images only, and this project has videos."
        : "These tools only apply to videos, and this project has none.",
      fix: hasVideos
        ? "To use them on the images, remove the videos or keep them in a separate project."
        : "Add a video to use them.",
    }));
}

module.exports = {
  TOOL_LABELS,
  pipelineIssues,
  frameExtractionIssue,
  blockingIssue,
  previewBlockingIssue,
  describeIssue,
  toolErrors,
  unavailableTools,
};
