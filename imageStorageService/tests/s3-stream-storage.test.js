const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('crypto');
const http = require('http');
const { Readable } = require('stream');
const express = require('express');
const multer = require('multer');

// No S3 server in unit tests: the bucket check succeeds immediately.
const s3 = require('../services/s3Client');
s3.headBucket = () => ({ promise: async () => ({}) });

const uploadImage = require('../services/uploadImage');
const s3StreamStorage = require('../services/s3StreamStorage');

const MB = 1024 * 1024;
const BOUNDARY = 'picturas-test-boundary';

function* chunks(totalBytes, chunkBytes = MB) {
  let byte = 0;
  for (let sent = 0; sent < totalBytes; sent += chunkBytes) {
    const n = Math.min(chunkBytes, totalBytes - sent);
    yield Buffer.alloc(n, byte++ % 251);
  }
}

function multipart(totalBytes, hash) {
  const head = Buffer.from(
    `--${BOUNDARY}\r\nContent-Disposition: form-data; name="file"; filename="v.mp4"\r\nContent-Type: video/mp4\r\n\r\n`
  );
  const tail = Buffer.from(`\r\n--${BOUNDARY}--\r\n`);
  return {
    length: head.length + totalBytes + tail.length,
    stream: Readable.from((function* () {
      yield head;
      for (const c of chunks(totalBytes)) {
        hash?.update(c);
        yield c;
      }
      yield tail;
    })()),
  };
}

function post(port, body) {
  return new Promise((resolve, reject) => {
    const req = http.request({
      port, method: 'POST', path: '/u1/p1/src',
      headers: { 'Content-Type': `multipart/form-data; boundary=${BOUNDARY}`, 'Content-Length': body.length },
    }, (res) => {
      let data = '';
      res.on('data', (d) => (data += d));
      res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(data || 'null') }));
    });
    req.on('error', reject);
    body.stream.pipe(req);
  });
}

async function withApp(upload, fn) {
  const app = express();
  const parser = multer({ storage: s3StreamStorage(upload) });
  app.post('/:userId/:projectId/:stage', (req, res) => parser.single('file')(req, res, (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.status(201).json(req.file);
  }));
  const server = app.listen(0);
  await new Promise((r) => server.once('listening', r));
  try { return await fn(server.address().port); } finally { server.close(); }
}

// Fake S3 client that consumes the Body the way the SDK does (as a stream)
function fakeS3Client(record) {
  return {
    upload(params, options) {
      record.params = params;
      record.options = options;
      return {
        promise: async () => {
          const hash = crypto.createHash('sha256');
          let size = 0;
          const body = Buffer.isBuffer(params.Body) ? [params.Body] : params.Body;
          for await (const c of body) { size += c.length; hash.update(c); }
          record.size = size;
          record.sha256 = hash.digest('hex');
          return { Location: `http://s3/${params.Key}` };
        },
      };
    },
  };
}

test('uploadImage sends a stream body with bounded multipart settings', async () => {
  const record = {};
  const body = Readable.from([Buffer.from('abc')]);
  const result = await uploadImage('u1', 'p1', { stream: body, mimetype: 'video/mp4' }, 'src', fakeS3Client(record));
  assert.equal(record.params.Body, body);
  assert.match(record.params.Key, /^users\/u1\/projects\/p1\/src\/[0-9a-f-]+\.mp4$/);
  assert.equal(record.options.partSize, 5 * MB);
  assert.equal(record.options.queueSize, 2);
  assert.match(result.imageKey, /^p1\/src\/[0-9a-f-]+\.mp4$/);
});

test('uploadImage still accepts an in-memory buffer', async () => {
  const record = {};
  await uploadImage('u1', 'p1', { buffer: Buffer.from('abc'), mimetype: 'image/png' }, 'out', fakeS3Client(record));
  assert.equal(record.size, 3);
});

test('the storage engine streams the received file to S3 unchanged', async () => {
  const record = {};
  const hash = crypto.createHash('sha256');
  const upload = (u, p, file, stage) => uploadImage(u, p, file, stage, fakeS3Client(record));
  await withApp(upload, async (port) => {
    const res = await post(port, multipart(7 * MB + 5, hash));
    assert.equal(res.status, 201);
    assert.equal(res.body.size, 7 * MB + 5);
    assert.match(res.body.result.imageKey, /^p1\/src\//);
  });
  assert.equal(record.size, 7 * MB + 5);
  assert.equal(record.sha256, hash.digest('hex'));
});

test('an S3 failure is reported as an error and the client still gets a reply', async () => {
  const upload = async () => { throw new Error('S3 unavailable'); };
  await withApp(upload, async (port) => {
    const res = await post(port, multipart(3 * MB));
    assert.equal(res.status, 500);
    assert.equal(res.body.error, 'S3 unavailable');
  });
});

test('memory stays bounded while a 256 MB file is streamed to S3', async () => {
  const record = {};
  const upload = (u, p, file, stage) => uploadImage(u, p, file, stage, fakeS3Client(record));
  const base = process.memoryUsage();
  let peak = 0;
  const timer = setInterval(() => {
    const m = process.memoryUsage();
    peak = Math.max(peak, m.heapUsed + m.arrayBuffers - (base.heapUsed + base.arrayBuffers));
  }, 20);
  try {
    await withApp(upload, async (port) => {
      const res = await post(port, multipart(256 * MB));
      assert.equal(res.status, 201);
    });
  } finally {
    clearInterval(timer);
  }
  assert.equal(record.size, 256 * MB);
  // memoryStorage would need at least the whole file (256 MB) here
  assert.ok(peak < 64 * MB, `peak memory growth ${(peak / MB).toFixed(1)} MB`);
});
