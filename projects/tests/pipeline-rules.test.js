const test = require('node:test');
const assert = require('node:assert/strict');
const {
  pipelineIssues, blockingIssue, describeIssue, toolErrors, unavailableTools, frameExtractionIssue,
} = require('../utils/pipelineRules');

const image = { _id: 'img', media_type: 'image' };
const video = { _id: 'vid', media_type: 'video', video: { duration: 5 } };
const tool = (procedure, params = {}, position = 0, _id = procedure) => ({ _id, procedure, params, position });
const codes = (issues) => issues.map((i) => `${i.procedure}:${i.code}:${i.severity}`);

test('valid pipelines have no issues', () => {
  const cases = [
    { imgs: [image], tools: [tool('brightness'), tool('bg_remove_ai', {}, 1)] },
    { imgs: [video], tools: [tool('brightness'), tool('trim', { start: 1, end: 3, imgId: 'vid' }, 1)] },
    { imgs: [video], tools: [tool('contrast'), tool('speed', { factor: 2, imgId: 'vid' }, 1)] },
    { imgs: [image, video], tools: [tool('border'), tool('extract_frames', { mode: 'count', count: 3, format: 'png' }, 1)] },
    { imgs: [image, video], tools: [tool('brightness'), tool('trim', { start: 0, end: 5.04, imgId: 'vid' }, 1)] },
    { imgs: [], tools: [tool('text_ai')] },
  ];
  for (const project of cases) assert.deepEqual(pipelineIssues(project), [], JSON.stringify(project.tools));
});

test('image-only tools in a project with videos are errors that name the tool and the fix', () => {
  const project = { imgs: [image, video], tools: [tool('brightness'), tool('bg_remove_ai', {}, 1)] };
  const issues = pipelineIssues(project);
  assert.deepEqual(codes(issues), ['bg_remove_ai:image_only_tool:error']);
  const text = describeIssue(blockingIssue(issues));
  assert.match(text, /AI Background Removal only works on images/);
  assert.match(text, /Remove AI Background Removal/);
});

test('video-only tools without videos: error when nothing else runs, warning otherwise', () => {
  const only = { imgs: [image], tools: [tool('trim', { start: 1, end: 3, imgId: 'gone' })] };
  assert.deepEqual(codes(pipelineIssues(only)), ['trim:video_only_tool:error']);
  const mixed = { imgs: [image], tools: [tool('brightness'), tool('subtitles', {}, 1)] };
  assert.deepEqual(codes(pipelineIssues(mixed)), ['subtitles:video_only_tool:warning']);
  assert.equal(blockingIssue(pipelineIssues(mixed)), null);
});

test('a per-video tool whose video was deleted is a warning while other videos remain', () => {
  const other = { _id: 'v2', media_type: 'video', video: { duration: 9 } };
  const project = { imgs: [other], tools: [tool('brightness'), tool('trim', { start: 1, end: 3, imgId: 'vid' }, 1)] };
  assert.deepEqual(codes(pipelineIssues(project)), ['trim:missing_video:warning']);
});

test('trim times and speed factor are checked against the video', () => {
  const beyond = { imgs: [video], tools: [tool('trim', { start: 1, end: 8, imgId: 'vid' })] };
  assert.deepEqual(codes(pipelineIssues(beyond)), ['trim:trim_times:error']);
  assert.match(describeIssue(pipelineIssues(beyond)[0]), /ends at 8 s, but the video lasts 5 s.*up to 5 s/);
  const reversed = { imgs: [video], tools: [tool('trim', { start: 3, end: 2, imgId: 'vid' })] };
  assert.deepEqual(codes(pipelineIssues(reversed)), ['trim:trim_times:error']);
  const fast = { imgs: [video], tools: [tool('speed', { factor: 8, imgId: 'vid' })] };
  assert.deepEqual(codes(pipelineIssues(fast)), ['speed:speed_factor:error']);
});

test('frame extraction keeps its rules and gets a fix', () => {
  const tools = [tool('extract_frames', { mode: 'count', count: 3, format: 'png' }), tool('brightness', {}, 1)];
  const project = { imgs: [video], tools };
  assert.deepEqual(codes(pipelineIssues(project)), ['extract_frames:frame_extraction:error']);
  assert.match(describeIssue(frameExtractionIssue(tools)), /must be the last tool.*Move Extract frames to the end/);
});

test('only the tool being added or edited is judged, so corrections are never blocked', () => {
  // the project already has an incompatible tool; adding a compatible one is fine
  const project = { imgs: [image, video], tools: [tool('bg_remove_ai')] };
  assert.deepEqual(toolErrors(project, tool('brightness')), []);
  assert.equal(toolErrors(project, tool('watermark'))[0].code, 'image_only_tool');
  assert.equal(toolErrors({ imgs: [image], tools: [] }, tool('subtitles'))[0].code, 'video_only_tool');
  assert.deepEqual(toolErrors(project, tool('trim', { start: 0, end: 4, imgId: 'vid' })), []);
});

test('unavailable tools follow the media of the project', () => {
  const withVideo = unavailableTools({ imgs: [image, video] }).map((t) => t.procedure);
  assert.ok(withVideo.includes('watermark') && withVideo.includes('cut_ai'));
  assert.ok(!withVideo.includes('brightness') && !withVideo.includes('trim'));
  const imagesOnly = unavailableTools({ imgs: [image] }).map((t) => t.procedure).sort();
  assert.deepEqual(imagesOnly, ['extract_frames', 'speed', 'subtitles', 'trim']);
});
