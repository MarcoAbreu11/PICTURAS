const router = require("express").Router();
const axios = require("axios");
const jwt = require("jsonwebtoken");
const mongoose = require("mongoose");
const Project = require("../models/project");
const { service, httpsAgent, users } = require("../services/subtitleRuntime");
const { validate } = require("../services/subtitles");

async function authorize(req, res, next) {
  try {
    const token = req.headers.authorization?.split(" ")[1];
    const caller = token && jwt.decode(token)?.id;
    if (!caller || !mongoose.isObjectIdOrHexString(caller))
      return res.status(401).json({ message: "Sessão inválida" });
    // users validates the signature and expiry; never trust X-Caller-Id.
    const validated = await axios.get(`${users}/validate/${caller}`, {
      httpsAgent, headers: { Authorization: `Bearer ${token}` },
    });
    if (!["free", "premium"].includes(validated.data.user.type))
      return res.status(403).json({ message: "Inicie sessão com uma conta registada para usar legendas" });
    if (![req.params.user, req.params.project, req.params.img].every(mongoose.isObjectIdOrHexString))
      return res.status(404).json({ message: "Vídeo indisponível" });
    const project = await Project.findOne({ _id: req.params.project, user_id: req.params.user }).lean();
    if (!project) return res.status(404).json({ message: "Projeto indisponível" });
    const owner = String(project.user_id) === caller;
    const share = project.sharedLinks.find((link) => link.id === req.query.share && !link.revoked);
    if (!owner && (!share || (req.method === "POST" && share.permission !== "edit")))
      return res.status(403).json({ message: "Sem permissão para aceder às legendas deste vídeo" });
    const video = project.imgs.find((item) => String(item._id) === req.params.img);
    if (!video || video.media_type !== "video")
      return res.status(404).json({ message: "Vídeo indisponível" });
    if (video.converted_from && !owner)
      return res.status(403).json({ message: "Vídeo disponível apenas para o proprietário" });
    req.subtitleContext = { caller, project, video };
    next();
  } catch (err) {
    res.status(err.response?.status === 401 ? 401 : 503)
      .json({ message: "Não foi possível validar o acesso às legendas" });
  }
}
router.get("/:user/:project/img/:img/subtitles", authorize, async (req, res) => {
  try {
    const doc = await service.store.get(req.params.project, req.params.img);
    res.set("Cache-Control", "no-store");
    res.json(await service.present(doc));
  } catch (err) { res.status(503).json({ message: "Não foi possível carregar as legendas" }); }
});
router.post("/:user/:project/img/:img/subtitles", authorize, async (req, res) => {
  try {
    validate(req.body);
    const { project, video, caller } = req.subtitleContext;
    const result = await service.generate(project, video, caller, req.body);
    res.status(result.status).json(result.data);
  } catch (err) {
    res.status(err.status || 503).json({ code: err.code, message: err.message });
  }
});
module.exports = router;
