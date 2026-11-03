const test = require('node:test');
const assert = require('node:assert/strict');
const { createSoundPlayer } = require('../app/audio.js');

function audioHost() {
  const events = [];
  class AudioContext {
    constructor() { events.push('context'); this.currentTime = 0; this.state = 'running'; }
    createGain() {
      return { connect() {}, gain: { setValueAtTime() {}, exponentialRampToValueAtTime() {} } };
    }
    createOscillator() {
      return {
        frequency: { setValueAtTime(value) { events.push(value); }, exponentialRampToValueAtTime() {} },
        connect() {}, disconnect() {}, start() { events.push('start'); }, stop() { events.push('stop'); }
      };
    }
  }
  return { host: { AudioContext }, events };
}

test('no audio context is created before a user gesture', () => {
  const { host, events } = audioHost();
  createSoundPlayer(host).play('break', 0, false);
  assert.deepEqual(events, []);
});

test('a user answer enables short synthesized feedback without media URLs', () => {
  const { host, events } = audioHost();
  const player = createSoundPlayer(host);
  player.play('hit', 0, true);
  assert.equal(events[0], 'context');
  assert.equal(events.filter(event => event === 'start').length, 2);
  player.stop();
  player.play('break', 0, false);
  assert.equal(events.filter(event => event === 'context').length, 1);
});

test('missing or rejected audio support does not interrupt practice', () => {
  assert.doesNotThrow(() => createSoundPlayer({}).play('hit', 0, true));
  assert.doesNotThrow(() => createSoundPlayer({ AudioContext: class { constructor() { throw new Error('Blocked'); } } }).play('hit', 0, true));
});

test('the first user answer selects playback audio before creating the context', () => {
  const { host, events } = audioHost();
  host.navigator = { audioSession: {} };
  Object.defineProperty(host.navigator.audioSession, 'type', {
    set(value) { events.push('session:' + value); }
  });
  const player = createSoundPlayer(host);
  player.play('break', 0, false);
  assert.deepEqual(events, []);
  player.play('hit', 0, true);
  assert.deepEqual(events.slice(0, 2), ['session:playback', 'context']);
  assert.equal(events.filter(event => event === 'start').length, 2);
});

test('an unavailable or rejected audio session API does not block supported audio', () => {
  for (const deniedAccess of ['get', 'set']) {
    const { host, events } = audioHost();
    host.navigator = {};
    if (deniedAccess === 'get') {
      Object.defineProperty(host.navigator, 'audioSession', {
        get() { throw new Error('Unavailable'); }
      });
    } else {
      host.navigator.audioSession = {};
      Object.defineProperty(host.navigator.audioSession, 'type', {
        set() { throw new Error('Rejected'); }
      });
    }
    createSoundPlayer(host).play('hit', 0, true);
    assert.equal(events.filter(event => event === 'start').length, 2);
  }
});
