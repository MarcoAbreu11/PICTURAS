const test = require("node:test");
const assert = require("node:assert");

const {
  MAX_FRAMES_PER_VIDEO,
  validateFrameParams,
  frameTimestamps,
  frameCount,
  checkFramesForVideos,
} = require("../utils/frames");

test("TST-FRAME-01: intervalo de 10 s num vídeo de 60 s gera 6 frames (FRAME-009)", () => {
  assert.deepStrictEqual(frameTimestamps({ mode: "interval", interval: 10 }, 60), [0, 10, 20, 30, 40, 50]);
});

test("TST-FRAME-02: frame único devolve só o instante (FRAME-003, FRAME-006)", () => {
  assert.deepStrictEqual(frameTimestamps({ mode: "single", instant: 12 }, 60), [12]);
});

test("TST-FRAME-03: limite de 100 imagens por vídeo (FRAME-014, FRAME-015)", () => {
  const ok = { mode: "interval", interval: 6 };
  const tooMany = { mode: "interval", interval: 5 };
  assert.strictEqual(frameCount(ok, 600), MAX_FRAMES_PER_VIDEO);
  assert.strictEqual(checkFramesForVideos(ok, [{ name: "a.mp4", duration: 600 }]), null);
  assert.match(checkFramesForVideos(tooMany, [{ name: "a.mp4", duration: 600 }]), /more than 100.*a\.mp4/);
});

test("TST-FRAME-04: instante depois do fim indica os vídeos afetados (FRAME-013)", () => {
  const msg = checkFramesForVideos({ mode: "single", instant: 30 }, [
    { name: "curto.mp4", duration: 10 },
    { name: "longo.mp4", duration: 60 },
  ]);
  assert.match(msg, /curto\.mp4/);
  assert.doesNotMatch(msg, /longo\.mp4/);
});

test("TST-FRAME-05: vídeos sem duração guardada não bloqueiam (o worker valida)", () => {
  assert.strictEqual(checkFramesForVideos({ mode: "single", instant: 30 }, [{ name: "antigo.mp4" }]), null);
});

test("TST-FRAME-06: validação dos parâmetros da tool (FRAME-002, FRAME-010)", () => {
  assert.strictEqual(validateFrameParams({ mode: "interval", interval: 2, format: "png" }), null);
  assert.strictEqual(validateFrameParams({ mode: "single", instant: 0, format: "jpeg" }), null);
  assert.notStrictEqual(validateFrameParams({ mode: "interval", interval: 0 }), null);
  assert.notStrictEqual(validateFrameParams({ mode: "single", instant: -1 }), null);
  assert.notStrictEqual(validateFrameParams({ mode: "interval", interval: 2, format: "gif" }), null);
  assert.notStrictEqual(validateFrameParams({ mode: "other" }), null);
  assert.notStrictEqual(validateFrameParams(undefined), null);
});
