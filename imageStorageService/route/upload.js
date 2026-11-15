const express = require("express");
const multer = require("multer");
const s3StreamStorage = require("../services/s3StreamStorage");
const allowedStages = require("../utils/stages");

const router = express.Router();
// The file is streamed to S3 as it arrives (no full copy in memory).
const upload = multer({ storage: s3StreamStorage() });

router.post(
  "/:userId/:projectId/:stage",
  (req, res, next) => {
    // validate the stage before receiving the file, so nothing is stored
    if (!allowedStages.includes(req.params.stage)) {
      req.resume();
      return res.status(400).json({
        error: "O estágio deve ser src, preview, preview_cache ou out.",
      });
    }
    next();
  },
  (req, res) => {
    upload.single("file")(req, res, (error) => {
      if (error) {
        return res.status(500).json({ error: error.message });
      }
      if (!req.file) {
        return res.status(500).json({ error: "No file found" });
      }
      res
        .status(201)
        .json({ message: "Imagem enviada com sucesso!", data: req.file.result });
    });
  },
);

module.exports = router;
