// Que tipo de media cada tool aceita. As tools de vídeo entram aqui.
const CAPABILITIES = {
  border: ["image"],
  brightness: ["image"],
  contrast: ["image"],
  cut: ["image"],
  scale: ["image"],
  saturation: ["image"],
  binarization: ["image"],
  rotate: ["image"],
  resize: ["image"],
  watermark: ["image"],
  cut_ai: ["image"],
  upgrade_ai: ["image"],
  bg_remove_ai: ["image"],
  text_ai: ["image"],
  obj_ai: ["image"],
  people_ai: ["image"],
  expand_ai: ["image"],
  extract_frames: ["video"],
  trim: ["video"],
  video_convert: ["video"],
};

// Tools que, no MVP, não podem ser combinadas com outras na mesma pipeline
// (a pipeline é linear e estas geram vários resultados por item)
const EXCLUSIVE_TOOLS = ["extract_frames", "trim", "video_convert"];

function toolAccepts(procedure, mediaType) {
  return (CAPABILITIES[procedure] || []).includes(mediaType);
}

// true se TODAS as tools aceitam mediaType (procedure desconhecida → false)
function pipelineAccepts(tools, mediaType) {
  if (!Array.isArray(tools) || tools.length === 0) return false;
  return tools.every((t) => toolAccepts(t.procedure, mediaType));
}

// null se a pipeline resultante for válida, senão o motivo
function checkExclusiveTools(procedures) {
  const exclusive = procedures.filter((p) => EXCLUSIVE_TOOLS.includes(p));
  if (exclusive.length > 0 && procedures.length > 1)
    return "Video tools cannot be combined with other tools. Remove the other tools first.";
  return null;
}

module.exports = {
  CAPABILITIES,
  EXCLUSIVE_TOOLS,
  toolAccepts,
  pipelineAccepts,
  checkExclusiveTools,
};
