import { ExtractFramesToolParams } from "./tool-types";

// Espelho de projects/utils/frames.js (o backend valida sempre)
export const MAX_FRAMES_PER_VIDEO = 100;

export const DEFAULT_FRAME_PARAMS: ExtractFramesToolParams = {
  mode: "interval",
  interval: 5,
  instant: 0,
  format: "png",
};

// Nº de imagens que a extração gera num vídeo com esta duração (s)
export function frameCount(params: ExtractFramesToolParams, duration: number) {
  if (params.mode === "single") return params.instant < duration ? 1 : 0;
  if (!(params.interval > 0)) return 0;
  return Math.ceil(duration / params.interval);
}
