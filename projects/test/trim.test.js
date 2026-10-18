const test = require("node:test");
const assert = require("node:assert");

const { validateTrimParams, checkTrimForVideos } = require("../utils/trim");
const { pipelineAccepts, checkExclusiveTools } = require("../utils/toolCapabilities");

test("TST-TRIM-01: intervalo válido é aceite (TRIM-003)", () => {
  assert.strictEqual(validateTrimParams({ start: 10, end: 40 }), null);
  assert.strictEqual(validateTrimParams({ start: 0, end: 1 }), null);
});

test("TST-TRIM-02: início maior ou igual ao fim é recusado (TRIM-014)", () => {
  assert.match(validateTrimParams({ start: 40, end: 10 }), /before the end/);
  assert.match(validateTrimParams({ start: 10, end: 10 }), /before the end/);
});

test("TST-TRIM-03: excerto com menos de 1 s é recusado (TRIM-034)", () => {
  assert.match(validateTrimParams({ start: 10, end: 10.5 }), /at least 1 s/);
});

test("TST-TRIM-04: parâmetros em falta ou inválidos são recusados", () => {
  assert.notStrictEqual(validateTrimParams(undefined), null);
  assert.notStrictEqual(validateTrimParams({ start: -1, end: 5 }), null);
  assert.notStrictEqual(validateTrimParams({ start: 0 }), null);
});

test("TST-TRIM-05: fim além da duração indica os vídeos afetados (TRIM-015)", () => {
  const msg = checkTrimForVideos({ start: 0, end: 30 }, [
    { name: "curto.mp4", duration: 10 },
    { name: "longo.mp4", duration: 60 },
  ]);
  assert.match(msg, /curto\.mp4/);
  assert.doesNotMatch(msg, /longo\.mp4/);
  assert.strictEqual(checkTrimForVideos({ start: 0, end: 10 }, [{ name: "a.mp4", duration: 10 }]), null);
});

test("TST-TRIM-06: trim só aceita vídeos e não se combina com outras tools (TRIM-045, TRIM-046)", () => {
  assert.strictEqual(pipelineAccepts([{ procedure: "trim" }], "video"), true);
  assert.strictEqual(pipelineAccepts([{ procedure: "trim" }], "image"), false);
  assert.notStrictEqual(checkExclusiveTools(["trim", "brightness"]), null);
  assert.notStrictEqual(checkExclusiveTools(["trim", "extract_frames"]), null);
  assert.strictEqual(checkExclusiveTools(["trim"]), null);
});
