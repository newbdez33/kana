const test = require('node:test');
const assert = require('node:assert/strict');
const { createQuestion, PracticeSession, emptyStats, isValidStats } = require('../app/core.js');

const pool = [
  ['a', 'あ', 'ア'], ['i', 'い', 'イ'], ['u', 'う', 'ウ'],
  ['e', 'え', 'エ'], ['o', 'お', 'オ'], ['ne', 'ね', 'ネ']
];

function randomSource(seed = 17) {
  return function () {
    seed = (Math.imul(1664525, seed) + 1013904223) >>> 0;
    return seed / 4294967296;
  };
}

function setup(stats) {
  let now = 0;
  const session = new PracticeSession(pool, { now: () => now, random: randomSource(), stats });
  session.start();
  return { session, advance: (milliseconds) => { now += milliseconds; } };
}

test('questions have four distinct kana and one answer in a different form', () => {
  const random = randomSource();
  const seen = new Set();
  for (let index = 0; index < 1000; index++) {
    const question = createQuestion(pool, random);
    assert.equal(question.answers.length, 4);
    assert.equal(new Set(question.answers.map((answer) => answer.kana[0])).size, 4);
    assert.equal(question.answers[question.correctIndex].kana[0], question.kana[0]);
    assert.notEqual(question.answers[question.correctIndex].label, question.prompt);
    assert.ok(question.kana.includes(question.prompt));
    question.answers.forEach((answer) => assert.ok(answer.kana.includes(answer.label)));
    seen.add(question.kana[0]);
  }
  assert.equal(seen.size, pool.length);
});

test('a correct answer records time and advances immediately', () => {
  const { session, advance } = setup();
  const previous = session.question;
  advance(1250);
  assert.equal(session.answer(previous.correctIndex).kind, 'correct');
  assert.notEqual(session.question, previous);
  assert.deepEqual(session.snapshot(), {
    version: 1, totalCount: 1, totalCost: 1.25, recentCosts: [1.25], currentStreak: 1, bestStreak: 1
  });
});

test('a correction preserves timing samples but does not add to the streak', () => {
  const { session, advance } = setup();
  const question = session.question;
  advance(1200);
  assert.equal(session.answer((question.correctIndex + 1) % 4).kind, 'incorrect');
  assert.equal(session.phase, 'revealed');
  assert.equal(session.question, question);
  advance(600);
  const correction = session.answer(question.correctIndex);
  assert.equal(correction.kind, 'correct');
  assert.equal(correction.firstAttempt, false);
  assert.equal(session.snapshot().totalCount, 2);
  assert.deepEqual(session.snapshot().recentCosts, [1.2, 1.8]);
  assert.equal(session.snapshot().currentStreak, 0);
});

test('timeout resets the streak and does not add an answer-time sample', () => {
  const { session, advance } = setup();
  advance(1000);
  session.answer(session.question.correctIndex);
  const question = session.question;
  advance(5000);
  assert.equal(session.tick().kind, 'timeout');
  assert.equal(session.phase, 'revealed');
  assert.equal(session.question, question);
  assert.equal(session.snapshot().totalCount, 1);
  assert.equal(session.snapshot().currentStreak, 0);
  assert.equal(session.snapshot().bestStreak, 1);
  assert.equal(session.tick().kind, 'idle');
  advance(1000);
  session.answer(question.correctIndex);
  assert.equal(session.snapshot().totalCount, 1);
  assert.equal(session.snapshot().currentStreak, 0);
});

test('a tap at the deadline resolves the timeout before it can answer a new question', () => {
  const { session, advance } = setup();
  advance(5000);
  assert.equal(session.answer(session.question.correctIndex).kind, 'timeout');
  assert.equal(session.snapshot().bestStreak, 0);
  assert.equal(session.phase, 'revealed');
});

test('menu and background time do not affect the answer time or deadline', () => {
  const { session, advance } = setup();
  advance(1500);
  session.setPaused(true);
  advance(60000);
  session.setPaused(true);
  assert.equal(session.tick().kind, 'idle');
  assert.equal(session.answer(session.question.correctIndex).kind, 'idle');
  assert.equal(session.remaining(), 3500);
  session.setPaused(false);
  advance(500);
  session.answer(session.question.correctIndex);
  assert.equal(session.snapshot().totalCost, 2);
});

test('only the most recent ten timed answers contribute to the recent average', () => {
  const { session, advance } = setup();
  for (let index = 0; index < 10; index++) {
    advance(1000);
    session.answer(session.question.correctIndex);
  }
  advance(3000);
  session.answer(session.question.correctIndex);
  const stats = session.snapshot();
  assert.equal(stats.totalCount, 11);
  assert.equal(stats.totalCost, 13);
  assert.equal(stats.recentCosts.length, 10);
  assert.equal(stats.recentCosts.reduce((sum, cost) => sum + cost, 0) / 10, 1.2);
});

test('saved statistics restore without sharing mutable arrays', () => {
  const saved = { version: 1, totalCount: 2, totalCost: 5, recentCosts: [2, 3], currentStreak: 2, bestStreak: 3 };
  const { session, advance } = setup(saved);
  advance(1000);
  session.answer(session.question.correctIndex);
  assert.equal(session.snapshot().bestStreak, 3);
  assert.deepEqual(saved.recentCosts, [2, 3]);
  const snapshot = session.snapshot();
  snapshot.recentCosts.push(5);
  assert.equal(session.snapshot().recentCosts.length, 3);
});

test('invalid or future storage records are rejected instead of displayed as statistics', () => {
  assert.equal(isValidStats(emptyStats()), true);
  for (const value of [null, [], {}, { ...emptyStats(), version: 2 },
    { ...emptyStats(), totalCount: -1 }, { ...emptyStats(), totalCost: Infinity },
    { ...emptyStats(), recentCosts: [6] }, { ...emptyStats(), currentStreak: 5 }]) {
    assert.equal(isValidStats(value), false);
  }
});
