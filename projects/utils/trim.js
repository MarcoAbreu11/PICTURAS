// Regras da tool trim (UC-VID-002). O worker (Tools/trim) valida também a duração real.

const MIN_EXCERPT_SECONDS = 1;

// null se os parâmetros forem válidos, senão o motivo
function validateTrimParams(params) {
  if (!params || typeof params !== "object") return "Missing trim parameters";

  const start = Number(params.start);
  const end = Number(params.end);
  if (!Number.isFinite(start) || start < 0) return "The start must be zero or a positive number of seconds";
  if (!Number.isFinite(end)) return "The end must be a number of seconds";
  if (start >= end) return "The start must be before the end";
  if (end - start < MIN_EXCERPT_SECONDS)
    return `The excerpt must be at least ${MIN_EXCERPT_SECONDS} s long`;
  return null;
}

// O mesmo intervalo aplica-se a todos os vídeos; null se couber em todos, senão o motivo
function checkTrimForVideos(params, videos) {
  const tooShort = videos
    .filter((v) => Number.isFinite(v.duration) && Number(params.end) > v.duration)
    .map((v) => `${v.name} (${Math.floor(v.duration)} s)`);

  if (tooShort.length > 0)
    return `The end of the excerpt is beyond the end of: ${tooShort.join(", ")}`;
  return null;
}

module.exports = { MIN_EXCERPT_SECONDS, validateTrimParams, checkTrimForVideos };
