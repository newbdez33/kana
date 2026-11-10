import { Game, QUESTION_MS } from './engine.mjs';
import { entries, rows } from './kana-data.mjs';
import { PracticeBanner } from './ads.mjs';
import { bannerAdUnitId } from './ad-config.mjs';
import { Journey, STEPS_PER_MEADOW } from './journey.mjs';

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
const journeyKey = 'jumping-kana.journey.v1';
function readSaved(key) {
  try { return JSON.parse(localStorage.getItem(key)); } catch { return null; }
}
const game = new Game(entries, readSaved(storageKey));
const journey = new Journey(readSaved(journeyKey));
const answerButtons = [...byId('answers').querySelectorAll('button')];
const answerKeys = answerButtons.map(button => button.querySelector('.answer-key').textContent.toLowerCase());
const chart = byId('chart');
const phoneLayout = matchMedia('(max-width:700px), (pointer:coarse)');
const reducedMotion = matchMedia('(prefers-reduced-motion:reduce)');
let feedbackTimeout = null;
let rabbitAnimation = null;
let chartType = 1;
let lastProgressSecond = null;
let lastTimerText = null;
const banner = new PracticeBanner({
  host: globalThis.tap,
  adUnitId: bannerAdUnitId,
  placement: bannerPlacement,
  render(position) {
    const slot = byId('banner-slot');
    slot.hidden = !position;
    slot.style.height = position ? `${position.height + 52}px` : '';
  }
});
banner.setActive(!document.hidden);

function bannerPlacement(size) {
  if (game.phase !== 'feedback' || game.pauses.size || chart.open || document.hidden) return null;
  const panel = byId('question-panel').getBoundingClientRect();
  const available = Math.min(panel.width, innerWidth) - 16;
  const width = size.width || available;
  const height = size.height;
  const questionTop = byId('question-content').getBoundingClientRect().top;
  if (width < 300 || width > available || height > innerHeight * 0.1 ||
      panel.bottom - height - 52 - questionTop < 185) return null;
  return { left: panel.left + (panel.width - width) / 2, top: panel.bottom - height - 12, width, height };
}

window.addEventListener('resize', () => banner.reposition());
window.addEventListener('pagehide', () => banner.setActive(false));
window.addEventListener('pageshow', () => banner.setActive(!document.hidden));
byId('banner-close').addEventListener('click', () => banner.hide());

function save() {
  try {
    localStorage.setItem(storageKey, JSON.stringify(game.savedStatistics()));
    localStorage.setItem(journeyKey, JSON.stringify(journey.savedProgress()));
  }
  catch { byId('storage-note').textContent = '浏览器未允许保存，记录仅在本次练习中保留。'; }
}

const stones = Array.from({ length: STEPS_PER_MEADOW }, () => {
  const stone = document.createElement('span');
  stone.className = 'trail-stone';
  return stone;
});
byId('trail-stones').append(...stones);

function renderJourney(newMeadow = false) {
  const { meadow, step, remaining } = journey.view;
  byId('scene').dataset.meadow = meadow.id;
  byId('meadow-name').textContent = meadow.name;
  byId('journey-count').textContent = `再跳 ${remaining} 步，到下一片花田`;
  byId('trail-note').textContent = `已经跳过 ${journey.hops} 步 · ${meadow.note}`;
  byId('rabbit-position').classList.toggle('new-meadow', newMeadow);
  byId('rabbit-position').style.setProperty('--rabbit-x', `${11 + step * 78 / (STEPS_PER_MEADOW - 1)}%`);
  stones.forEach((stone, index) => stone.classList.toggle('visited', index <= step));
}

function animateRabbit(kind, newMeadow = false) {
  rabbitAnimation?.cancel();
  if (reducedMotion.matches || typeof byId('rabbit').animate !== 'function') return;
  const keyframes = kind === 'correct'
    ? [{ transform: 'translateY(0) scale(1.06,.94)', opacity: newMeadow ? 0 : 1 },
      { transform: 'translateY(-35%) rotate(-7deg) scale(.95,1.05)', offset: .48, opacity: 1 },
      { transform: 'translateY(0) scale(1.06,.94)', offset: .86 },
      { transform: 'translateY(0) scale(1)' }]
    : [{ transform: 'rotate(0)' }, { transform: 'rotate(-6deg)' }, { transform: 'rotate(3deg)' }, { transform: 'rotate(0)' }];
  rabbitAnimation = byId('rabbit').animate(keyframes, { duration: kind === 'correct' ? 420 : 330, easing: 'ease-in-out' });
}

function renderStatistics() {
  const stats = game.statistics;
  byId('best-streak').textContent = stats.bestStreak;
  byId('streak').textContent = game.streak;
  byId('answer-count').textContent = stats.count;
  renderAverage('average-time', stats.count ? stats.totalMs / stats.count : null);
  renderAverage('recent-time', stats.recentMs.length ? stats.recentMs.reduce((a, b) => a + b, 0) / stats.recentMs.length : null);
}

function renderAverage(id, milliseconds) {
  const value = byId(id);
  value.textContent = milliseconds === null ? '—' : (milliseconds / 1000).toFixed(2);
  if (milliseconds === null) return;
  const unit = document.createElement('span');
  unit.className = 'stat-unit';
  unit.textContent = '秒';
  value.append(unit);
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
    button.setAttribute('aria-label', game.question.choices[index]);
  });
  byId('feedback').className = '';
  byId('feedback').textContent = '选出对应的假名或罗马音，帮跳跳向前跳。';
  byId('next').hidden = true;
  renderTime(performance.now());
}

function startQuestion() {
  banner.hide();
  clearTimeout(feedbackTimeout);
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
  feedback.textContent = kind === 'correct' ? `答对了，跳跳又前进了一步！` : `${kind === 'timeout' ? '休息一下，记住' : '这次记住了'}：${game.question.kana.join(' · ')}。点绿色答案继续。`;
  byId('next').hidden = kind === 'correct';
  byId('next').disabled = game.pauses.size > 0;
  renderStatistics();
  renderTime(performance.now());
}

function finishQuestion() {
  clearTimeout(feedbackTimeout);
  const { kind } = game.result;
  const newMeadow = journey.record(kind);
  save();
  renderJourney(newMeadow);
  animateRabbit(kind, newMeadow);
  if (kind === 'correct') {
    renderStatistics();
    startQuestion();
    byId('feedback').className = 'success';
    byId('feedback').textContent = newMeadow ? `到达${journey.view.meadow.name}！带着记住的假名继续走。` : `轻轻一跳，连对 ${game.streak} 题！`;
    feedbackTimeout = setTimeout(() => { byId('feedback').textContent = '选出对应的假名或罗马音，帮跳跳向前跳。'; }, 1100);
  } else {
    renderResult();
    if (game.pauses.size === 0) banner.show();
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
  banner.hide();
  const phase = game.phase;
  game.pause(reason, performance.now());
  if (phase === 'playing' && game.phase === 'feedback') finishQuestion();
  syncPause();
}

function resume(reason) {
  game.resume(reason, performance.now());
  syncPause();
}

function setMenuOpen(open) {
  byId('practice-menu').hidden = !open;
  byId('menu-toggle').setAttribute('aria-expanded', open);
  byId('menu-toggle').setAttribute('aria-label', open ? '关闭菜单' : '菜单');
  if (open) pause('menu');
  else resume('menu');
}

function syncPause() {
  const manual = game.pauses.has('manual');
  byId('scene').dataset.paused = game.pauses.size > 0;
  if (game.pauses.size) rabbitAnimation?.pause();
  else if (rabbitAnimation?.playState === 'paused') rabbitAnimation.play();
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
function startPractice() {
  byId('start-panel').hidden = true;
  byId('question-content').removeAttribute('aria-hidden');
  byId('answers-panel').removeAttribute('aria-hidden');
  byId('pause').disabled = false;
  startQuestion();
}
byId('start').addEventListener('click', startPractice);
byId('menu-toggle').addEventListener('click', () => setMenuOpen(byId('practice-menu').hidden));
byId('pause').addEventListener('click', () => {
  if (game.pauses.has('manual')) resume('manual');
  else pause('manual');
  setMenuOpen(false);
});
byId('resume').addEventListener('click', () => resume('manual'));
byId('next').addEventListener('click', () => { if (game.phase === 'feedback' && !game.pauses.size) startQuestion(); });
byId('chart-open').addEventListener('click', () => { pause('chart'); setMenuOpen(false); renderChart(); chart.showModal(); });
byId('chart-close').addEventListener('click', () => chart.close());
chart.addEventListener('close', () => resume('chart'));
byId('hiragana').addEventListener('click', () => { chartType = 1; renderChart(); });
byId('katakana').addEventListener('click', () => { chartType = 2; renderChart(); });
document.addEventListener('visibilitychange', () => {
  banner.setActive(!document.hidden);
  document.hidden ? pause('visibility') : resume('visibility');
});
document.addEventListener('keydown', event => {
  if (event.altKey || event.ctrlKey || event.metaKey || event.isComposing || chart.open ||
      event.target.closest('input, textarea, select, [contenteditable]')) return;
  if (event.key === 'Escape' && game.phase !== 'ready') {
    event.preventDefault();
    if (!event.repeat) {
      if (!byId('practice-menu').hidden) setMenuOpen(false);
      else game.pauses.has('manual') ? resume('manual') : pause('manual');
    }
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
renderJourney();
async function startPhonePractice() {
  await document.fonts.ready;
  if (phoneLayout.matches && game.phase === 'ready') startPractice();
}
phoneLayout.addEventListener('change', startPhonePractice);
startPhonePractice();
requestAnimationFrame(function frame(now) {
  if (game.tick(now)) finishQuestion();
  if (game.phase === 'playing' && game.pauses.size === 0) renderTime(now);
  requestAnimationFrame(frame);
});
