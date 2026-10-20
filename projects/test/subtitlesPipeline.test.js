const test = require("node:test");
const assert = require("node:assert");

const { SUBTITLES_TOOL, validateSubtitleToolParams } = require("../utils/subtitlesTool");
const { pipelineAccepts, checkExclusiveTools } = require("../utils/toolCapabilities");

const subtitles = { procedure: SUBTITLES_TOOL };

test("TST-SUB-P1: a ferramenta de legendas aceita só { language: original | en }", () => {
  assert.strictEqual(validateSubtitleToolParams({ language: "original" }), null);
  assert.strictEqual(validateSubtitleToolParams({ language: "en" }), null);
  assert.notStrictEqual(validateSubtitleToolParams({ language: "pt" }), null);
  assert.notStrictEqual(validateSubtitleToolParams({}), null);
  assert.notStrictEqual(validateSubtitleToolParams({ language: "en", mode: "burn" }), null);
  assert.notStrictEqual(validateSubtitleToolParams(null), null);
});

test("TST-SUB-P2: as legendas só se aplicam a vídeos", () => {
  assert.strictEqual(pipelineAccepts([subtitles], "video"), true);
  assert.strictEqual(pipelineAccepts([subtitles], "image"), false);
});

test("TST-SUB-P3: as legendas não se combinam com outras ferramentas", () => {
  assert.strictEqual(checkExclusiveTools([SUBTITLES_TOOL]), null);
  assert.notStrictEqual(checkExclusiveTools([SUBTITLES_TOOL, "trim"]), null);
  assert.notStrictEqual(checkExclusiveTools(["brightness", SUBTITLES_TOOL]), null);
});
