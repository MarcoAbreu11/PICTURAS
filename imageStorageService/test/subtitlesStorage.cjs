// Opt-in against a disposable storage service/S3 instance (never production).
const assert = require("node:assert/strict");
const { randomUUID } = require("node:crypto");
async function main() {
  const base = process.env.SUBTITLES_TEST_STORAGE || "http://127.0.0.1:11000";
  const project = randomUUID();
  const filename = `subtitles-${randomUUID()}.vtt`;
  const content = "WEBVTT\n\n00:00:00.000 --> 00:00:01.000\nOlá\n\n";
  async function upload() {
    const form = new FormData();
    form.append("file", new Blob([content], { type: "text/vtt" }), filename);
    const response = await fetch(`${base}/upload/e4-test/${project}/subtitles`, { method: "POST", body: form });
    assert.equal(response.status, 201, await response.clone().text());
    return (await response.json()).data.imageKey;
  }
  assert.equal(await upload(), await upload(), "Retry must overwrite the same physical key");
  const signed = await fetch(`${base}/image/internal/e4-test/${project}/subtitles/${filename}`);
  assert.equal(signed.status, 200);
  const { url } = await signed.json();
  const vtt = await fetch(url);
  assert.equal(vtt.status, 200);
  assert.equal(vtt.headers.get("content-type"), "text/vtt");
  assert.equal(await vtt.text(), content);
  const removed = await fetch(`${base}/delete/e4-test/${project}/subtitles/${filename}`, { method: "DELETE" });
  assert.equal(removed.status, 201);
  assert.equal((await fetch(url)).status, 404);
  console.log("PASS real S3 storage: deterministic VTT upload, UTF-8/text-vtt, retrieval, deletion.");
}
main().catch((error) => { console.error(error); process.exitCode = 1; });
