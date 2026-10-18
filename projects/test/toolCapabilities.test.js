const test = require("node:test");
const assert = require("node:assert");

const { pipelineAccepts, checkExclusiveTools } = require("../utils/toolCapabilities");

const brightness = { procedure: "brightness" };
const textAi = { procedure: "text_ai" };
const frames = { procedure: "extract_frames" };

test("TST-FRAME-07: tools de imagem aceitam imagens e ignoram vídeos", () => {
  assert.strictEqual(pipelineAccepts([brightness, textAi], "image"), true);
  assert.strictEqual(pipelineAccepts([brightness, textAi], "video"), false);
});

test("TST-FRAME-08: extract_frames só aceita vídeos (FRAME-050, FRAME-052)", () => {
  assert.strictEqual(pipelineAccepts([frames], "video"), true);
  assert.strictEqual(pipelineAccepts([frames], "image"), false);
});

test("TST-FRAME-09: pipeline vazia ou com tool desconhecida não aceita nada", () => {
  assert.strictEqual(pipelineAccepts([], "image"), false);
  assert.strictEqual(pipelineAccepts([{ procedure: "nope" }], "image"), false);
});

test("TST-FRAME-10: extract_frames não se combina com outras tools (FRAME-051)", () => {
  assert.strictEqual(checkExclusiveTools(["extract_frames"]), null);
  assert.strictEqual(checkExclusiveTools(["brightness", "contrast"]), null);
  assert.notStrictEqual(checkExclusiveTools(["brightness", "extract_frames"]), null);
  assert.notStrictEqual(checkExclusiveTools(["extract_frames", "brightness"]), null);
});
