// Streaming upload handling for project media.
// The uploaded file is written to a temporary file while its SHA-256 is
// computed in the same pass, so the orchestrator never holds the whole file
// in memory (it used multer.memoryStorage before).
const crypto = require("crypto");
const fs = require("fs");
const os = require("os");
const path = require("path");
const multer = require("multer");
const { v4: uuidv4 } = require("uuid");

const UPLOAD_TMP_DIR = process.env.UPLOAD_TMP_DIR || os.tmpdir();

// Extra bytes allowed on top of the file itself for the multipart envelope
// (boundaries, part headers) when checking Content-Length.
const MULTIPART_OVERHEAD_BYTES = 1024 * 1024;

// Multer storage engine: file -> temporary file + SHA-256, one pass.
function hashingDiskStorage(dir = UPLOAD_TMP_DIR) {
  return {
    _handleFile(req, file, cb) {
      const filePath = path.join(dir, `upload-${uuidv4()}${path.extname(file.originalname || "")}`);
      const hash = crypto.createHash("sha256");
      const out = fs.createWriteStream(filePath);
      let size = 0;
      let done = false;

      // A client that disconnects mid-upload never ends file.stream, so
      // neither multer nor cleanupOnClose (req.file is still unset) would
      // remove the partial file: watch the request itself.
      const onRequestClose = () => {
        if (req.complete) return;
        const err = new Error("Upload aborted by the client");
        err.code = "UPLOAD_ABORTED";
        fail(err);
      };
      req.on("close", onRequestClose);

      const fail = (err) => {
        if (done) return;
        done = true;
        req.removeListener("close", onRequestClose);
        file.stream.unpipe(out);
        file.stream.resume();
        out.destroy();
        fs.rm(filePath, { force: true }, () => cb(err));
      };

      file.stream.on("data", (chunk) => {
        size += chunk.length;
        hash.update(chunk);
      });
      file.stream.on("error", fail);
      // multer stops reading at the size limit; drop the partial file
      file.stream.on("limit", () => fail(new Error("File too large")));
      out.on("error", fail);
      out.on("finish", () => {
        if (done) return;
        done = true;
        req.removeListener("close", onRequestClose);
        cb(null, { path: filePath, size, sha256: hash.digest("hex") });
      });
      file.stream.pipe(out);
    },
    _removeFile(req, file, cb) {
      // a file stopped by the size limit has already been removed by fail()
      if (!file.path) return cb(null);
      fs.rm(file.path, { force: true }, cb);
    },
  };
}

// Removes the temporary file once the response is done (success, error or
// client disconnect), so failed uploads leave nothing behind.
function cleanupOnClose(req, res) {
  res.on("close", () => {
    if (req.file && req.file.path) fs.rm(req.file.path, { force: true }, () => {});
  });
}

// Message for a file over the size limit. `bytes` may be unknown (null) when
// the client sent no Content-Length.
function sizeLimitMessage(bytes, limitMB) {
  if (bytes == null) return `The video exceeds your profile limit of ${limitMB} MB`;
  return `The video is ${(bytes / 1048576).toFixed(1)} MB and your profile limit is ${limitMB} MB`;
}

// Middleware factory that receives one file field into a temporary file.
// `getLimitBytes(req)` returns the maximum file size in bytes, or null for no
// limit. Requests whose Content-Length is already above the limit are
// rejected before any of the body is read.
function receiveUpload(field, { getLimitBytes = () => null, dir } = {}) {
  const storage = hashingDiskStorage(dir);
  return (req, res, next) => {
    const limitBytes = getLimitBytes(req);
    const limitMB = limitBytes != null ? Math.round(limitBytes / 1048576) : null;

    const declared = Number(req.headers["content-length"]);
    if (limitBytes != null && Number.isFinite(declared) && declared > limitBytes + MULTIPART_OVERHEAD_BYTES) {
      // the multipart envelope is a few hundred bytes, so this is the file size
      return res.status(400).jsonp(sizeLimitMessage(declared, limitMB));
    }

    cleanupOnClose(req, res);
    const limits = limitBytes != null ? { fileSize: limitBytes } : undefined;
    multer({ storage, limits }).single(field)(req, res, (err) => {
      if (err && err.code === "LIMIT_FILE_SIZE") {
        return res.status(400).jsonp(sizeLimitMessage(null, limitMB));
      }
      // the client is gone and the partial file was removed: nothing to answer
      if (err && err.code === "UPLOAD_ABORTED") return;
      next(err);
    });
  };
}

module.exports = {
  hashingDiskStorage,
  receiveUpload,
  sizeLimitMessage,
  MULTIPART_OVERHEAD_BYTES,
};
