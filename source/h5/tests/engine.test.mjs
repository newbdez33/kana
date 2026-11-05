import test from 'node:test';
import assert from 'node:assert/strict';
import { Game, createQuestion, readStatistics } from '../../../build/h5/engine.mjs';
import { entries } from '../../../build/h5/kana-data.mjs';

function seededRandom(seed = 7) {
  return () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; };
}

test('questions contain four distinct choices and exactly one equivalent kana', () => {
  const random = seededRandom();
  const observed = new Set();
  for (let index = 0; index < 2000; index += 1) {
    const question = createQuestion(entries, random);
    assert.equal(question.choices.length, 4);
    assert.equal(new Set(question.choices).size, 4);
    assert.equal(question.choices.filter(choice => question.kana.includes(choice)).length, 1);
    assert.ok(question.kana.includes(question.choices[question.correctIndex]));
    assert.notEqual(question.prompt, question.choices[question.correctIndex]);
    observed.add(question.kana[0]);
  }
  assert.equal(observed.size, 46);
});

test('the deadline takes priority over an answer at exactly five seconds', () => {
  const game = new Game(entries);
  game.start(100);
  assert.equal(game.answer(game.question.correctIndex, 5100).kind, 'timeout');
  assert.equal(game.statistics.count, 0);
  assert.equal(game.tick(5200), null);
  assert.equal(game.answer(0, 5200), null);
});

test('a wrong answer counts once and resets the current streak', () => {
  const game = new Game(entries);
  game.start(0);
  game.answer(game.question.correctIndex, 1000);
  game.start(1100);
  const wrong = (game.question.correctIndex + 1) % 4;
  assert.equal(game.answer(wrong, 3100).kind, 'incorrect');
  assert.equal(game.answer(wrong, 3200), null);
  assert.equal(game.statistics.count, 2);
  assert.equal(game.statistics.totalMs, 3000);
  assert.equal(game.statistics.bestStreak, 1);
  assert.equal(game.streak, 0);
});

test('overlapping chart, manual and background pauses preserve time', () => {
  const game = new Game(entries);
  game.start(100);
  game.pause('chart', 1100);
  game.pause('visibility', 2100);
  game.pause('manual', 3100);
  assert.equal(game.answer(game.question.correctIndex, 4000), null);
  game.resume('chart', 7100);
  game.resume('visibility', 8100);
  assert.equal(game.remaining(9100), 4000);
  game.resume('manual', 10100);
  assert.equal(game.remaining(11100), 3000);
  assert.equal(game.answer(game.question.correctIndex, 11100).kind, 'correct');
  assert.equal(game.statistics.totalMs, 2000);
});

test('opening a pause after the deadline cannot save an expired answer', () => {
  const game = new Game(entries);
  game.start(0);
  game.pause('chart', 5001);
  assert.equal(game.phase, 'feedback');
  assert.equal(game.result.kind, 'timeout');
});

test('new questions remain paused until all pause reasons are removed', () => {
  const game = new Game(entries);
  game.pause('visibility', 0);
  game.start(1000);
  assert.equal(game.remaining(10000), 5000);
  game.resume('unknown', 10000);
  assert.equal(game.remaining(11000), 5000);
  game.resume('visibility', 12000);
  assert.equal(game.remaining(13000), 4000);
});

test('statistics retain only the last ten timed answers and survive reload', () => {
  const game = new Game(entries);
  for (let index = 1; index <= 15; index += 1) {
    game.start(index * 10000);
    game.answer(game.question.correctIndex, index * 10000 + index * 100);
  }
  assert.deepEqual(game.statistics.recentMs, [600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500]);
  const restored = new Game(entries, game.savedStatistics());
  assert.deepEqual(restored.statistics, game.statistics);
  assert.equal(restored.streak, 0);
  restored.statistics.recentMs.push(1);
  assert.equal(game.statistics.recentMs.length, 10);
});

test('invalid stored statistics and unsupported versions use an empty record', () => {
  for (const value of [null, {}, { version: 2 }, { version: 1, count: -1 }, { version: 1, count: 1, totalMs: Infinity, recentMs: [], bestStreak: 0 }, { version: 1, count: 1, totalMs: 1000, recentMs: [5000], bestStreak: 1 }]) {
    assert.deepEqual(readStatistics(value), { count: 0, totalMs: 0, recentMs: [], bestStreak: 0 });
  }
});

test('invalid answer indices cannot change the current question', () => {
  const game = new Game(entries);
  game.start(0);
  for (const index of [-1, 4, 0.5, NaN, '1']) assert.equal(game.answer(index, 1000), null);
  assert.equal(game.phase, 'playing');
  assert.equal(game.statistics.count, 0);
});
