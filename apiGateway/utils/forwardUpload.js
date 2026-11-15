const axios = require("axios");

// Forwards a multipart upload to another service as a stream: the request
// body is piped through unchanged, so the gateway never holds the file in
// memory (it parsed it with multer.memoryStorage before).
//
// `send` is the axios function to call (injectable for tests). Returns the
// axios promise; aborts the upstream request if the client disconnects.
function forwardUpload(req, url, { headers = {}, httpsAgent, params, send = axios } = {}) {
  const controller = new AbortController();
  req.on("aborted", () => controller.abort());

  const forwarded = { ...headers, "Content-Type": req.headers["content-type"] };
  if (req.headers["content-length"]) forwarded["Content-Length"] = req.headers["content-length"];

  return send({
    method: "post",
    url,
    data: req,
    headers: forwarded,
    httpsAgent,
    params,
    signal: controller.signal,
    // Videos can be hundreds of MB. maxRedirects: 0 sends the body without the
    // redirect helper, which would otherwise keep a copy of all of it in memory.
    maxBodyLength: Infinity,
    maxContentLength: Infinity,
    maxRedirects: 0,
  });
}

module.exports = { forwardUpload };
