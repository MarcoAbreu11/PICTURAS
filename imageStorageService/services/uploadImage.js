const s3 = require("./s3Client");
const createBucket = require("./createBucket");
const { v4: uuidv4 } = require("uuid");
const path = require("path");

async function uploadImage(userId, projectId, file, stage) {
  const bucketName = `user-${userId}`;
  await createBucket(bucketName);

  // Extensão do nome original: o mimetype dá extensões erradas (ex.: video/quicktime -> .quicktime)
  const ext =
    path.extname(file.originalname || "").slice(1).toLowerCase() ||
    file.mimetype.split("/")[1];
  const imageKey = `${projectId}/${stage}/${uuidv4()}.${ext}`;
  const params = {
    Bucket: bucketName,
    Key: imageKey,
    Body: file.buffer,
    ContentType: file.mimetype,
  };

  try {
    const data = await s3.upload(params).promise();
    return { imageKey, location: data.Location };
  } catch (error) {
    console.error("Erro ao enviar imagem:", error.message);
    throw error;
  }
}

module.exports = uploadImage;
