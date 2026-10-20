const { randomUUID } = require("crypto");
const path = require("path");
const fs = require("fs/promises");
const { subtitleStore } = require("../controllers/subtitles");

const messages = {
  2301: "Não foi possível gerar as legendas. Tente novamente",
  2302: "Escolha Original ou English",
  2303: "O vídeo não tem faixa de áudio",
  2304: "Não foi possível detetar fala para gerar legendas",
  2305: "Já existe uma geração de legendas em curso para este vídeo",
};
function error(code, status = 400) {
  return Object.assign(new Error(messages[code]), { code, status });
}
function validate(body) {
  if (!body || !["original", "en"].includes(body.language) ||
      Object.keys(body).some((key) => key !== "language")) throw error(2302);
}
function keys(doc) {
  return [...new Set([doc.original?.key, doc.en?.key, doc.job?.key, ...(doc.garbageKeys || [])].filter(Boolean))];
}

// Dependencies are explicit so tests exercise the real lifecycle with controlled
// storage/worker failures, without invoking an AI model.
function createSubtitleService({ Model, Project, storage, reserve, refund, publish, root, assertPublisher = () => {} }) {
  const store = subtitleStore(Model);
  const dispatches = new Map();
  const identity = (project, video) => ({
    user_id: project.user_id, project_id: project._id,
    video_id: video._id, sourceHash: video.og_sha256,
  });
  const directory = (id) => path.join(root, id);
  async function alive(doc) {
    return Project.exists({
      _id: doc.project_id, user_id: doc.user_id,
      imgs: { $elemMatch: { _id: doc.video_id, og_sha256: doc.sourceHash } },
    });
  }
  async function present(doc) {
    const result = {
      detectedLanguage: doc?.detectedLanguage, tracks: {},
      job: doc?.job?.id ? { id: doc.job.id, language: doc.job.language } : null,
      error: doc?.error?.code ? doc.error : null,
    };
    if (!doc || doc.deleted) return result;
    for (const language of ["original", "en"]) {
      if (doc[language]?.key) {
        result.tracks[language] = {
          ...doc[language],
          url: await storage.url(doc, doc[language].key),
        };
      }
    }
    return result;
  }
  async function cleanup(doc) {
    for (const key of keys(doc)) await storage.remove(doc, key);
    // Keep a tombstone while the worker can still publish a late result.
    if (!doc.job?.id) await Model.deleteOne({ _id: doc._id, deleted: true, "job.id": { $exists: false } });
  }
  async function remove(project, video) {
    const filter = { project_id: project, ...(video ? { video_id: video } : {}) };
    await Model.updateMany(filter, { $set: { deleted: true } });
    for (const doc of await Model.find(filter).lean()) {
      if (doc.job?.id && (doc.job.delivery === "preparing" || !doc.job.reserved)) await failed(doc, 2301, true);
      else await cleanup(doc);
    }
  }
  async function failed(doc, code, onlyPreparing = false) {
    // Return the pre-update job so deletion/reservation races refund its actual state.
    const claimed = await store.fail(doc.job.id, {
      code, message: messages[code] || messages[2301], jobId: doc.job.id, refundPending: true,
    }, doc.job.key, onlyPreparing);
    if (!claimed) return false;
    let refunded = false;
    try {
      if (claimed.job.reserved) {
        await refund(claimed.job.runner);
        refunded = true;
      }
    } finally {
      await Model.updateOne({ _id: claimed._id, "error.jobId": doc.job.id }, {
        $set: { "error.refunded": refunded, "error.refundPending": false },
      });
      await fs.rm(directory(doc.job.id), { recursive: true, force: true });
      await cleanupGarbage({ ...claimed, garbageKeys: [...new Set([...(claimed.garbageKeys || []), claimed.job.key])] });
      if (claimed.deleted) await cleanup({ ...claimed, job: undefined });
    }
    return true;
  }
  async function cleanupGarbage(doc) {
    for (const key of doc.garbageKeys || []) {
      await storage.remove(doc, key);
      await Model.updateOne({ _id: doc._id }, { $pull: { garbageKeys: key } });
    }
  }
  async function dispatch(doc) {
    // The HTTP request and periodic recovery must not prepare the same files together.
    const id = doc.job.id;
    if (dispatches.has(id)) return dispatches.get(id);
    const pending = dispatchOnce(doc).finally(() => dispatches.delete(id));
    dispatches.set(id, pending);
    return pending;
  }
  async function dispatchOnce(snapshot) {
    let doc = await store.byJob(snapshot.job.id);
    if (!doc) return;
    const dir = directory(doc.job.id);
    const input = path.join(dir, "source");
    if (doc.job.delivery === "preparing") {
      try {
        assertPublisher();
        await fs.mkdir(dir, { recursive: true });
        try { await fs.access(input); } catch {
          const project = await Project.findById(doc.project_id).lean();
          const video = project?.imgs.find((i) => String(i._id) === String(doc.video_id));
          if (!video || doc.deleted) throw error(2301, 404);
          await storage.download(doc, video.og_img_key, input);
        }
        if (!(await alive(doc))) throw error(2301, 404);
        // Persist uncertainty BEFORE sending. Deletion and terminal preparation
        // failure can only claim "preparing", so neither can release a sent job.
        const publishing = await Model.findOneAndUpdate(
          { "job.id": doc.job.id, "job.delivery": "preparing", "job.reserved": true, deleted: false },
          { $set: { "job.delivery": "publishing" } }, { new: true },
        ).lean();
        if (!publishing) throw error(2301, 404);
        doc = publishing;
      } catch (err) {
        let terminated = false;
        try { terminated = await failed(doc, 2301, true); } catch (cleanupError) {
          console.error("[subtitles preparation cleanup]", doc.job.id, cleanupError.message);
        }
        if (terminated || !(await store.byJob(doc.job.id))) {
          // A download already in flight when deletion won may have left bytes.
          try { await fs.rm(dir, { recursive: true, force: true }); } finally {
            throw Object.assign(error(2301, 503), { terminalPreparation: true });
          }
        }
        throw err; // A competing publisher may already own this job.
      }
    }
    await publish({
      messageId: doc.job.id, timestamp: new Date().toISOString(), procedure: "video_subtitles",
      parameters: {
        inputImageURI: input, outputImageURI: path.join(dir, "subtitles.vtt"),
        language: doc.job.language, detectedLanguage: doc.detectedLanguage,
        videoId: String(doc.video_id),
      },
    });
    await Model.updateOne({ "job.id": doc.job.id }, { $set: { "job.delivery": "delivered" } });
  }
  async function generate(project, video, runner, body) {
    validate(body);
    await Model.init(); // the unique video index must exist before first admission
    let doc = await store.ensure(identity(project, video));
    if (doc.deleted || doc.sourceHash !== video.og_sha256 || !(await alive(doc)))
      throw Object.assign(new Error("Vídeo indisponível"), { status: 404 });
    if (doc[body.language]?.key) return { status: 200, data: await present(doc) };
    const id = `subtitles-${randomUUID()}`;
    doc = await store.acquire(doc._id, body.language, {
      id, language: body.language, runner, startedAt: new Date(),
      reserved: false, delivery: "preparing", key: `${id}.vtt`,
    });
    if (!doc) {
      const fresh = await store.get(project._id, video._id);
      if (!fresh?.deleted && fresh?.[body.language]?.key)
        return { status: 200, data: await present(fresh) };
      throw error(2305, 409);
    }
    try {
      if (!(await alive(doc))) throw error(2301, 404);
      await reserve(runner);
      const reserved = await Model.updateOne({ "job.id": id }, { $set: { "job.reserved": true } });
      if (!reserved.matchedCount) {
        await refund(runner);
        throw error(2301, 503);
      }
      doc.job.reserved = true;
    } catch (err) {
      await failed(doc, 2301);
      throw err;
    }
    // A publish timeout is ambiguous; keep the same job/lock and retry it.
    // Never allow a new inference just because the HTTP connection failed.
    try { await dispatch(doc); } catch (err) {
      if (err.terminalPreparation) throw err;
      console.error("[subtitles dispatch]", err.message);
    }
    return { status: 202, data: await present(doc) };
  }
  async function finish(message) {
    const doc = await store.byJob(message.correlationId);
    if (!doc) {
      // Also covers a crash after commit but before local cleanup.
      if (/^subtitles-[0-9a-f-]{36}$/.test(message.correlationId || ""))
        await fs.rm(directory(message.correlationId), { recursive: true, force: true });
      return;
    }
    if (doc.deleted || !(await alive(doc))) {
      await remove(doc.project_id, doc.video_id);
      return failed({ ...doc, deleted: true }, 2301);
    }
    if (message.status === "error") {
      const code = [2301, 2302, 2303, 2304].includes(message.error?.code) ? message.error.code : 2301;
      return failed(doc, code);
    }
    const output = message.output;
    const metadata = output?.metadata;
    const expectedPath = path.join(directory(doc.job.id), "subtitles.vtt");
    if (message.status !== "success" || output?.type !== "text" ||
        output.imageURI !== expectedPath || metadata?.videoId !== String(doc.video_id) ||
        metadata?.requestedLanguage !== doc.job.language ||
        !/^[a-z]{2,3}$/.test(metadata?.detectedLanguage || "") ||
        (doc.detectedLanguage && metadata.detectedLanguage !== doc.detectedLanguage))
      return failed(doc, 2301);
    const data = await fs.readFile(expectedPath, "utf8");
    if (!data.startsWith("WEBVTT\n\n") || !/\d{2}:\d{2}:\d{2}\.\d{3} --> /.test(data))
      return failed(doc, 2301);
    // Deterministic key makes retries and concurrent deletion safe across S3/Mongo.
    // Storage errors are retried by the result consumer, with the lock still held.
    await storage.upload(doc, doc.job.key, data);
    if (!(await alive(doc))) await remove(doc.project_id, doc.video_id);
    const saved = await store.complete(
      doc.job.id, metadata.detectedLanguage, doc.job.language, doc.job.key,
    );
    if (!saved) {
      // Another result consumer may already have committed this same job.
      // Never delete its now-valid track when a duplicate reply loses the CAS.
      const fresh = await store.get(doc.project_id, doc.video_id);
      if (!fresh || fresh.deleted || !keys({ original: fresh.original, en: fresh.en }).includes(doc.job.key)) {
        await storage.remove(doc, doc.job.key);
        await failed({ ...doc, deleted: true }, 2301);
      }
    } else if (!(await alive(saved))) {
      await remove(saved.project_id, saved.video_id);
    }
    await fs.rm(directory(doc.job.id), { recursive: true, force: true });
  }
  async function recover() {
    for (const doc of await Model.find({}).lean()) {
      try {
        await cleanupGarbage(doc);
        if (doc.deleted || !(await alive(doc))) {
          await remove(doc.project_id, doc.video_id);
          // A possibly-sent job keeps its files and identity. Redelivering also
          // settles a crash between the publishing CAS and the actual send.
          if (doc.job?.reserved && doc.job.delivery !== "preparing") await dispatch(doc);
        } else if (doc.job?.id && !doc.job.reserved && Date.now() - new Date(doc.job.startedAt).getTime() > 60000) {
          // No message can be published before the reserved CAS. A crash during
          // quota reservation is recoverable without expiring a running worker.
          await failed(doc, 2301, doc.job.delivery === "preparing");
        } else if (doc.job?.id && doc.job.reserved) {
          await dispatch(doc); // identical ID; worker receipt avoids another inference
        }
      } catch (err) {
        console.error("[subtitles recovery job]", doc.job?.id || String(doc._id), err.message);
      }
    }
  }
  return { generate, finish, remove, recover, present, store };
}
module.exports = { createSubtitleService, validate, messages, keys };
