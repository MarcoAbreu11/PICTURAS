import { BlurFacesToolParams } from "./tool-types";

// Espelho de projects/utils/blurFaces.js (o backend valida sempre)
export const MIN_STRENGTH = 1;
export const MAX_STRENGTH = 10;
export const MIN_PADDING = 0;
export const MAX_PADDING = 100;

export const DEFAULT_BLUR_PARAMS: BlurFacesToolParams = {
  mode: "blur",
  strength: 5,
  padding: 20,
};

// null se as opções forem válidas, senão o motivo (BLUR-050)
export function blurParamsError(p: BlurFacesToolParams): string | null {
  if (p.mode !== "blur" && p.mode !== "pixelate") return "Choose blur or pixelate";
  if (!(p.strength >= MIN_STRENGTH && p.strength <= MAX_STRENGTH))
    return `The intensity must be between ${MIN_STRENGTH} and ${MAX_STRENGTH}`;
  if (!(p.padding >= MIN_PADDING && p.padding <= MAX_PADDING))
    return `The margin must be between ${MIN_PADDING} and ${MAX_PADDING} %`;
  return null;
}
