const test = require('node:test');
const assert = require('node:assert/strict');
const { FeedbackRun, stageFor, levels } = require('../app/feedback.js');

test('streak feedback restores records and caps the five stages', () => {
  const run = new FeedbackRun({currentStreak:29,bestStreak:29});
  const result = run.consume({kind:'correct',firstAttempt:true},{currentStreak:30,bestStreak:30});
  assert.equal(result.stage,4);
  assert.equal(result.milestone,true);
  assert.equal(result.record,true);
  assert.equal(result.strength,'heavy');
  assert.equal(run.consume({kind:'correct',firstAttempt:true},{currentStreak:31,bestStreak:31}).record,false);
  assert.equal(stageFor(10000),4);
  assert.deepEqual(levels.map(level=>level.bpm),[0,0,80,100,120]);
});

test('corrections and retries never produce a hit, record, or haptic pulse', () => {
  const run = new FeedbackRun({currentStreak:5,bestStreak:5});
  assert.equal(run.consume({kind:'incorrect',firstAttempt:true},{currentStreak:0,bestStreak:5}).broken,5);
  const retry=run.consume({kind:'incorrect',firstAttempt:false},{currentStreak:0,bestStreak:5});
  const correction=run.consume({kind:'correct',firstAttempt:false},{currentStreak:0,bestStreak:5});
  assert.equal(retry.kind,'retry');
  assert.equal(correction.kind,'correction');
  assert.equal(correction.strength,null);
  assert.equal(correction.record,false);
  assert.equal(correction.milestone,false);
});

test('milestones use medium or heavy pulses while ordinary hits stay light or medium', () => {
  const run = new FeedbackRun({currentStreak:0,bestStreak:100});
  const strengths = [1,5,6,10,11,20,21,30,31].map(combo => run.consume(
    {kind:'correct',firstAttempt:true},{currentStreak:combo,bestStreak:100}).strength);
  assert.deepEqual(strengths,['light','medium','light','medium','medium','heavy','medium','heavy','medium']);
  const timeout=run.consume({kind:'timeout'},{currentStreak:0,bestStreak:100});
  assert.equal(timeout.broken,31);
  assert.equal(timeout.strength,null);
});

test('a new run can celebrate a new record once without changing saved statistics', () => {
  const stats={currentStreak:6,bestStreak:6};
  const run=new FeedbackRun({currentStreak:0,bestStreak:5});
  assert.equal(run.consume({kind:'correct',firstAttempt:true},stats).record,true);
  assert.deepEqual(stats,{currentStreak:6,bestStreak:6});
  run.consume({kind:'timeout'},{currentStreak:0,bestStreak:6});
  assert.equal(run.consume({kind:'correct',firstAttempt:true},{currentStreak:7,bestStreak:7}).record,true);
});
