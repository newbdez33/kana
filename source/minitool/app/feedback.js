(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.KanaFeedback = factory();
}(typeof window === 'object' ? window : this, function () {
  'use strict';
  const levels = [{ min: 0, bpm: 0 }, { min: 5, bpm: 0 }, { min: 10, bpm: 80 }, { min: 20, bpm: 100 }, { min: 30, bpm: 120 }];
  function stageFor(combo) {
    let stage = 0;
    levels.forEach(function (level, index) { if (combo >= level.min) stage = index; });
    return stage;
  }

  class FeedbackRun {
    constructor(stats) {
      this.combo = stats.currentStreak;
      this.recordTarget = stats.bestStreak;
      this.recordShown = false;
    }
    consume(result, stats) {
      if (result.kind === 'idle') return result;
      const kind = result.firstAttempt === false ? result.kind === 'correct' ? 'correction' : 'retry' : result.kind;
      const previous = this.combo;
      this.combo = stats.currentStreak;
      const stage = stageFor(this.combo);
      const correct = kind === 'correct';
      const record = correct && this.recordTarget >= 5 && this.combo > this.recordTarget && !this.recordShown;
      const milestone = correct && this.combo >= 5 && (this.combo === 5 || this.combo % 10 === 0);
      if (record) this.recordShown = true;
      if (kind === 'incorrect' || kind === 'timeout') {
        this.recordTarget = stats.bestStreak;
        this.recordShown = false;
      }
      return {
        kind: kind, combo: this.combo, stage: stage, record: record, milestone: milestone,
        broken: kind === 'incorrect' || kind === 'timeout' ? previous : 0,
        strength: !correct ? null : record || (milestone && stage >= 3) ? 'heavy' : milestone || stage >= 2 ? 'medium' : 'light'
      };
    }
  }

  function createFeedback(host, session, copy) {
    const document = host.document;
    const byId = function (id) { return document.getElementById(id); };
    const surface = byId('workspace');
    const run = new FeedbackRun(session.snapshot());
    const animations = [];
    let frame = null;
    const sound = host.KanaAudio.createSoundPlayer(host, function () { animate(surface, 'feedback-beat', 260); });
    const haptics = host.KanaHaptics.createHaptics(host);
    const reduced = host.matchMedia && host.matchMedia('(prefers-reduced-motion: reduce)');
    byId('motion-setting').checked = !!reduced && reduced.matches;

    function animate(element, name, duration) {
      if (byId('motion-setting').checked && name !== 'feedback-show') return;
      const previous = animations.filter(function (item) { return item.element === element && item.name === name; })[0];
      if (previous) { host.clearTimeout(previous.timer); animations.splice(animations.indexOf(previous), 1); }
      element.classList.remove(name);
      void element.offsetWidth;
      element.classList.add(name);
      const item = { element: element, name: name, timer: null };
      item.timer = host.setTimeout(function () {
        element.classList.remove(name);
        const index = animations.indexOf(item);
        if (index !== -1) animations.splice(index, 1);
      }, duration);
      animations.push(item);
    }

    function stopFrame() {
      if (frame !== null) host.cancelAnimationFrame(frame);
      frame = null;
    }
    function active() { return !document.hidden && session.pausedAt === null && session.phase === 'answering'; }
    function drawTime() {
      const remaining = session.remaining();
      byId('time-fill').style.transform = 'scaleX(' + Math.max(0, Math.min(1, remaining / 5000)) + ')';
      surface.classList.toggle('feedback-urgent', active() && remaining < 2000 && stageFor(run.combo) >= 2);
      if (active()) frame = host.requestAnimationFrame(drawTime);
    }
    function stop() {
      sound.stop(); haptics.stop(); stopFrame();
      animations.splice(0).forEach(function (item) {
        host.clearTimeout(item.timer); item.element.classList.remove(item.name);
      });
      surface.classList.remove('feedback-urgent');
    }
    function sync() {
      const stage = stageFor(run.combo);
      surface.setAttribute('data-stage', String(stage));
      surface.classList.toggle('feedback-paused', session.pausedAt !== null);
      surface.classList.toggle('feedback-reduced', byId('motion-setting').checked);
      byId('streak-count').textContent = String(run.combo);
      byId('stage-name').textContent = copy.FeedbackStages[stage];
      stopFrame();
      if (session.pausedAt !== null || document.hidden) stop();
      else sound.setRhythm(levels[stage].bpm, active() && byId('sound-setting').checked && byId('rhythm-setting').checked);
      drawTime();
    }
    function handle(result, userGesture) {
      const effect = run.consume(result, session.snapshot());
      if (effect.kind === 'idle') return;
      sync();
      let tone = 'break';
      let message = effect.broken ? copy.FeedbackBreak.replace('%d', String(effect.broken)) : copy.FeedbackTryAgain;
      if (effect.kind === 'correct') {
        tone = effect.record ? 'record' : effect.milestone ? 'milestone' : 'hit';
        message = effect.record ? copy.FeedbackRecord : copy.FeedbackCombo.replace('%d', String(effect.combo));
        animate(byId('streak-count'), 'feedback-hit', 250);
        animate(surface, 'feedback-hit', 280);
        if (effect.record || effect.milestone) {
          byId('feedback-stamp').textContent = effect.record ? copy.FeedbackRecord : copy.FeedbackStages[effect.stage];
          animate(byId('feedback-stamp'), 'feedback-show', 650);
        }
        if (userGesture && byId('haptic-setting').checked) haptics.pulse(effect.strength, true);
      } else if (effect.kind === 'correction' || effect.kind === 'retry') {
        tone = 'correction';
        message = copy.FeedbackCorrection;
      } else animate(surface, 'feedback-break', 300);
      byId('feedback-message').textContent = message;
      if (byId('sound-setting').checked) sound.play(tone, effect.stage, userGesture);
    }
    async function prepare() {
      const capability = await haptics.prepare();
      byId('haptic-setting').disabled = capability.mode !== 'native';
      byId('haptic-option').title = capability.mode === 'native' ? '' : copy.HapticUnavailable;
    }
    ['sound', 'rhythm', 'haptic', 'motion'].forEach(function (name) {
      byId(name + '-setting').addEventListener('change', function () {
        if (!byId('sound-setting').checked || byId('motion-setting').checked) stop();
        if (!byId('haptic-setting').checked) haptics.stop();
        sync();
      });
    });
    prepare(); sync();
    return { handle: handle, sync: sync, stop: stop, prepare: prepare };
  }

  return { levels: levels, stageFor: stageFor, FeedbackRun: FeedbackRun, createFeedback: createFeedback };
}));
