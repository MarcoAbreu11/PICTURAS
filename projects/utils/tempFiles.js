// Ficheiros temporários das tools de vídeo (cópias locais das fontes, saídas por enviar e
// cópias usadas nas estimativas de tamanho da conversão).
// REQ-VID-CONV-034: saem até 1 h depois do fim do trabalho, com sucesso, falha ou cancelamento.
const fs = require("fs");
const path = require("path");

const IMAGES_ROOT = path.join(__dirname, "..", "images", "users");
const VIDEO_EXT = [".mp4", ".mov", ".webm"];
const MAX_AGE_MS = 50 * 60 * 1000;   // mais antigos que isto e sem trabalho ativo: apagar
const SWEEP_EVERY_MS = 10 * 60 * 1000; // 50 min + 10 min entre varrimentos = ≤ 1 h

// uri relativo à raiz do serviço ("./images/users/...")
function removeLocalFile(uri) {
  if (!uri) return;
  fs.promises.unlink(path.join(__dirname, "..", uri)).catch(() => {});
}

// Ficheiros de vídeo (e cópias a meio, .part) nas pastas src/out/estimate de cada projeto
async function listVideoTempFiles(root = IMAGES_ROOT) {
  const files = [];
  const read = (dir) => fs.promises.readdir(dir, { withFileTypes: true }).catch(() => []);
  for (const user of await read(root)) {
    if (!user.isDirectory()) continue;
    const projectsDir = path.join(root, user.name, "projects");
    for (const project of await read(projectsDir)) {
      if (!project.isDirectory()) continue;
      for (const stage of ["src", "out", "estimate"]) {
        const dir = path.join(projectsDir, project.name, stage);
        for (const entry of await read(dir)) {
          const ext = path.extname(entry.name).toLowerCase();
          if (entry.isFile() && (VIDEO_EXT.includes(ext) || ext === ".part"))
            files.push(path.join(dir, entry.name));
        }
      }
    }
  }
  return files;
}

// Apaga os temporários antigos que nenhum trabalho em curso referencia.
// activeUris: og_img_uri/new_img_uri dos processes ainda ativos.
async function sweepTempFiles(activeUris, { root = IMAGES_ROOT, now = Date.now(), maxAgeMs = MAX_AGE_MS } = {}) {
  const active = new Set(
    activeUris.filter(Boolean).map((u) => path.basename(u))
  );
  let removed = 0;
  for (const file of await listVideoTempFiles(root)) {
    // a saída do FFmpeg tem um sufixo próprio; a referência ativa é pelo nome da fonte
    const name = path.basename(file);
    const stem = name.split("__converted_")[0];
    if (active.has(name) || [...active].some((a) => path.basename(a, path.extname(a)) === stem)) continue;
    try {
      const stat = await fs.promises.stat(file);
      if (now - stat.mtimeMs < maxAgeMs) continue;
      await fs.promises.unlink(file);
      removed++;
    } catch (_) {}
  }
  return removed;
}

function startTempSweeper(getActiveUris) {
  const run = async () => {
    try {
      const removed = await sweepTempFiles(await getActiveUris());
      if (removed) console.log(`[TEMP-SWEEP] removed=${removed}`);
    } catch (err) {
      console.error("[TEMP-SWEEP] error:", err.message);
    }
  };
  const timer = setInterval(run, SWEEP_EVERY_MS);
  timer.unref();
  run();
  return timer;
}

module.exports = { removeLocalFile, listVideoTempFiles, sweepTempFiles, startTempSweeper, MAX_AGE_MS };
