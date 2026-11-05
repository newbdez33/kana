export const QUESTION_MS = 5000;

export function createQuestion(entries, random = Math.random) {
  const pool = [...entries];
  for (let index = pool.length - 1; index > 0; index -= 1) {
    const other = Math.floor(random() * (index + 1));
    [pool[index], pool[other]] = [pool[other], pool[index]];
  }
  const answer = pool[0];
  const promptType = Math.floor(random() * 3);
  const answerType = (promptType + 1 + Math.floor(random() * 2)) % 3;
  const correctIndex = Math.floor(random() * 4);
  const choices = pool.slice(1, 4).map(entry => entry[Math.floor(random() * 3)]);
  choices.splice(correctIndex, 0, answer[answerType]);
  return { prompt: answer[promptType], promptType, choices, correctIndex, kana: answer };
}

export function readStatistics(value) {
  const empty = { count: 0, totalMs: 0, recentMs: [], bestStreak: 0 };
  if (!value || value.version !== 1) return empty;
  const { count, totalMs, recentMs, bestStreak } = value;
  if (!Number.isSafeInteger(count) || count < 0 || !Number.isSafeInteger(bestStreak) || bestStreak < 0 ||
      !Number.isFinite(totalMs) || totalMs < 0 || totalMs > count * QUESTION_MS ||
      !Array.isArray(recentMs) || recentMs.length > Math.min(count, 10) ||
      recentMs.some(ms => !Number.isFinite(ms) || ms <= 0 || ms >= QUESTION_MS)) return empty;
  return { count, totalMs, recentMs: [...recentMs], bestStreak };
}

export class Game {
  constructor(entries, statistics, random = Math.random) {
    if (entries.length < 4) throw new Error('At least four kana are required.');
    this.entries = entries;
    this.random = random;
    this.statistics = readStatistics(statistics);
    this.phase = 'ready';
    this.question = null;
    this.streak = 0;
    this.elapsedMs = 0;
    this.startedAt = null;
    this.pauses = new Set();
    this.result = null;
  }

  start(now) {
    this.question = createQuestion(this.entries, this.random);
    this.phase = 'playing';
    this.result = null;
    this.elapsedMs = 0;
    this.startedAt = this.pauses.size ? null : now;
  }

  elapsed(now) {
    return this.elapsedMs + (this.startedAt === null ? 0 : Math.max(0, now - this.startedAt));
  }

  remaining(now) {
    return Math.max(0, QUESTION_MS - this.elapsed(now));
  }

  pause(reason, now) {
    if (this.phase === 'playing' && this.pauses.size === 0) {
      this.tick(now);
      if (this.phase === 'playing') {
        this.elapsedMs = this.elapsed(now);
        this.startedAt = null;
      }
    }
    this.pauses.add(reason);
  }

  resume(reason, now) {
    if (!this.pauses.delete(reason)) return;
    if (this.phase === 'playing' && this.pauses.size === 0) this.startedAt = now;
  }

  tick(now) {
    if (this.phase === 'playing' && this.pauses.size === 0 && this.elapsed(now) >= QUESTION_MS) {
      return this.finish('timeout', now);
    }
    return null;
  }

  answer(index, now) {
    if (this.phase !== 'playing' || this.pauses.size || !Number.isInteger(index) || index < 0 || index > 3) return null;
    if (this.tick(now)) return this.result;
    return this.finish(index === this.question.correctIndex ? 'correct' : 'incorrect', now, index);
  }

  finish(kind, now, selectedIndex = null) {
    const elapsed = Math.min(QUESTION_MS, this.elapsed(now));
    this.elapsedMs = elapsed;
    this.startedAt = null;
    this.phase = 'feedback';
    this.streak = kind === 'correct' ? this.streak + 1 : 0;
    this.statistics.bestStreak = Math.max(this.statistics.bestStreak, this.streak);
    // Keep the native app's statistics rule: timeouts do not count as answers.
    if (kind !== 'timeout' && elapsed > 0) {
      this.statistics.count += 1;
      this.statistics.totalMs += elapsed;
      this.statistics.recentMs = [...this.statistics.recentMs, elapsed].slice(-10);
    }
    this.result = { kind, selectedIndex, correctIndex: this.question.correctIndex };
    return this.result;
  }

  savedStatistics() {
    return { version: 1, ...this.statistics, recentMs: [...this.statistics.recentMs] };
  }
}
