import { Game, QUESTION_MS } from './engine.mjs';
import { entries, rows } from './kana-data.mjs';

const byId = id => document.getElementById(id);

function updateHostInsets() {
  const host = globalThis.tap;
  if (!host) return;
  try {
    const system = host.getSystemInfoSync?.();
    const menu = host.getMenuButtonBoundingClientRect?.();
    const top = Math.max(0, system?.safeArea?.top ?? 0, menu?.bottom ?? 0);
    const height = system?.windowHeight ?? innerHeight;
    const bottom = Math.max(0, height - (system?.safeArea?.bottom ?? height));
    const style = document.documentElement.style;
    style.setProperty('--host-safe-top', `${top ? top + 8 : 0}px`);
    style.setProperty('--host-safe-bottom', `${bottom}px`);
  } catch {
    // A host geometry failure must not prevent practice from starting.
  }
}

updateHostInsets();
window.addEventListener('resize', updateHostInsets);

const storageKey = 'kana.h5.statistics.v1';
let saved;
try { saved = JSON.parse(localStorage.getItem(storageKey)); } catch { /* Practice also works without storage. */ }
const game = new Game(entries, saved);
const answerButtons = [...byId('answers').querySelectorAll('button')];
const answerKeys = answerButtons.map(button => button.querySelector('.answer-key').textContent.toLowerCase());
const chart = byId('chart');
let automaticNext = null;
let chartType = 1;
let lastProgressSecond = null;
let lastTimerText = null;

function save() {
  try { localStorage.setItem(storageKey, JSON.stringify(game.savedStatistics())); }
  catch { byId('storage-note').textContent = '浏览器未允许保存，记录仅在本次练习中保留。'; }
}

function renderStatistics() {
  const stats = game.statistics;
  byId('best-streak').textContent = stats.bestStreak;
  byId('streak').textContent = game.streak;
  byId('answer-count').textContent = stats.count;
  byId('average-time').textContent = stats.count ? `${(stats.totalMs / stats.count / 1000).toFixed(2)} 秒` : '—';
  byId('recent-time').textContent = stats.recentMs.length ? `${(stats.recentMs.reduce((a, b) => a + b, 0) / stats.recentMs.length / 1000).toFixed(2)} 秒` : '—';
}

function renderTime(now) {
  const remaining = game.remaining(now);
  const timerText = (remaining / 1000).toFixed(1);
  if (timerText !== lastTimerText) {
    byId('timer-value').textContent = timerText;
    lastTimerText = timerText;
  }
  byId('timer').classList.toggle('urgent', remaining <= 1000 && game.phase === 'playing');
  byId('time-fill').style.transform = `scaleX(${remaining / QUESTION_MS})`;
  const second = Math.ceil(remaining / 1000);
  if (second !== lastProgressSecond) {
    byId('time-progress').setAttribute('aria-valuenow', second);
    lastProgressSecond = second;
  }
}

function renderQuestion() {
  byId('prompt').textContent = game.question.prompt;
  byId('prompt-type').textContent = ['罗马音', '平假名', '片假名'][game.question.promptType];
  answerButtons.forEach((button, index) => {
    button.className = 'answer';
    button.disabled = game.pauses.size > 0;
    button.querySelector('.answer-label').textContent = game.question.choices[index];
    button.querySelector('.answer-mark').textContent = '';
    button.setAttribute('aria-label', `${answerKeys[index].toUpperCase()}：${game.question.choices[index]}`);
  });
  byId('feedback').className = '';
  byId('feedback').textContent = '选出对应的假名或罗马音。';
  byId('next').hidden = true;
  renderTime(performance.now());
}

function startQuestion() {
  clearTimeout(automaticNext);
  automaticNext = null;
  game.start(performance.now());
  renderQuestion();
}

function renderResult() {
  if (!game.result) return;
  const { kind, selectedIndex, correctIndex } = game.result;
  const hadAnswerFocus = answerButtons.includes(document.activeElement);
  answerButtons.forEach((button, index) => {
    button.className = `answer ${index === correctIndex ? 'correct' : index === selectedIndex ? 'incorrect' : 'muted'}`;
    button.querySelector('.answer-mark').textContent = index === correctIndex ? '✓' : index === selectedIndex ? '×' : '';
    button.disabled = index !== correctIndex || game.pauses.size > 0;
    button.setAttribute('aria-label', index === correctIndex ? `${game.question.choices[index]}，正确答案。继续下一题` : game.question.choices[index]);
  });
  if (hadAnswerFocus && !game.pauses.size) answerButtons[correctIndex].focus({ preventScroll: true });
  const feedback = byId('feedback');
  feedback.className = kind === 'correct' ? 'success' : 'error';
  feedback.textContent = kind === 'correct' ? `答对了，已经连对 ${game.streak} 题！` : `${kind === 'timeout' ? '时间到' : '再记住一次'}：${game.question.kana.join(' · ')}。点击正确答案继续。`;
  byId('next').hidden = kind === 'correct';
  byId('next').disabled = game.pauses.size > 0;
  renderStatistics();
  renderTime(performance.now());
}

function finishQuestion() {
  save();
  renderResult();
  if (game.result.kind === 'correct') {
    automaticNext = setTimeout(() => {
      automaticNext = null;
      if (game.phase === 'feedback' && game.pauses.size === 0) startQuestion();
    }, 500);
  }
}

function choose(index) {
  if (game.pauses.size) return;
  if (game.phase === 'feedback') {
    if (index === game.question.correctIndex) startQuestion();
    return;
  }
  if (game.answer(index, performance.now())) finishQuestion();
}

function pause(reason) {
  const phase = game.phase;
  game.pause(reason, performance.now());
  if (phase === 'playing' && game.phase === 'feedback') finishQuestion();
  syncPause();
}

function resume(reason) {
  game.resume(reason, performance.now());
  if (!game.pauses.size && game.phase === 'feedback' && game.result.kind === 'correct' && automaticNext === null) startQuestion();
  syncPause();
}

function syncPause() {
  const manual = game.pauses.has('manual');
  byId('pause-panel').hidden = !manual;
  byId('pause').textContent = manual ? '继续' : '暂停';
  if (game.phase === 'playing') answerButtons.forEach(button => { button.disabled = game.pauses.size > 0; });
  else if (game.phase === 'feedback') renderResult();
}

function renderChart() {
  byId('chart-grid').replaceChildren(...rows.flatMap(row => {
    const cells = [...row];
    while (cells.length < 5) cells.push(['', '', '']);
    return cells.map(entry => {
      const cell = document.createElement('div');
      cell.className = 'chart-cell';
      if (!entry[0]) { cell.setAttribute('aria-hidden', 'true'); return cell; }
      const glyph = document.createElement('span');
      glyph.className = 'kana';
      glyph.lang = 'ja';
      glyph.textContent = entry[chartType];
      const romaji = document.createElement('small');
      romaji.textContent = entry[0];
      cell.append(glyph, romaji);
      return cell;
    });
  }));
  byId('hiragana').setAttribute('aria-pressed', chartType === 1);
  byId('katakana').setAttribute('aria-pressed', chartType === 2);
}

answerButtons.forEach((button, index) => {
  button.setAttribute('aria-keyshortcuts', answerKeys[index].toUpperCase());
  button.addEventListener('click', () => choose(index));
});
byId('start').addEventListener('click', () => {
  byId('start-panel').hidden = true;
  byId('question-panel').removeAttribute('aria-hidden');
  byId('answers-panel').removeAttribute('aria-hidden');
  byId('pause').disabled = false;
  startQuestion();
});
byId('pause').addEventListener('click', () => game.pauses.has('manual') ? resume('manual') : pause('manual'));
byId('resume').addEventListener('click', () => resume('manual'));
byId('next').addEventListener('click', () => { if (game.phase === 'feedback' && !game.pauses.size) startQuestion(); });
byId('chart-open').addEventListener('click', () => { pause('chart'); renderChart(); chart.showModal(); });
byId('chart-close').addEventListener('click', () => chart.close());
chart.addEventListener('close', () => resume('chart'));
byId('hiragana').addEventListener('click', () => { chartType = 1; renderChart(); });
byId('katakana').addEventListener('click', () => { chartType = 2; renderChart(); });
document.addEventListener('visibilitychange', () => document.hidden ? pause('visibility') : resume('visibility'));
document.addEventListener('keydown', event => {
  if (event.altKey || event.ctrlKey || event.metaKey || event.isComposing || chart.open ||
      event.target.closest('input, textarea, select, [contenteditable]')) return;
  if (event.key === 'Escape' && game.phase !== 'ready') {
    event.preventDefault();
    if (!event.repeat) game.pauses.has('manual') ? resume('manual') : pause('manual');
    return;
  }
  if (game.phase === 'ready' || game.pauses.size) return;

  const shortcutIndex = answerKeys.indexOf(event.key.toLowerCase());
  const focusedIndex = answerButtons.indexOf(document.activeElement);
  const isArrow = ['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(event.key);
  const isConfirm = focusedIndex !== -1 && (event.key === 'Enter' || event.key === ' ');
  if (shortcutIndex === -1 && !isArrow && !isConfirm) return;

  // Suppress native button activation and key repeats across question changes.
  event.preventDefault();
  if (event.repeat) return;
  if (shortcutIndex !== -1) {
    if (!answerButtons[shortcutIndex].disabled) {
      answerButtons[shortcutIndex].focus({ preventScroll: true });
      choose(shortcutIndex);
    }
    return;
  }
  if (isConfirm) {
    choose(focusedIndex);
    return;
  }

  let nextIndex = focusedIndex;
  if (focusedIndex === -1 || answerButtons[focusedIndex].disabled) {
    nextIndex = answerButtons.findIndex(button => !button.disabled);
  } else {
    const row = Math.floor(focusedIndex / 2);
    const column = focusedIndex % 2;
    if (event.key === 'ArrowUp') nextIndex = Math.max(0, row - 1) * 2 + column;
    if (event.key === 'ArrowDown') nextIndex = Math.min(1, row + 1) * 2 + column;
    if (event.key === 'ArrowLeft') nextIndex = row * 2 + Math.max(0, column - 1);
    if (event.key === 'ArrowRight') nextIndex = row * 2 + Math.min(1, column + 1);
  }
  if (nextIndex !== -1 && !answerButtons[nextIndex].disabled) answerButtons[nextIndex].focus({ preventScroll: true });
});
if (document.hidden) pause('visibility');
renderStatistics();
requestAnimationFrame(function frame(now) {
  if (game.tick(now)) finishQuestion();
  if (game.phase === 'playing' && game.pauses.size === 0) renderTime(now);
  requestAnimationFrame(frame);
});
