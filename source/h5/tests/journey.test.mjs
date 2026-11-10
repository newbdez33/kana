import test from 'node:test';
import assert from 'node:assert/strict';
import { Journey, MEADOWS, STEPS_PER_MEADOW } from '../../../build/h5/journey.mjs';

test('only correct answers move the rabbit, and review does not erase the trail', () => {
  const journey = new Journey();
  journey.record('correct');
  journey.record('incorrect');
  journey.record('timeout');
  journey.record('review');
  assert.equal(journey.hops, 1);
  assert.equal(journey.view.step, 1);
  assert.equal(journey.view.remaining, STEPS_PER_MEADOW - 1);
});

test('the eighth correct answer reaches a new meadow without losing total progress', () => {
  const journey = new Journey();
  for (let index = 0; index < STEPS_PER_MEADOW - 1; index += 1) journey.record('correct');
  assert.equal(journey.view.meadow, MEADOWS[0]);
  assert.equal(journey.view.remaining, 1);
  assert.equal(journey.record('correct'), true);
  assert.equal(journey.view.meadow, MEADOWS[1]);
  assert.equal(journey.view.step, 0);
  assert.equal(journey.view.chapter, 2);
  assert.equal(journey.hops, STEPS_PER_MEADOW);
});

test('a saved journey survives reload and continues after every meadow', () => {
  const journey = new Journey();
  for (let index = 0; index < MEADOWS.length * STEPS_PER_MEADOW + 3; index += 1) journey.record('correct');
  const restored = new Journey(journey.savedProgress());
  assert.equal(restored.view.meadow, MEADOWS[0]);
  assert.equal(restored.view.chapter, MEADOWS.length + 1);
  assert.equal(restored.view.step, 3);
  restored.record('correct');
  assert.equal(restored.hops, journey.hops + 1);
});

test('invalid saved journeys start safely and progress remains a safe integer', () => {
  for (const value of [null, {}, { version: 2, hops: 9 }, { version: 1, hops: -1 },
    { version: 1, hops: 2.5 }, { version: 1, hops: '8' }, { version: 1, hops: Infinity }]) {
    assert.equal(new Journey(value).hops, 0);
  }
  const journey = new Journey({ version: 1, hops: Number.MAX_SAFE_INTEGER });
  journey.record('correct');
  assert.equal(journey.hops, Number.MAX_SAFE_INTEGER);
  assert.ok(journey.view.meadow);
});
