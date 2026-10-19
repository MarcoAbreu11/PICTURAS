const test = require("node:test");
const assert = require("node:assert");

const { validateBlurParams, DEFAULT_BLUR_PARAMS } = require("../utils/blurFaces");
const { pipelineAccepts, checkExclusiveTools } = require("../utils/toolCapabilities");

const blur = { procedure: "blur_faces" };

test("TST-BLUR-U1: opções por omissão e válidas são aceites (BLUR-002, BLUR-009)", () => {
  assert.strictEqual(validateBlurParams(DEFAULT_BLUR_PARAMS), null);
  assert.strictEqual(validateBlurParams({}), null);
  assert.strictEqual(validateBlurParams({ mode: "pixelate", strength: 10, padding: 0 }), null);
});

test("TST-BLUR-U2: opções fora dos valores permitidos são recusadas (BLUR-050)", () => {
  assert.notStrictEqual(validateBlurParams(null), null);
  assert.notStrictEqual(validateBlurParams({ mode: "emoji" }), null);
  assert.notStrictEqual(validateBlurParams({ strength: 0 }), null);
  assert.notStrictEqual(validateBlurParams({ strength: 11 }), null);
  assert.notStrictEqual(validateBlurParams({ strength: "forte" }), null);
  assert.notStrictEqual(validateBlurParams({ padding: 101 }), null);
});

test("TST-BLUR-U3: blur_faces só aceita vídeos (BLUR-045, BLUR-047)", () => {
  assert.strictEqual(pipelineAccepts([blur], "video"), true);
  assert.strictEqual(pipelineAccepts([blur], "image"), false);
});

test("TST-BLUR-U4: blur_faces não se combina com outras tools (BLUR-046)", () => {
  assert.strictEqual(checkExclusiveTools(["blur_faces"]), null);
  assert.notStrictEqual(checkExclusiveTools(["blur_faces", "trim"]), null);
  assert.notStrictEqual(checkExclusiveTools(["brightness", "blur_faces"]), null);
});
