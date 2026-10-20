const fs = require("fs/promises");
const path = require("path");
const https = require("https");
const axios = require("axios");
const FormData = require("form-data");
const amqp = require("amqplib");
const Model = require("../models/subtitles");
const Project = require("../models/project");
const images = require("../utils/imageStorage");
const { createSubtitleService, messages } = require("./subtitles");
const { v4: uuidv4 } = require("uuid");
const { send_msg_client, send_msg_client_item_error } = require("../utils/project_msg");
const httpsAgent = new https.Agent({ rejectUnauthorized: false });
const users = "https://users:10001";
const requestQueue = "video_subtitles_queue";
const resultQueue = "video_subtitles_results_queue";
let channel;

const service = createSubtitleService({
  Model, Project, root: path.join(__dirname, "..", "images", "subtitles", "jobs"),
  reserve: async (runner) => {
    try { await axios.get(`${users}/${runner}/process/1`, { httpsAgent, timeout: 15000 }); } catch (err) {
      throw Object.assign(new Error(err.response?.data === "No more daily_operations available"
        ? "Limite diário de operações avançadas atingido" : "Não foi possível reservar a operação"),
      { status: err.response?.data === "No more daily_operations available" ? 429 : 503 });
    }
  },
  refund: (runner) => axios.post(`${users}/${runner}/process/refund/1`, {}, { httpsAgent, timeout: 15000 }),
  assertPublisher: () => {
    if (!channel) throw new Error("Subtitle queue unavailable before publication");
  },
  publish: async (message) => {
    if (!channel) throw new Error("Subtitle queue unavailable");
    await new Promise((resolve, reject) => channel.publish(
      "picturas", requestQueue, Buffer.from(JSON.stringify(message)),
      { persistent: true, contentType: "application/json" },
      (err) => err ? reject(err) : resolve(),
    ));
  },
  storage: {
    url: async (doc, key) => (await images.get_image_public_url(doc.user_id, doc.project_id, "subtitles", key)).data.url,
    remove: (doc, key) => images.delete_image(doc.user_id, doc.project_id, "subtitles", key),
    download: async (doc, key, dest) => {
      const response = await images.get_image_internal_url(doc.user_id, doc.project_id, "src", key);
      const bytes = await axios.get(response.data.url, { responseType: "arraybuffer" });
      await fs.writeFile(`${dest}.part`, bytes.data);
      await fs.rename(`${dest}.part`, dest);
    },
    upload: async (doc, key, data) => {
      const form = new FormData();
      form.append("file", Buffer.from(data, "utf8"), { filename: key, contentType: "text/vtt" });
      await images.post_image(doc.user_id, doc.project_id, "subtitles", form);
    },
  },
});

// UC-VID-001 na pipeline: avisa a página de quem carregou em Apply que este vídeo terminou
// (com a faixa guardada) ou falhou (com o motivo), como as outras ferramentas de vídeo.
async function notifyRunner(job) {
  const after = await service.store.get(job.project_id, job.video_id);
  const runner = job.job.runner;
  const ts = new Date().toISOString();
  if (after && !after.deleted && after[job.job.language]?.key && after.error?.jobId !== job.job.id) {
    send_msg_client(`update-client-process-${uuidv4()}`, ts, runner);
  } else {
    const code = after?.error?.jobId === job.job.id ? after.error.code : 2301;
    send_msg_client_item_error(`update-client-process-${uuidv4()}`, ts, runner,
      String(job.video_id), code, messages[code] || messages[2301]);
  }
}

// Dedicated E4 consumer: await persistence before ack. Existing tools are untouched.
async function start() {
  try {
    await Model.init();
    const connection = await amqp.connect({
      hostname: process.env.RABBITMQ_HOST, port: Number(process.env.RABBITMQ_PORT || 5672),
      username: process.env.RABBITMQ_USER, password: process.env.RABBITMQ_PASS,
    });
    connection.on("error", (err) => console.error("[subtitles broker]", err.message));
    connection.on("close", () => { channel = null; setTimeout(start, 5000).unref(); });
    channel = await connection.createConfirmChannel();
    const current = channel;
    await current.assertExchange("picturas", "direct", { durable: true });
    for (const queue of [requestQueue, resultQueue]) {
      await current.assertQueue(queue, { durable: true });
      await current.bindQueue(queue, "picturas", queue);
    }
    await current.prefetch(1);
    await current.consume(resultQueue, async (message) => {
      if (!message) return;
      try {
        const reply = JSON.parse(message.content.toString());
        const job = await service.store.byJob(reply.correlationId);
        await service.finish(reply);
        current.ack(message);
        if (job?.job) notifyRunner(job).catch((err) => console.error("[subtitles notify]", err.message));
      } catch (err) {
        console.error("[subtitles result]", err.message);
        setTimeout(() => {
          if (channel === current) current.nack(message, false, true);
        }, 5000).unref();
      }
    });
    await service.recover();
  } catch (err) {
    console.error("[subtitles start]", err.message);
    if (!channel) setTimeout(start, 5000).unref();
  }
}
let recovering = false;
function startRecovery() {
  start();
  setInterval(async () => {
    if (!channel || recovering) return;
    recovering = true;
    try { await service.recover(); } catch (err) { console.error("[subtitles recovery]", err.message); }
    finally { recovering = false; }
  }, 60000).unref();
}
module.exports = { service, startRecovery, httpsAgent, users };
