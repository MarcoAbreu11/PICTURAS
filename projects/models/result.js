const mongoose = require("mongoose");

const resultSchema = new mongoose.Schema({
  type: { type: String, required: true },
  file_name: { type: String, required: true },
  img_key: { type: String, required: true },
  img_id: { type: mongoose.Schema.Types.ObjectId, required: true },
  project_id: { type: mongoose.Schema.Types.ObjectId, required: true },
  user_id: { type: mongoose.Schema.Types.ObjectId, required: true },
  token: { type: Number, default: 0, index: true },
  // extract_frames: instante (s) do frame no vídeo de origem
  frame_time: { type: Number, required: false },
});

module.exports = mongoose.model("result", resultSchema);
