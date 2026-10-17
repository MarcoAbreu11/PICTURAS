const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFile } = require("child_process");
const { v4: uuidv4 } = require("uuid");

const IMAGE_EXT = [".png", ".jpg", ".jpeg"];
const VIDEO_EXT = [".mp4", ".webm", ".mov"];

// "image" | "video" | null, pela extensão do nome do ficheiro
function mediaTypeOf(filename) {
  const ext = path.extname(filename || "").toLowerCase();
  if (IMAGE_EXT.includes(ext)) return "image";
  if (VIDEO_EXT.includes(ext)) return "video";
  return null;
}

// Lê duração e resolução com ffprobe (o buffer é escrito para um ficheiro temporário)
async function probeVideo(buffer, filename = "video") {
  const tmp = path.join(os.tmpdir(), `${uuidv4()}${path.extname(filename)}`);
  await fs.promises.writeFile(tmp, buffer);

  try {
    const stdout = await new Promise((resolve, reject) => {
      execFile(
        "ffprobe",
        [
          "-v", "error",
          "-select_streams", "v:0",
          "-show_entries", "format=duration:stream=width,height",
          "-of", "json",
          tmp,
        ],
        (err, out) => (err ? reject(err) : resolve(out))
      );
    });

    const info = JSON.parse(stdout);
    const stream = info.streams?.[0];
    if (!stream) throw new Error("No video stream found");

    return {
      duration: Number(info.format?.duration) || 0,
      width: stream.width ?? null,
      height: stream.height ?? null,
    };
  } finally {
    fs.promises.unlink(tmp).catch(() => {});
  }
}

const VIDEO_LIMITS = {
  anonymous: { maxBytes: 20 * 1024 * 1024, maxSeconds: 15 },
  free: { maxBytes: 100 * 1024 * 1024, maxSeconds: 60 },
  premium: { maxBytes: 500 * 1024 * 1024, maxSeconds: 600 },
};

// null se estiver dentro dos limites do perfil, senão o motivo
function checkVideoLimits(userType, sizeBytes, durationSec) {
  const limits = VIDEO_LIMITS[userType] ?? VIDEO_LIMITS.anonymous;

  if (sizeBytes > limits.maxBytes)
    return `Video exceeds the ${Math.round(limits.maxBytes / 1024 / 1024)} MB limit for ${userType} users`;

  if (durationSec > limits.maxSeconds)
    return `Video exceeds the ${limits.maxSeconds} s limit for ${userType} users`;

  return null;
}

module.exports = { mediaTypeOf, probeVideo, VIDEO_LIMITS, checkVideoLimits };
