// Regras da tool extract_frames (UC-VID-003). O worker (Tools/extract_frames)
// calcula os instantes com o mesmo algoritmo.

const MAX_FRAMES_PER_VIDEO = 100;
const FORMATS = ["png", "jpeg"];
const MODES = ["interval", "single"];

// null se os parâmetros forem válidos, senão o motivo
function validateFrameParams(params) {
  if (!params || typeof params !== "object") return "Missing frame extraction parameters";
  if (!MODES.includes(params.mode)) return "Mode must be 'interval' or 'single'";
  if (params.format !== undefined && !FORMATS.includes(params.format))
    return "Format must be 'png' or 'jpeg'";

  if (params.mode === "interval") {
    const n = Number(params.interval);
    if (!Number.isFinite(n) || n <= 0) return "Interval must be a positive number of seconds";
  } else {
    const t = Number(params.instant);
    if (!Number.isFinite(t) || t < 0) return "Instant must be zero or a positive number of seconds";
  }
  return null;
}

// Instantes (s) a extrair: 0, N, 2N, ... < duração; ou [instant]
function frameTimestamps(params, duration) {
  if (params.mode === "single") return [Number(params.instant)];

  const n = Number(params.interval);
  const count = Math.ceil(duration / n);
  const out = [];
  for (let i = 0; i < count; i++) out.push(Math.round(i * n * 1000) / 1000);
  return out;
}

function frameCount(params, duration) {
  return frameTimestamps(params, duration).length;
}

// Valida a extração contra os vídeos do projeto; null se ok, senão o motivo
function checkFramesForVideos(params, videos) {
  const tooShort = [];
  const tooMany = [];

  for (const v of videos) {
    if (!Number.isFinite(v.duration)) continue; // vídeos antigos sem duração: o worker valida
    if (params.mode === "single" && Number(params.instant) >= v.duration)
      tooShort.push(`${v.name} (${Math.floor(v.duration)} s)`);
    if (params.mode === "interval" && frameCount(params, v.duration) > MAX_FRAMES_PER_VIDEO)
      tooMany.push(v.name);
  }

  if (tooShort.length > 0)
    return `The chosen instant is beyond the end of: ${tooShort.join(", ")}`;
  if (tooMany.length > 0)
    return `The interval generates more than ${MAX_FRAMES_PER_VIDEO} images per video in: ${tooMany.join(", ")}`;
  return null;
}

module.exports = {
  MAX_FRAMES_PER_VIDEO,
  validateFrameParams,
  frameTimestamps,
  frameCount,
  checkFramesForVideos,
};
