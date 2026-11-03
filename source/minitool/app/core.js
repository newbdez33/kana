(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.KanaCore = factory();
}(typeof window === 'object' ? window : this, function () {
  'use strict';

  const TIME_LIMIT = 5000;

  function emptyStats() {
    return { version: 1, totalCount: 0, totalCost: 0, recentCosts: [], currentStreak: 0, bestStreak: 0 };
  }

  function isCount(value) {
    return Number.isSafeInteger(value) && value >= 0;
  }

  function isValidStats(value) {
    if (!value || value.version !== 1 || !isCount(value.totalCount) ||
        !isCount(value.currentStreak) || !isCount(value.bestStreak) ||
        value.currentStreak > value.bestStreak || !Number.isFinite(value.totalCost) ||
        value.totalCost < 0 || value.totalCost > value.totalCount * 5 ||
        !Array.isArray(value.recentCosts) || value.recentCosts.length !== Math.min(value.totalCount, 10)) {
      return false;
    }
    return value.recentCosts.every(function (cost) {
      return Number.isFinite(cost) && cost > 0 && cost <= 5;
    }) && (value.totalCount === 0 ? value.totalCost === 0 : value.totalCost > 0);
  }

  function copyStats(value) {
    return {
      version: 1,
      totalCount: value.totalCount,
      totalCost: value.totalCost,
      recentCosts: value.recentCosts.slice(),
      currentStreak: value.currentStreak,
      bestStreak: value.bestStreak
    };
  }

  function pick(values, random) {
    return values[Math.floor(random() * values.length)];
  }

  function createQuestion(pool, random) {
    const kana = pick(pool, random);
    const promptForm = Math.floor(random() * 3);
    const correctForm = pick([0, 1, 2].filter(function (form) { return form !== promptForm; }), random);
    const correctIndex = Math.floor(random() * 4);
    const remaining = pool.filter(function (item) { return item[0] !== kana[0]; });
    const answers = [];
    for (let index = 0; index < 4; index++) {
      if (index === correctIndex) {
        answers.push({ kana: kana, label: kana[correctForm] });
      } else {
        const other = remaining.splice(Math.floor(random() * remaining.length), 1)[0];
        answers.push({ kana: other, label: pick(other, random) });
      }
    }
    return { kana: kana, prompt: kana[promptForm], answers: answers, correctIndex: correctIndex };
  }

  class PracticeSession {
    constructor(pool, options) {
      this.pool = pool;
      this.now = options.now;
      this.random = options.random || Math.random;
      this.stats = isValidStats(options.stats) ? copyStats(options.stats) : emptyStats();
      this.phase = 'idle';
      this.pausedAt = null;
      this.question = null;
      this.startedAt = 0;
    }

    start() {
      this.question = createQuestion(this.pool, this.random);
      this.phase = 'answering';
      this.startedAt = this.now();
      if (this.pausedAt !== null) this.pausedAt = this.startedAt;
    }

    elapsed() {
      return Math.max(0, (this.pausedAt === null ? this.now() : this.pausedAt) - this.startedAt);
    }

    remaining() {
      return Math.max(0, TIME_LIMIT - this.elapsed());
    }

    setPaused(paused) {
      if (paused && this.pausedAt === null) this.pausedAt = this.now();
      else if (!paused && this.pausedAt !== null) {
        this.startedAt += this.now() - this.pausedAt;
        this.pausedAt = null;
      }
    }

    tick() {
      if (this.phase === 'answering' && this.pausedAt === null && this.elapsed() >= TIME_LIMIT) {
        this.phase = 'revealed';
        this.stats.currentStreak = 0;
        return { kind: 'timeout' };
      }
      return { kind: 'idle' };
    }

    answer(index) {
      if (!this.question || this.pausedAt !== null || !Number.isInteger(index) || index < 0 || index > 3) {
        return { kind: 'idle' };
      }
      const deadline = this.tick();
      if (deadline.kind === 'timeout') return deadline;
      const firstAttempt = this.phase === 'answering';
      const cost = this.elapsed() / 1000;
      const correct = index === this.question.correctIndex;

      // Match iOS: correction taps use the original question start time.
      if (cost > 0 && cost <= 5) {
        this.stats.totalCount += 1;
        this.stats.totalCost += cost;
        this.stats.recentCosts.push(cost);
        this.stats.recentCosts = this.stats.recentCosts.slice(-10);
      }
      this.stats.currentStreak = correct && firstAttempt ? this.stats.currentStreak + 1 : 0;
      this.stats.bestStreak = Math.max(this.stats.bestStreak, this.stats.currentStreak);
      if (correct) this.start();
      else this.phase = 'revealed';
      return { kind: correct ? 'correct' : 'incorrect', firstAttempt: firstAttempt };
    }

    snapshot() {
      return copyStats(this.stats);
    }
  }

  return { createQuestion: createQuestion, PracticeSession: PracticeSession, emptyStats: emptyStats, isValidStats: isValidStats };
}));
