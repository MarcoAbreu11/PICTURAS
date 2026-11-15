const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('crypto');
const fs = require('fs');
const os = require('os');
const path = require('path');
const http = require('http');
const { Readable } = require('stream');
const express = require('express');
const { receiveUpload } = require('../utils/uploadStorage');

const MB = 1024 * 1024;
const BOUNDARY = 'picturas-test-boundary';

// Deterministic pseudo-random chunks, generated lazily so the test client
// itself never holds the whole file.
function* chunks(totalBytes, chunkBytes = MB) {
  let seed = 7;
  for (let sent = 0; sent < totalBytes; sent += chunkBytes) {
    const n = Math.min(chunkBytes, totalBytes - sent);
    const b = Buffer.allocUnsafe(n);
    for (let i = 0; i < n; i += 4) {
      seed = (seed * 1103515245 + 12345) >>> 0;
      b.writeUInt32LE(seed, i <= n - 4 ? i : n - 4);
    }
    yield b;
  }
}

function multipartBody(field, filename, totalBytes, hash) {
  const head = Buffer.from(
    `--${BOUNDARY}\r\nContent-Disposition: form-data; name="${field}"; filename="${filename}"\r\n` +
      'Content-Type: video/mp4\r\n\r\n'
  );
  const tail = Buffer.from(`\r\n--${BOUNDARY}--\r\n`);
  return {
    length: head.length + totalBytes + tail.length,
    stream: Readable.from((function* () {
      yield head;
      for (const c of chunks(totalBytes)) {
        if (hash) hash.update(c);
        yield c;
      }
      yield tail;
    })()),
  };
}

function post(port, body, { chunked = false } = {}) {
  return new Promise((resolve, reject) => {
    const headers = { 'Content-Type': `multipart/form-data; boundary=${BOUNDARY}` };
    if (!chunked) headers['Content-Length'] = body.length;
    const req = http.request({ port, method: 'POST', path: '/upload', headers }, (res) => {
      let data = '';
      res.on('data', (d) => (data += d));
      res.on('end', () => resolve({ status: res.statusCode, body: data ? JSON.parse(data) : null }));
    });
    req.on('error', reject);
    body.stream.pipe(req);
  });
}

async function withServer(limitBytes, dir, fn) {
  const app = express();
  let seenFile = null;
  app.post('/upload', receiveUpload('video', { getLimitBytes: () => limitBytes, dir }), (req, res) => {
    seenFile = { ...req.file, existedDuringRequest: fs.existsSync(req.file.path) };
    res.status(200).json({ size: req.file.size, sha256: req.file.sha256 });
  });
  const server = app.listen(0);
  await new Promise((r) => server.once('listening', r));
  try {
    return await fn(server.address().port, () => seenFile);
  } finally {
    server.close();
  }
}

const tmpDir = () => fs.mkdtempSync(path.join(os.tmpdir(), 'upload-test-'));
const settle = () => new Promise((r) => setTimeout(r, 100));

test('a streamed upload reaches a temporary file with the right size and SHA-256', async () => {
  const dir = tmpDir();
  const hash = crypto.createHash('sha256');
  const size = 3 * MB + 123;
  await withServer(null, dir, async (port, seen) => {
    const res = await post(port, multipartBody('video', 'clip.mp4', size, hash));
    assert.equal(res.status, 200);
    assert.equal(res.body.size, size);
    assert.equal(res.body.sha256, hash.digest('hex'));
    assert.equal(seen().existedDuringRequest, true);
    assert.equal(path.dirname(seen().path), dir);
    assert.equal(seen().originalname, 'clip.mp4');
  });
  await settle();
  assert.deepEqual(fs.readdirSync(dir), [], 'temporary file removed after the response');
});

test('a Content-Length above the profile limit is rejected before the body is read', async () => {
  const dir = tmpDir();
  await withServer(10 * MB, dir, async (port) => {
    const res = await post(port, multipartBody('video', 'big.mp4', 20 * MB));
    assert.equal(res.status, 400);
    assert.match(res.body, /^The video is 20\.0 MB and your profile limit is 10 MB$/);
  });
  assert.deepEqual(fs.readdirSync(dir), [], 'nothing was written to disk');
});

test('a chunked upload over the limit is stopped and leaves no partial file', async () => {
  const dir = tmpDir();
  await withServer(5 * MB, dir, async (port) => {
    const res = await post(port, multipartBody('video', 'big.mp4', 12 * MB), { chunked: true });
    assert.equal(res.status, 400);
    assert.equal(res.body, 'The video exceeds your profile limit of 5 MB');
  });
  await settle();
  assert.deepEqual(fs.readdirSync(dir), []);
});

test('a file within the limit is accepted', async () => {
  const dir = tmpDir();
  await withServer(5 * MB, dir, async (port) => {
    const res = await post(port, multipartBody('video', 'ok.mp4', 4 * MB));
    assert.equal(res.status, 200);
  });
});

test('memory stays bounded while a 256 MB upload is received', async () => {
  const dir = tmpDir();
  const size = 256 * MB;
  global.gc?.();
  const base = process.memoryUsage();
  let peak = 0;
  const timer = setInterval(() => {
    const m = process.memoryUsage();
    peak = Math.max(peak, m.heapUsed + m.arrayBuffers - (base.heapUsed + base.arrayBuffers));
  }, 20);
  try {
    await withServer(null, dir, async (port) => {
      const res = await post(port, multipartBody('video', 'large.mp4', size));
      assert.equal(res.status, 200);
      assert.equal(res.body.size, size);
    });
  } finally {
    clearInterval(timer);
  }
  // memoryStorage would need at least the whole file (256 MB) here
  assert.ok(peak < 64 * MB, `peak memory growth ${(peak / MB).toFixed(1)} MB`);
});
