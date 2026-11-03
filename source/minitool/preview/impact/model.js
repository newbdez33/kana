(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory(require('../../app/core.js'), require('../../app/feedback.js'));
  else root.KanaImpact = factory(root.KanaCore, root.KanaFeedback);
}(typeof window === 'object' ? window : this, function (core, feedback) {
  'use strict';
  const levels = [
    { name: '起步', note: '轻快落点，找到自己的节奏。' },
    { name: '入拍', note: '音阶上扬，连击开始有分量。' },
    { name: '升温', note: '轻节拍进入，最后两秒开始收紧。' },
    { name: '冲刺', note: '节拍加密，朱红随节奏呼吸。' },
    { name: '高燃', note: '保持最高强度，继续刷新连对。' }
  ];
  levels.forEach(function (level, index) { Object.assign(level, feedback.levels[index]); });
  const stageFor = feedback.stageFor;

  class ImpactSession {
    constructor(pool, options) {
      this.practice = new core.PracticeSession(pool, options);
      this.practice.start();
      this.combo = 0;
      this.best = 0;
      this.attempts = 0;
      this.correct = 0;
      this.recordTarget = 0;
      this.recordShown = false;
    }
    get question() { return this.practice.question; }
    get phase() { return this.practice.phase; }
    remaining() { return this.practice.remaining(); }
    setPaused(value) { this.practice.setPaused(value); }
    answer(index) {
      const first = this.practice.phase === 'answering';
      return this.consume(this.practice.answer(index), first);
    }
    tick() { return this.consume(this.practice.tick(), true); }
    consume(result, first) {
      if (result.kind === 'idle') return result;
      if (!first) return { kind: result.kind === 'correct' ? 'correction' : 'retry', combo: this.combo };
      const previous = this.combo;
      this.attempts += 1;
      let record = false;
      if (result.kind === 'correct') {
        this.combo += 1;
        this.correct += 1;
        record = this.recordTarget >= 5 && this.combo > this.recordTarget && !this.recordShown;
        if (record) this.recordShown = true;
        this.best = Math.max(this.best, this.combo);
      } else {
        this.combo = 0;
        this.recordTarget = this.best;
        this.recordShown = false;
      }
      return {
        kind: result.kind, combo: this.combo, stage: stageFor(this.combo), record: record,
        milestone: this.combo >= 5 && (this.combo === 5 || this.combo % 10 === 0),
        broken: result.kind === 'correct' ? 0 : previous
      };
    }
  }
  return { levels: levels, stageFor: stageFor, ImpactSession: ImpactSession };
}));
