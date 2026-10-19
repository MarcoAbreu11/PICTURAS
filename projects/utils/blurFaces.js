// Regras da tool blur_faces (UC-VID-004). O worker (Tools/blur_faces) valida o mesmo.

const MODES = ["blur", "pixelate"];
const MIN_STRENGTH = 1;
const MAX_STRENGTH = 10;
const MIN_PADDING = 0;
const MAX_PADDING = 100;
const DEFAULT_BLUR_PARAMS = { mode: "blur", strength: 5, padding: 20 };

// null se as opções forem válidas, senão o motivo
function validateBlurParams(params) {
  if (!params || typeof params !== "object") return "Missing face blurring parameters";

  const p = { ...DEFAULT_BLUR_PARAMS, ...params };
  if (!MODES.includes(p.mode)) return "The anonymization type must be 'blur' or 'pixelate'";

  const strength = Number(p.strength);
  if (!Number.isFinite(strength) || strength < MIN_STRENGTH || strength > MAX_STRENGTH)
    return `The intensity must be between ${MIN_STRENGTH} and ${MAX_STRENGTH}`;

  const padding = Number(p.padding);
  if (!Number.isFinite(padding) || padding < MIN_PADDING || padding > MAX_PADDING)
    return `The margin must be between ${MIN_PADDING} and ${MAX_PADDING} %`;

  return null;
}

module.exports = {
  MODES,
  MIN_STRENGTH,
  MAX_STRENGTH,
  MIN_PADDING,
  MAX_PADDING,
  DEFAULT_BLUR_PARAMS,
  validateBlurParams,
};
