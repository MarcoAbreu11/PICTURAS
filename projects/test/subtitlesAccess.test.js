const { test } = require("node:test");
const assert = require("node:assert/strict");

test("E4 routes enforce verified identity, registered profile and video permission", async (t) => {
  const express = require("express");
  const jwt = require("jsonwebtoken");
  const axios = require("axios");
  const Project = require("../models/project");
  const { service } = require("../services/subtitleRuntime");
  const presence = require("../utils/presence");
  const router = require("../routes/subtitles");
  const owner = "111111111111111111111111";
  const guest = "222222222222222222222222";
  const projectId = "333333333333333333333333";
  const videoId = "444444444444444444444444";
  let profile = "free", generated = 0, converted = false, admitted = true, stored = null;
  const admissions = [];
  t.mock.method(presence, "ensureEditorSlot", async (identity) => {
    admissions.push(identity);
    return { ok: admitted, active: 2, limit: 2 };
  });
  const project = () => ({
    _id: projectId, user_id: owner,
    imgs: [{ _id: videoId, media_type: "video", converted_from: converted ? "other" : undefined }],
    sharedLinks: [
      { id: "read", permission: "read" }, { id: "edit", permission: "edit" },
      { id: "revoked", permission: "edit", revoked: true },
    ],
  });
  t.mock.method(axios, "get", async (url, config) => {
    let payload;
    try { payload = jwt.verify(config.headers.Authorization.slice(7), "test-key"); }
    catch { throw { response: { status: 401 } }; }
    assert.ok(url.endsWith(`/validate/${payload.id}`));
    return { data: { user: { _id: payload.id, type: profile } } };
  });
  t.mock.method(Project, "findOne", () => ({ lean: async () => project() }));
  t.mock.method(service, "generate", async () => { generated++; return { status: 202, data: {} }; });
  t.mock.method(service.store, "get", async () => stored);
  const app = express();
  app.use(express.json(), router);
  const server = app.listen(0, "127.0.0.1");
  await new Promise((resolve) => server.once("listening", resolve));
  t.after(() => new Promise((resolve) => server.close(resolve)));
  const base = `http://127.0.0.1:${server.address().port}/${owner}/${projectId}/img/${videoId}/subtitles`;
  async function request({ user = owner, share, method = "POST", token } = {}) {
    return fetch(`${base}${share ? `?share=${share}` : ""}`, {
      method, headers: { "Content-Type": "application/json", "X-Caller-Id": owner,
        Authorization: `Bearer ${token || jwt.sign({ id: user }, "test-key", { expiresIn: 60 })}` },
      body: method === "POST" ? JSON.stringify({ language: "original" }) : undefined,
    });
  }
  assert.equal((await request()).status, 202);
  profile = "premium";
  assert.equal((await request()).status, 202);
  profile = "anonymous";
  assert.equal((await request()).status, 403);
  assert.equal((await request({ method: "GET" })).status, 403);
  profile = "free";
  assert.equal((await request({ user: guest })).status, 403);
  assert.equal((await request({ user: guest, share: "read" })).status, 403);
  assert.equal((await request({ user: guest, share: "read", method: "GET" })).status, 200);
  assert.equal((await request({ user: guest, share: "edit" })).status, 202);
  assert.deepEqual(admissions.at(-1), { ownerId: owner, projectId, callerId: guest });
  admitted = false;
  const denied = await request({ user: guest, share: "edit" });
  assert.equal(denied.status, 429);
  assert.equal((await denied.json()).limit, 2);
  assert.equal(generated, 3, "denied editor must not reach generation/quota reservation");
  const checks = admissions.length;
  assert.equal((await request({ user: guest, share: "read", method: "GET" })).status, 200);
  assert.equal(admissions.length, checks, "viewing tracks must not require an editor slot");
  stored = { original: { key: "existing.vtt" } };
  assert.equal((await request({ user: guest, share: "edit" })).status, 202);
  assert.equal(admissions.length, checks, "reusing an existing track must not require an editor slot");
  stored = null;
  admitted = true;
  assert.equal((await request({ user: guest, share: "revoked" })).status, 403);
  assert.equal((await request({ token: jwt.sign({ id: owner }, "wrong-key") })).status, 401);
  converted = true;
  assert.equal((await request({ user: guest, share: "edit" })).status, 403);
  assert.equal(generated, 4);
});
