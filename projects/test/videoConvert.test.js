const test = require("node:test");
const assert = require("node:assert");
const fs = require("fs");
const os = require("os");
const path = require("path");

const {
  validateVideoConvertParams,
  validateResolutionForProfile,
  validateVideoForConversion,
  conversionTargets,
  convertedName,
} = require("../utils/videoConvert");
const { sweepTempFiles } = require("../utils/tempFiles");
const { checkExclusiveTools } = require("../utils/toolCapabilities");

const MB = 1024 * 1024;
const ok = { format: "mp4", resolution: 720, quality: "medium" };

test("TST-CONV-01: parâmetros válidos são aceites (CONV-005, 046)", () => {
  assert.strictEqual(validateVideoConvertParams(ok), null);
  assert.strictEqual(validateVideoConvertParams({ ...ok, format: "webm", resolution: "original" }), null);
  assert.strictEqual(validateVideoConvertParams({ ...ok, video_id: "abc", allow_larger: true }), null);
});

test("TST-CONV-02: formato, resolução ou qualidade inválidos são recusados", () => {
  assert.match(validateVideoConvertParams({ ...ok, format: "avi" }), /MP4 or WebM/);
  assert.notStrictEqual(validateVideoConvertParams({ ...ok, resolution: 2160 }), null);
  assert.notStrictEqual(validateVideoConvertParams({ ...ok, quality: "max" }), null);
  assert.notStrictEqual(validateVideoConvertParams({ ...ok, allow_larger: "yes" }), null);
  assert.notStrictEqual(validateVideoConvertParams({ ...ok, video_id: 42 }), null);
  assert.notStrictEqual(validateVideoConvertParams(undefined), null);
});

test("TST-CONV-03: registado limitado a 720p com sugestão de upgrade (CONV-014, 022)", () => {
  assert.match(validateResolutionForProfile({ ...ok, resolution: 1080 }, "free"), /Upgrade to Premium/);
  assert.strictEqual(validateResolutionForProfile({ ...ok, resolution: 720 }, "free"), null);
});

test("TST-CONV-04: premium até 1080p; anónimo excluído (CONV-035, 032)", () => {
  assert.strictEqual(validateResolutionForProfile({ ...ok, resolution: 1080 }, "premium"), null);
  assert.match(validateResolutionForProfile(ok, "anonymous"), /Sign in/);
});

test("TST-CONV-05: só MP4/MOV com H.264/AAC são aceites (CONV-015, 042)", () => {
  const base = { size_bytes: 10 * MB, duration: 30, video_codec: "h264", audio_codec: "aac" };
  assert.strictEqual(validateVideoForConversion({ ...base, og_uri: "./a/aula.mp4" }), null);
  assert.strictEqual(validateVideoForConversion({ ...base, og_uri: "./a/aula.mov" }), null);
  assert.match(validateVideoForConversion({ ...base, og_uri: "./a/aula.avi" }), /aula.avi/);
  assert.notStrictEqual(validateVideoForConversion({ ...base, og_uri: "./a/x.mp4", video_codec: "hevc" }), null);
  assert.notStrictEqual(validateVideoForConversion({ ...base, og_uri: "./a/x.mp4", audio_codec: "opus" }), null);
});

test("TST-CONV-06: limites de 500 MB e 10 min nas fronteiras (CONV-026, 037)", () => {
  const base = { og_uri: "./a/x.mp4", video_codec: "h264", audio_codec: "aac" };
  assert.strictEqual(validateVideoForConversion({ ...base, size_bytes: 500 * MB, duration: 600 }), null);
  assert.match(validateVideoForConversion({ ...base, size_bytes: 501 * MB, duration: 60 }), /500 MB/);
  assert.match(validateVideoForConversion({ ...base, size_bytes: MB, duration: 660 }), /10 minute/);
});

test("TST-CONV-07: só o vídeo escolhido é convertido (passo 2)", () => {
  const imgs = [
    { _id: "v1", media_type: "video" },
    { _id: "v2", media_type: "video" },
    { _id: "i1", media_type: "image" },
  ];
  assert.deepStrictEqual(conversionTargets(imgs, { video_id: "v2" }).map((v) => v._id), ["v2"]);
  assert.deepStrictEqual(conversionTargets(imgs, {}).map((v) => v._id), ["v1", "v2"]);
  assert.deepStrictEqual(conversionTargets(imgs, { video_id: "gone" }), []);
});

test("TST-CONV-08: novo ficheiro com nome único, o original não é substituído (CONV-036, RN1)", () => {
  const used = new Set(["aula.mov", "aula_converted.mp4"]);
  assert.strictEqual(convertedName("aula.mov", "webm", used), "aula_converted.webm");
  assert.strictEqual(convertedName("aula.mov", "mp4", used), "aula_converted_2.mp4");
});

test("TST-CONV-09: a conversão não se combina com outras tools (DQ-009)", () => {
  assert.notStrictEqual(checkExclusiveTools(["video_convert", "brightness"]), null);
  assert.strictEqual(checkExclusiveTools(["video_convert"]), null);
});

test("TST-CONV-10: temporários antigos saem, os de trabalhos ativos ficam (CONV-034)", async () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "conv-sweep-"));
  const dir = path.join(root, "u1", "projects", "p1", "src");
  const out = path.join(root, "u1", "projects", "p1", "out");
  fs.mkdirSync(dir, { recursive: true });
  fs.mkdirSync(out, { recursive: true });
  const old = Date.now() - 2 * 60 * 60 * 1000;
  for (const f of [path.join(dir, "velho.mp4"), path.join(dir, "ativo.mov"), path.join(out, "ativo__converted_ab12.mp4")]) {
    fs.writeFileSync(f, "x");
    fs.utimesSync(f, old / 1000, old / 1000);
  }
  fs.writeFileSync(path.join(dir, "recente.mp4"), "x");

  const removed = await sweepTempFiles(["./images/users/u1/projects/p1/src/ativo.mov"], { root });

  assert.strictEqual(removed, 1);
  assert.ok(!fs.existsSync(path.join(dir, "velho.mp4")));
  assert.ok(fs.existsSync(path.join(dir, "ativo.mov")));
  assert.ok(fs.existsSync(path.join(out, "ativo__converted_ab12.mp4")));
  assert.ok(fs.existsSync(path.join(dir, "recente.mp4")));
  fs.rmSync(root, { recursive: true, force: true });
});
