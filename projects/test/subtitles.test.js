const { test, before, after } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("fs/promises");
const os = require("os");
const path = require("path");
const { randomUUID } = require("crypto");
const { validate, keys, createSubtitleService } = require("../services/subtitles");

test("E4 accepts only the requested Original/English option", () => {
  validate({ language: "original" });
  validate({ language: "en" });
  for (const value of [{}, { language: "pt" }, { language: "en", mode: "burn" },
    { language: "original", format: "srt" }, { language: "en", previewSeconds: 3 }]) {
    assert.throws(() => validate(value), { code: 2302 });
  }
});
test("English aliases are deleted as one physical object", () => {
  assert.deepEqual(keys({ original: { key: "one" }, en: { key: "one" } }), ["one"]);
});

// Uses a real MongoDB server, in a fresh test-only database. No app data is read.
test("UC-VID-001 persistent lifecycle", { skip: !process.env.SUBTITLES_TEST_MONGO }, async (t) => {
  const mongoose = require("mongoose");
  const Model = require("../models/subtitles");
  const Project = require("../models/project");
  await mongoose.connect(process.env.SUBTITLES_TEST_MONGO, { dbName: `subtitles_test_${randomUUID().replaceAll("-", "")}` });
  await Model.init();
  t.after(async () => { await mongoose.connection.dropDatabase(); await mongoose.disconnect(); });
  async function fixture() {
    const root = await fs.mkdtemp(path.join(os.tmpdir(), "subtitles-test-"));
    t.after(() => fs.rm(root, { recursive: true, force: true }));
    const project = await Project.create({ name: "E4", user_id: new mongoose.Types.ObjectId(),
      imgs: [{ media_type: "video", og_uri: "source.mp4", new_uri: "out.mp4",
        og_img_key: "source.mp4", og_sha256: "source-hash" }] });
    const video = project.imgs[0];
    const objects = new Map();
    const calls = { ai: [], reserve: 0, refund: 0, deleted: [] };
    let uploadHook;
    const dependencies = {
      Model, Project, root,
      reserve: async () => { calls.reserve++; },
      refund: async () => { calls.refund++; },
      publish: async (msg) => { calls.ai.push(msg); },
      storage: {
        download: async (_doc, _key, dest) => fs.writeFile(dest, "original bytes"),
        url: async (_doc, key) => `https://storage/${key}`,
        upload: async (_doc, key, data) => { objects.set(key, data); if (uploadHook) await uploadHook(); },
        remove: async (_doc, key) => { calls.deleted.push(key); objects.delete(key); },
      },
    };
    let service = createSubtitleService(dependencies);
    async function generate(language) { return service.generate(project, video, String(project.user_id), { language }); }
    async function result(detected = "pt", failure) {
      const msg = calls.ai.at(-1);
      if (failure) return service.finish({ correlationId: msg.messageId, status: "error", error: { code: failure } });
      await fs.writeFile(msg.parameters.outputImageURI, "WEBVTT\n\n00:00:00.000 --> 00:00:01.000\nOlá\n\n");
      return service.finish({
        correlationId: msg.messageId, status: "success",
        output: { type: "text", imageURI: msg.parameters.outputImageURI, metadata: {
          videoId: String(video._id), requestedLanguage: msg.parameters.language, detectedLanguage: detected,
        } },
      });
    }
    return { project, video, calls, objects, generate, result,
      service: () => service,
      reopen: () => { service = createSubtitleService(dependencies); },
      onUpload: (fn) => { uploadHook = fn; },
    };
  }

  for (const first of ["original", "en"]) {
    await t.test(`${first} first: persist, reopen, reuse, then generate only other option`, async () => {
      const f = await fixture();
      const second = first === "en" ? "original" : "en";
      assert.equal((await f.generate(first)).status, 202);
      await f.result();
      f.reopen();
      const reused = await f.generate(first);
      assert.equal(reused.status, 200);
      assert.equal(reused.data.detectedLanguage, "pt");
      assert.equal(reused.data.tracks[second], undefined);
      assert.equal(f.calls.ai.length, 1);
      assert.equal((await f.generate(second)).status, 202);
      // An existing track stays usable while the other option is processing.
      assert.equal((await f.generate(first)).status, 200);
      assert.equal(f.calls.ai.at(-1).parameters.detectedLanguage, "pt");
      await f.result();
      assert.equal(f.objects.size, 2);
      assert.equal(f.calls.reserve, 2);
    });
    await t.test(`English source, ${first} first: one job and one object`, async () => {
      const f = await fixture();
      await f.generate(first); await f.result("en");
      f.reopen();
      const state = (await f.generate(first === "en" ? "original" : "en")).data;
      assert.equal(state.tracks.en.key, state.tracks.original.key);
      assert.equal(f.objects.size, 1);
      assert.equal(f.calls.ai.length, 1);
      assert.equal(f.calls.reserve, 1);
      await Project.updateOne({ _id: f.project._id }, { $pull: { imgs: { _id: f.video._id } } });
      await f.service().remove(f.project._id, f.video._id);
      assert.equal(f.objects.size, 0);
      assert.equal(f.calls.deleted.length, 1);
      assert.equal(await f.service().store.get(f.project._id, f.video._id), null);
    });
  }
  await t.test("simultaneous sessions/opposite languages start exactly one job", async () => {
    const f = await fixture();
    const requests = await Promise.allSettled(Array.from({ length: 12 }, (_, i) => f.generate(i % 2 ? "original" : "en")));
    assert.equal(requests.filter((r) => r.status === "fulfilled").length, 1);
    for (const rejected of requests.filter((r) => r.status === "rejected"))
      assert.equal(rejected.reason.code, 2305);
    assert.equal(f.calls.ai.length, 1);
    assert.equal(f.calls.reserve, 1);
    await f.result();
  });
  for (const code of [2301, 2303, 2304]) {
    await t.test(`error ${code}: no track, refund once, allow retry`, async () => {
      const f = await fixture();
      await f.generate("original"); const job = f.calls.ai.at(-1).messageId;
      await f.result("pt", code);
      await f.service().finish({ correlationId: job, status: "error", error: { code } });
      const doc = await f.service().store.get(f.project._id, f.video._id);
      assert.equal(doc.detectedLanguage, undefined);
      assert.equal(doc.original, undefined);
      assert.equal(doc.job, undefined);
      assert.equal(doc.error.code, code);
      assert.equal(f.calls.refund, 1);
      assert.equal(f.objects.size, 0);
      assert.equal((await f.generate("original")).status, 202);
    });
  }
  await t.test("failure of second track preserves valid original", async () => {
    const f = await fixture();
    await f.generate("original"); await f.result();
    await f.generate("en"); await f.result("pt", 2301);
    assert.equal((await f.generate("original")).status, 200);
    assert.equal(f.objects.size, 1);
  });
  await t.test("delete while generating discards late output without resurrecting metadata", async () => {
    const f = await fixture();
    await f.generate("original");
    await Project.deleteOne({ _id: f.project._id });
    await f.service().remove(f.project._id);
    await f.result();
    assert.equal(f.objects.size, 0);
    assert.equal(await f.service().store.get(f.project._id, f.video._id), null);
  });
  await t.test("delete racing with S3 upload leaves no orphan", async () => {
    const f = await fixture();
    await f.generate("original");
    f.onUpload(async () => {
      await Project.deleteOne({ _id: f.project._id });
      await f.service().remove(f.project._id);
    });
    await f.result();
    assert.equal(f.objects.size, 0);
    assert.equal(await f.service().store.get(f.project._id, f.video._id), null);
  });
  await t.test("storage failure retains lock and retries the same physical key", async () => {
    const f = await fixture();
    await f.generate("original");
    f.onUpload(() => { throw new Error("storage unavailable"); });
    await assert.rejects(f.result(), /storage unavailable/);
    await assert.rejects(f.generate("en"), { code: 2305 });
    f.onUpload(null);
    await f.result();
    assert.equal(f.objects.size, 1);
    assert.equal(f.calls.ai.length, 1);
  });
  await t.test("duplicate success replies cannot delete the committed track", async () => {
    const f = await fixture();
    await f.generate("original");
    let uploads = 0, release;
    const barrier = new Promise((resolve) => { release = resolve; });
    f.onUpload(async () => {
      if (++uploads === 2) release();
      await barrier;
    });
    await Promise.all([f.result(), f.result()]);
    assert.equal(f.objects.size, 1);
    assert.equal((await f.generate("original")).status, 200);
    assert.equal(f.calls.refund, 0);
  });
});
