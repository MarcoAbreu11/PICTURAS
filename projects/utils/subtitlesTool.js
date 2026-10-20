// UC-VID-001 na pipeline: a ferramenta video_subtitles é guardada como as outras e só
// gera legendas quando o utilizador carrega em Apply. A geração em si continua a ser
// feita pelo serviço de legendas (services/subtitles.js), que reserva e devolve a quota.
const { validate } = require("../services/subtitles");

const SUBTITLES_TOOL = "video_subtitles";

// null se os parâmetros forem válidos ({ language: "original" | "en" }), senão o motivo
function validateSubtitleToolParams(params) {
  try {
    validate(params);
    return null;
  } catch (err) {
    return err.message;
  }
}

module.exports = { SUBTITLES_TOOL, validateSubtitleToolParams };
