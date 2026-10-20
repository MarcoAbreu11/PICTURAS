// Conditional updates are the per-video lock. No clock-based expiry: an old
// inference may still be running. RabbitMQ redelivers interrupted jobs.
function subtitleStore(Model) {
  return {
    async ensure(identity) {
      try {
        await Model.updateOne(
          { project_id: identity.project_id, video_id: identity.video_id },
          { $setOnInsert: identity }, { upsert: true },
        );
      } catch (error) {
        if (error.code !== 11000) throw error; // concurrent first request
      }
      return this.get(identity.project_id, identity.video_id);
    },
    get(project, video) {
      return Model.findOne({ project_id: project, video_id: video }).lean();
    },
    acquire(id, language, job) {
      return Model.findOneAndUpdate(
        { _id: id, deleted: false, "job.id": { $exists: false },
          [`${language}.key`]: { $exists: false } },
        { $set: { job }, $unset: { error: "" } }, { new: true },
      ).lean();
    },
    byJob(id) { return Model.findOne({ "job.id": id }).lean(); },
    async complete(id, detectedLanguage, language, key) {
      const value = { key, language: language === "en" ? "en" : detectedLanguage };
      const tracks = detectedLanguage === "en" ? { original: value, en: value } : { [language]: value };
      return Model.findOneAndUpdate(
        { "job.id": id, deleted: false },
        { $set: { detectedLanguage, ...tracks }, $unset: { job: "", error: "" } },
        { new: true },
      ).lean();
    },
    async fail(id, error, key) {
      return Model.findOneAndUpdate(
        { "job.id": id },
        { $set: { error }, $unset: { job: "" }, ...(key ? { $addToSet: { garbageKeys: key } } : {}) }, { new: true },
      ).lean();
    },
  };
}
module.exports = { subtitleStore };
