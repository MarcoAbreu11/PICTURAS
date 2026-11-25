const test = require('node:test');
const assert = require('node:assert/strict');
const { requireVideoProfile } = require('../utils/uploadProfile');

// Runs the middleware with a fake response; resolves to what happened.
function run(lookupType) {
  return new Promise((resolve) => {
    const req = {};
    const res = {
      status(code) { this.code = code; return this; },
      jsonp(body) { resolve({ next: false, status: this.code, body, req }); },
    };
    requireVideoProfile(lookupType)(req, res, () => resolve({ next: true, req }));
  });
}

test('anonymous callers are rejected before the video body is read', async () => {
  const r = await run(async () => 'anonymous');
  assert.equal(r.next, false);
  assert.equal(r.status, 403);
  assert.match(r.body, /Anonymous users cannot upload videos/);
});

test('a failed profile lookup refuses the upload instead of running unlimited', async () => {
  const r = await run(async () => { throw new Error('users down'); });
  assert.equal(r.next, false);
  assert.equal(r.status, 503);
});

test('an unknown profile type is rejected', async () => {
  const r = await run(async () => undefined);
  assert.equal(r.status, 403);
});

test('free and premium callers continue with their type set', async () => {
  for (const type of ['free', 'premium']) {
    const r = await run(async () => type);
    assert.equal(r.next, true);
    assert.equal(r.req.uploadUserType, type);
  }
});
