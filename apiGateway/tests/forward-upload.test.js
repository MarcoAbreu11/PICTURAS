const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('crypto');
const http = require('http');
const { Readable } = require('stream');
const express = require('express');
const jwt = require('jsonwebtoken');

process.env.JWT_SECRET_KEY = 'test-secret';
const auth = require('../auth/auth');
const { forwardUpload } = require('../utils/forwardUpload');

const MB = 1024 * 1024;

function* chunks(totalBytes, chunkBytes = MB) {
  let byte = 0;
  for (let sent = 0; sent < totalBytes; sent += chunkBytes) {
    yield Buffer.alloc(Math.min(chunkBytes, totalBytes - sent), byte++ % 251);
  }
}

function listen(app) {
  const server = app.listen(0);
  return new Promise((r) => server.once('listening', () => r(server)));
}

// Upstream stand-in for the projects service: hashes whatever it receives.
async function upstream() {
  const seen = { requests: 0 };
  const server = http.createServer((req, res) => {
    seen.requests++;
    seen.headers = req.headers;
    seen.url = req.url;
    const hash = crypto.createHash('sha256');
    let size = 0;
    req.on('data', (c) => { size += c.length; hash.update(c); });
    req.on('end', () => {
      seen.size = size;
      seen.sha256 = hash.digest('hex');
      res.writeHead(204, { 'X-Project-Version': '8' });
      res.end();
    });
  });
  await new Promise((r) => server.listen(0, r));
  return { server, seen, url: `http://127.0.0.1:${server.address().port}` };
}

async function gateway(upstreamUrl) {
  const app = express();
  app.use(express.json());
  app.post('/projects/:user/:project/video', auth.checkToken, (req, res) => {
    forwardUpload(req, `${upstreamUrl}/${req.params.user}/${req.params.project}/video`, {
      headers: { 'X-Caller-Id': req.authUserId, 'X-Project-Version': req.headers['x-project-version'] },
      params: { share: req.query.share },
    })
      .then((r) => res.set('X-Project-Version', r.headers['x-project-version']).sendStatus(204))
      .catch((e) => res.status(e.response?.status || 500).json(e.message));
  });
  return listen(app);
}

function send(port, { token, totalBytes, hash, query = '' }) {
  return new Promise((resolve, reject) => {
    const headers = {
      'Content-Type': 'multipart/form-data; boundary=x',
      'Content-Length': totalBytes,
      'X-Project-Version': '7',
    };
    if (token) headers.Authorization = `Bearer ${token}`;
    const req = http.request({ port, method: 'POST', path: `/projects/u1/p1/video${query}`, headers }, (res) => {
      res.resume();
      res.on('end', () => resolve({ status: res.statusCode, headers: res.headers }));
    });
    req.on('error', reject);
    Readable.from((function* () {
      for (const c of chunks(totalBytes)) { hash?.update(c); yield c; }
    })()).pipe(req);
  });
}

const token = () => jwt.sign({ id: 'u1' }, 'test-secret', { expiresIn: '1h' });

test('the body is forwarded byte for byte with the multipart headers', async () => {
  const up = await upstream();
  const gw = await gateway(up.url);
  try {
    const hash = crypto.createHash('sha256');
    const res = await send(gw.address().port, { token: token(), totalBytes: 5 * MB + 17, hash, query: '?share=s1' });
    assert.equal(res.status, 204);
    assert.equal(res.headers['x-project-version'], '8');
    assert.equal(up.seen.size, 5 * MB + 17);
    assert.equal(up.seen.sha256, hash.digest('hex'));
    assert.equal(up.seen.headers['content-type'], 'multipart/form-data; boundary=x');
    assert.equal(up.seen.headers['content-length'], String(5 * MB + 17));
    assert.equal(up.seen.headers['x-caller-id'], 'u1');
    assert.equal(up.seen.headers['x-project-version'], '7');
    assert.equal(up.seen.url, '/u1/p1/video?share=s1');
  } finally {
    gw.close();
    up.server.close();
  }
});

test('a request without a valid token is refused and never forwarded', async () => {
  const up = await upstream();
  const gw = await gateway(up.url);
  try {
    const res = await send(gw.address().port, { totalBytes: 2 * MB });
    assert.equal(res.status, 401);
    const bad = await send(gw.address().port, { token: 'not-a-jwt', totalBytes: 2 * MB });
    assert.equal(bad.status, 401);
    assert.equal(up.seen.requests, 0);
  } finally {
    gw.close();
    up.server.close();
  }
});

test('memory stays bounded while a 256 MB upload passes through the gateway', async () => {
  const up = await upstream();
  const gw = await gateway(up.url);
  const base = process.memoryUsage();
  let peak = 0;
  const timer = setInterval(() => {
    const m = process.memoryUsage();
    peak = Math.max(peak, m.heapUsed + m.arrayBuffers - (base.heapUsed + base.arrayBuffers));
  }, 20);
  try {
    const res = await send(gw.address().port, { token: token(), totalBytes: 256 * MB });
    assert.equal(res.status, 204);
    assert.equal(up.seen.size, 256 * MB);
  } finally {
    clearInterval(timer);
    gw.close();
    up.server.close();
  }
  // multer.memoryStorage would need at least the whole file (256 MB) here
  assert.ok(peak < 64 * MB, `peak memory growth ${(peak / MB).toFixed(1)} MB`);
});
