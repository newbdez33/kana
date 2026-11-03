(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.KanaAudio = factory();
}(typeof window === 'object' ? window : this, function () {
  'use strict';
  function createSoundPlayer(host, onBeat) {
    let context = null;
    let voices = [];
    let generation = 0;
    let beatTimer = null;
    let rhythm = 0;
    let rhythmEnabled = false;
    const clock = (host.setTimeout || setTimeout).bind(host);
    const cancel = (host.clearTimeout || clearTimeout).bind(host);

    function release(channel) {
      if (!context) return;
      voices.slice().forEach(function (voice) {
        if (channel && voice.channel !== channel) return;
        try {
          voice.gain.gain.cancelScheduledValues(context.currentTime);
          voice.gain.gain.setTargetAtTime(0.0001, context.currentTime, 0.004);
          voice.oscillator.stop(context.currentTime + 0.025);
        } catch (error) { /* A completed voice needs no release. */ }
      });
    }

    function tone(frequency, start, length, amplitude, shape, channel, endFrequency) {
      const oscillator = context.createOscillator();
      const gain = context.createGain();
      const voice = { oscillator: oscillator, gain: gain, channel: channel };
      oscillator.type = shape;
      oscillator.frequency.setValueAtTime(frequency, start);
      if (endFrequency) oscillator.frequency.exponentialRampToValueAtTime(endFrequency, start + length);
      gain.gain.setValueAtTime(0.0001, start);
      gain.gain.exponentialRampToValueAtTime(amplitude, start + 0.007);
      gain.gain.exponentialRampToValueAtTime(0.0001, start + length);
      oscillator.connect(gain);
      gain.connect(context.destination);
      voices.push(voice);
      oscillator.onended = function () {
        oscillator.disconnect();
        gain.disconnect();
        voices = voices.filter(function (item) { return item !== voice; });
      };
      oscillator.start(start);
      oscillator.stop(start + length + 0.015);
    }

    function scheduleBeat() {
      cancel(beatTimer);
      if (!rhythmEnabled || !rhythm || !context || context.state !== 'running') return;
      beatTimer = clock(function () {
        if (!rhythmEnabled || (host.document && host.document.hidden)) return;
        try { tone(145, context.currentTime, 0.11, 0.035, 'sine', 'beat', 70); }
        catch (error) { /* Visual feedback remains available. */ }
        if (onBeat) onBeat();
        scheduleBeat();
      }, 60000 / rhythm);
    }

    async function play(kind, stage, userGesture) {
      const ticket = ++generation;
      try {
        if (!context) {
          const AudioContext = host.AudioContext || host.webkitAudioContext;
          if (!userGesture || !AudioContext) return false;
          try {
            if (host.navigator && host.navigator.audioSession) host.navigator.audioSession.type = 'playback';
          } catch (error) { /* Audio Session is an optional enhancement. */ }
          context = new AudioContext();
        }
        if (context.state === 'suspended') {
          if (!userGesture) return false;
          await context.resume();
        }
        if (ticket !== generation || (host.document && host.document.hidden)) return false;
        release('effect');
        const start = context.currentTime + 0.003;
        if (kind === 'break') {
          tone(240, start, 0.17, 0.075, 'sine', 'effect', 100);
        } else if (kind === 'correction') {
          tone(540, start, 0.08, 0.045, 'sine', 'effect');
        } else {
          const base = [660, 740, 830, 880, 990][Math.max(0, Math.min(4, stage))];
          tone(170, start, 0.045, 0.11, 'triangle', 'effect', 55);
          tone(base, start + 0.018, 0.11, 0.065, 'sine', 'effect');
          if (kind === 'milestone' || kind === 'record') {
            [1, 1.25, 1.5].forEach(function (ratio, index) {
              tone(base * ratio, start + 0.055 + index * 0.055, 0.22, 0.045, 'sine', 'effect');
            });
          }
          if (kind === 'record') tone(base * 2, start + 0.22, 0.28, 0.035, 'sine', 'effect');
        }
        if (rhythmEnabled && !beatTimer) scheduleBeat();
        return true;
      } catch (error) { return false; }
    }

    function setRhythm(bpm, enabled) {
      if (rhythm === bpm && rhythmEnabled === enabled) return;
      rhythm = bpm;
      rhythmEnabled = enabled;
      cancel(beatTimer);
      beatTimer = null;
      release('beat');
      scheduleBeat();
    }
    function stop() {
      generation += 1;
      rhythmEnabled = false;
      cancel(beatTimer);
      beatTimer = null;
      release();
    }
    return { play: play, setRhythm: setRhythm, stop: stop };
  }
  return { createSoundPlayer: createSoundPlayer };
}));
