const { Transform } = require("stream");
const uploadImage = require("./uploadImage");

// Multer storage engine that sends each uploaded file straight to S3 while it
// is being received, instead of keeping the whole file in memory first
// (multer.memoryStorage). The upload result is exposed as `req.file.result`.
function s3StreamStorage(upload = uploadImage) {
  return {
    _handleFile(req, file, cb) {
      const { userId, projectId, stage } = req.params;
      let size = 0;
      // count bytes without switching the source to flowing mode, so no data
      // is lost before the S3 client starts reading
      const counted = new Transform({
        transform(chunk, _enc, done) {
          size += chunk.length;
          done(null, chunk);
        },
      });
      file.stream.on("error", (error) => counted.destroy(error));
      file.stream.pipe(counted);

      upload(userId, projectId, { stream: counted, mimetype: file.mimetype }, stage)
        .then((result) => cb(null, { size, result }))
        .catch((error) => {
          // drain the rest of the request so the client still gets the reply
          file.stream.unpipe(counted);
          file.stream.resume();
          cb(error);
        });
    },
    _removeFile(req, file, cb) {
      // An aborted multipart upload is cleaned up by the S3 SDK itself.
      cb(null);
    },
  };
}

module.exports = s3StreamStorage;
