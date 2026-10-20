const mongoose = require("mongoose");

// Independent of project run tokens and whole-project updates.
const track = new mongoose.Schema({
  key: { type: String, required: true },
  language: { type: String, required: true },
}, { _id: false });
const schema = new mongoose.Schema({
  user_id: { type: mongoose.Schema.Types.ObjectId, required: true },
  project_id: { type: mongoose.Schema.Types.ObjectId, required: true },
  video_id: { type: mongoose.Schema.Types.ObjectId, required: true },
  sourceHash: { type: String, required: true },
  detectedLanguage: String,
  original: track,
  en: track,
  garbageKeys: { type: [String], default: [] },
  job: {
    id: String,
    language: String,
    runner: String,
    startedAt: Date,
    reserved: Boolean,
    // Missing on legacy jobs: conservatively treat those as possibly published.
    delivery: { type: String, enum: ["preparing", "publishing", "delivered"] },
    key: String,
  },
  error: { code: Number, message: String, jobId: String, refundPending: Boolean, refunded: Boolean },
  deleted: { type: Boolean, default: false },
}, { timestamps: true });
schema.index({ project_id: 1, video_id: 1 }, { unique: true });
schema.index({ "job.id": 1 }, { sparse: true });

module.exports = mongoose.model("subtitles", schema);
