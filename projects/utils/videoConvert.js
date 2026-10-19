const FORMATS = ["mp4", "webm"];
const RESOLUTIONS = ["original", 1080, 720, 480, 360];
const QUALITIES = ["high", "medium", "low"];
const path = require("path");

function validateVideoConvertParams(params) {
  if (!params || typeof params !== "object") return "Missing conversion parameters";
  if (!FORMATS.includes(params.format)) return "Output format must be MP4 or WebM";
  if (!RESOLUTIONS.includes(params.resolution)) return "Unsupported output resolution";
  if (!QUALITIES.includes(params.quality)) return "Unsupported output quality";
  if (params.allow_larger !== undefined && typeof params.allow_larger !== "boolean")
    return "The size confirmation must be a boolean";
  if (params.video_id !== undefined && (typeof params.video_id !== "string" || params.video_id === ""))
    return "The video to convert must be identified by its id";
  return null;
}

function validateResolutionForProfile(params, userType) {
  if (userType === "free" && params.resolution !== "original" && Number(params.resolution) > 720)
    return "Free accounts can export up to 720p. Upgrade to Premium for 1080p.";
  if (userType === "anonymous") return "Sign in to convert or compress videos.";
  return null;
}

function isSupportedSource(video) {
  const ext = path.extname(video.name || "").toLowerCase();
  return [".mp4", ".mov"].includes(ext) &&
    (video.video_codec == null ? video.size_bytes == null : video.video_codec === "h264") &&
    (video.audio_codec == null ? video.size_bytes == null : video.audio_codec === "aac");
}

function validateVideoForConversion(video) {
  const name = path.basename(video.og_uri || video.name || "");
  if (!isSupportedSource({
    name,
    size_bytes: video.size_bytes,
    video_codec: video.video_codec,
    audio_codec: video.audio_codec,
  })) return `${name} must be an MP4 or MOV video with H.264 video and AAC audio`;
  if (Number(video.size_bytes) > 500 * 1024 * 1024) return `${name} exceeds the 500 MB conversion limit`;
  if (Number(video.duration) > 600) return `${name} exceeds the 10 minute conversion limit`;
  return null;
}

// Vídeo(s) a converter: o escolhido em video_id ou, sem escolha, todos os vídeos do projeto
function conversionTargets(imgs, params) {
  const videos = (imgs || []).filter((i) => (i.media_type ?? "image") === "video");
  if (!params?.video_id) return videos;
  return videos.filter((v) => String(v._id) === String(params.video_id));
}

// Nome do vídeo convertido na biblioteca, único no projeto: aula.mov -> aula_converted.mp4
function convertedName(sourceName, format, usedNames) {
  const stem = path.basename(sourceName, path.extname(sourceName));
  let name = `${stem}_converted.${format}`;
  for (let i = 2; usedNames.has(name); i++) name = `${stem}_converted_${i}.${format}`;
  return name;
}

module.exports = {
  FORMATS,
  RESOLUTIONS,
  QUALITIES,
  validateVideoConvertParams,
  validateResolutionForProfile,
  isSupportedSource,
  validateVideoForConversion,
  conversionTargets,
  convertedName,
};
