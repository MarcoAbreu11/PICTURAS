const s3 = require("./s3Client");
const { BUCKET, objectKey, ensureBucket } = require("./storage");
const { v4: uuidv4 } = require("uuid");

// Multipart upload settings: S3 receives the file in parts of PART_SIZE and at
// most QUEUE_SIZE parts are held in memory at once, so the memory needed for
// one upload is bounded (about PART_SIZE * QUEUE_SIZE) whatever the file size.
const PART_SIZE = 5 * 1024 * 1024; // the S3 minimum part size
const QUEUE_SIZE = 2;

// Uploads one file to the shared bucket. `file.stream` (a readable stream) is
// preferred; `file.buffer` is still accepted for in-memory callers.
async function uploadImage(userId, projectId, file, stage, client = s3) {
  await ensureBucket();

  // imageKey is what callers store and send back (<projectId>/<stage>/<file>);
  // the user prefix is added only for the object's key in the shared bucket.
  const fileName = `${uuidv4()}.${file.mimetype.split("/")[1]}`;
  const imageKey = `${projectId}/${stage}/${fileName}`;
  const params = {
    Bucket: BUCKET,
    Key: objectKey(userId, projectId, stage, fileName),
    Body: file.stream || file.buffer,
    ContentType: file.mimetype,
  };

  try {
    const data = await client
      .upload(params, { partSize: PART_SIZE, queueSize: QUEUE_SIZE })
      .promise();
    return { imageKey, location: data.Location };
  } catch (error) {
    console.error("Erro ao enviar imagem:", error.message);
    throw error;
  }
}

module.exports = uploadImage;
module.exports.PART_SIZE = PART_SIZE;
module.exports.QUEUE_SIZE = QUEUE_SIZE;
