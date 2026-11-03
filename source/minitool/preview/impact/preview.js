(function () {
  'use strict';
  const byId = function (id) { return document.getElementById(id); };
  const model = window.KanaImpact;
  const pool = [].concat.apply([], window.KanaData.rows).filter(function (kana) { return kana[0]; });
  const answers = Array.prototype.slice.call(document.querySelectorAll('[data-answer]'));
  const stageButtons = Array.prototype.slice.call(document.querySelectorAll('.stages button'));
  const hapticButtons = Array.prototype.slice.call(document.querySelectorAll('[data-haptic]'));
  const arena = byId('arena');
  const haptics = window.KanaHaptics.createHaptics(window, window.KanaBrowserHaptics);
  const platform = window.KanaPlatform.createPlatform(window);
  const sound = window.KanaAudio.createSoundPlayer(window, function () { animate(arena, 'beat', 260); });
  let game = null;
  let mode = 'demo';
  let demoCombo = 0;
  let demoDeadline = null;
  let paused = true;
  let silentTest = false;
  let frame = null;
  let hapticMode = 'loading';
  let pureTestPending = false;
  let statusRevision = 0;
  const animations = [];

  function animate(element, name, duration) {
    element.classList.remove(name);
    if (!byId('reduce-motion').checked || name === 'show') {
      void element.offsetWidth;
      element.classList.add(name);
    }
    const previous = animations.filter(function (item) { return item.element === element && item.name === name; })[0];
    if (previous) { clearTimeout(previous.timer); animations.splice(animations.indexOf(previous), 1); }
    const item = { element: element, name: name, timer: null };
    item.timer = setTimeout(function () {
      element.classList.remove(name);
      const index = animations.indexOf(item);
      if (index !== -1) animations.splice(index, 1);
    }, duration);
    animations.push(item);
  }

  function combo() { return mode === 'demo' ? demoCombo : game.combo; }
  function stage() { return model.stageFor(combo()); }
  function message(value) { byId('feedback').textContent = value; }
  function stopFrame() { if (frame !== null) cancelAnimationFrame(frame); frame = null; }

  function syncRhythm() {
    const active = !document.hidden && !silentTest && (mode === 'demo' || !paused);
    sound.setRhythm(model.levels[stage()].bpm, active && byId('sound-enabled').checked && byId('rhythm-enabled').checked);
  }

  function renderLevel() {
    const level = model.levels[stage()];
    arena.setAttribute('data-stage', String(stage()));
    byId('combo').textContent = String(combo());
    byId('stage-name').textContent = level.name;
    byId('tempo').textContent = level.bpm ? level.bpm + ' BPM' : '无节拍';
    byId('stage-description').textContent = level.note;
    byId('strength-description').textContent = stage() < 2 ? '普通命中轻振；升阶中振。' :
      stage() < 3 ? '普通命中中振；升阶中振。' : '普通命中中振；升阶与破纪录重振。';
    stageButtons.forEach(function (button, index) { button.setAttribute('aria-pressed', String(index === stage())); });
    byId('best').textContent = mode === 'demo' ? '—' : String(game.best);
    syncRhythm();
  }

  function renderQuestion() {
    if (mode !== 'practice') { byId('question').textContent = 'あ'; return; }
    byId('question').textContent = game.question.prompt;
    answers.forEach(function (button, index) {
      button.textContent = game.question.answers[index].label;
      const correct = game.phase === 'revealed' && index === game.question.correctIndex;
      button.classList.toggle('correct', correct);
      button.setAttribute('aria-label', correct ? '正确答案：' + button.textContent : button.textContent);
      button.disabled = paused;
    });
    byId('practice-toggle').textContent = paused ? '开始 / 继续练习' : '暂停练习';
  }

  function renderTime(remaining) {
    byId('timer-fill').style.transform = 'scaleX(' + Math.max(0, Math.min(1, remaining / 5000)) + ')';
    byId('time-left').textContent = (remaining / 1000).toFixed(1) + 's';
    arena.classList.toggle('urgent', remaining > 0 && remaining < 2000 && stage() >= 2 &&
      (mode === 'demo' ? demoDeadline !== null : !paused && game.phase === 'answering'));
  }

  function schedule() {
    stopFrame();
    if (document.hidden) return;
    if (mode === 'demo') {
      if (demoDeadline === null) { renderTime(5000); return; }
      const left = Math.max(0, demoDeadline - performance.now());
      renderTime(left);
      if (!left) {
        demoDeadline = null;
        const broken = demoCombo;
        demoCombo = 0;
        byId('timer-label').textContent = '时间到，点击命中继续';
        feedback({ kind: 'timeout', broken: broken }, false);
        renderTime(0);
        return;
      }
    } else {
      renderTime(game.remaining());
      if (paused || game.phase !== 'answering') return;
      const result = game.tick();
      if (result.kind !== 'idle') { handlePractice(result, false); return; }
    }
    frame = requestAnimationFrame(schedule);
  }

  function beginInteraction() {
    statusRevision += 1;
    silentTest = false;
    if (mode === 'demo') arena.classList.remove('testing');
  }

  async function pulse(type, pure) {
    const revision = ++statusRevision;
    const result = await haptics.pulse(type, true);
    if (revision !== statusRevision) return;
    const label = { light: '轻', medium: '中', heavy: '重' }[type];
    if (result.status === 'requested') {
      byId('haptic-result').textContent = label + '档请求已发送。' +
        (pure ? '本次没有音效，请直接感受设备。' : '实际触感以设备为准。');
    } else if (result.status === 'failed') {
      byId('haptic-result').textContent = '这次震动调用失败。可检查系统触感设置，或稍后重试。';
    } else if (result.status === 'unsupported' && pure) {
      byId('haptic-result').textContent = '当前环境不支持分级震动，请用小红书 App 扫码预览。';
    } else if (result.status === 'skipped' && pure) {
      byId('haptic-result').textContent = '点击间隔太短，请稍等一下再试。';
    }
  }

  function feedback(result, userGesture) {
    renderLevel();
    const success = result.kind === 'correct';
    if (success) {
      const kind = result.record ? 'record' : result.milestone ? 'milestone' : 'hit';
      animate(byId('combo'), 'combo-hit', 250);
      animate(arena, 'hit', 280);
      if (result.record || result.milestone) {
        byId('stamp').textContent = result.record ? '新纪录' : model.levels[stage()].name;
        animate(byId('stamp'), 'show', 650);
      }
      message(result.record ? '新的个人最佳，漂亮！' : result.milestone ? combo() + ' 连对 · ' + model.levels[stage()].name : '命中 · ' + combo() + ' 连对');
      if (byId('sound-enabled').checked) sound.play(kind, stage(), userGesture);
      if (userGesture && byId('haptic-enabled').checked) {
        const strength = result.record || (result.milestone && stage() >= 3) ? 'heavy' : result.milestone || stage() >= 2 ? 'medium' : 'light';
        pulse(strength, false);
      }
    } else if (result.kind === 'correction' || result.kind === 'retry') {
      if (byId('sound-enabled').checked) sound.play('correction', stage(), userGesture);
      message(result.kind === 'correction' ? '记住这一题，从下一题重新连对。' : '点亮的选项是正确答案。');
    } else {
      sound.setRhythm(0, false);
      if (byId('sound-enabled').checked) sound.play('break', 0, userGesture);
      animate(arena, 'broken', 300);
      message(result.broken ? '这一轮 ' + result.broken + ' 连对，再来一轮。' : result.kind === 'timeout' ? '时间到，看看正确答案。' : '慢一点，再来一次。');
    }
  }

  function handlePractice(result, userGesture) {
    if (result.kind === 'idle') return;
    feedback(result, userGesture);
    renderQuestion();
    if (game.phase === 'revealed') {
      byId('timer-label').textContent = '点亮正确答案，再继续';
    } else byId('timer-label').textContent = '首次答对才累计连击';
    schedule();
  }

  function switchMode(next) {
    if (game) game.setPaused(true);
    mode = next;
    paused = true;
    demoDeadline = null;
    silentTest = true;
    sound.stop();
    haptics.stop();
    if (!game && mode === 'practice') {
      game = new model.ImpactSession(pool, { now: function () { return performance.now(); } });
      game.setPaused(true);
    }
    byId('demo-actions').hidden = mode !== 'demo';
    byId('practice-area').hidden = mode !== 'practice';
    byId('combo-label').textContent = mode === 'demo' ? '试演连击' : '当前连击';
    byId('arena-footnote').textContent = mode === 'demo' ? '自由试演 · 随时跳档，试演数字不计入成绩' : '本次练习 · 仅首次答对计入连击，补答不计';
    byId('timer-label').textContent = mode === 'demo' ? '随时点击，感受落点' : '准备好后，点开始练习';
    byId('mode-demo').setAttribute('aria-pressed', String(mode === 'demo'));
    byId('mode-practice').setAttribute('aria-pressed', String(mode === 'practice'));
    message(mode === 'demo' ? '点击命中，或直接跳到某个阶段。' : '每题 5 秒。认准，再点。');
    renderLevel(); renderQuestion(); schedule();
  }

  function demoHit(kind) {
    if (mode !== 'demo') return;
    beginInteraction();
    const before = demoCombo;
    if (kind === 'break') demoCombo = 0;
    else if (kind === 'milestone') {
      demoCombo = stage() < 4 ? model.levels[stage() + 1].min : Math.ceil((demoCombo + 1) / 10) * 10;
    } else demoCombo = Math.min(9999, demoCombo + 1);
    if (demoDeadline !== null) demoDeadline = kind === 'break' ? null : performance.now() + 5000;
    if (demoDeadline === null) byId('timer-label').textContent = '随时点击，感受落点';
    feedback({
      kind: kind === 'break' ? 'incorrect' : 'correct', broken: before,
      record: kind === 'record', milestone: kind === 'milestone' || demoCombo === 5 || (demoCombo > 0 && demoCombo % 10 === 0)
    }, true);
    schedule();
  }

  async function prepareHaptics() {
    const result = await haptics.prepare();
    hapticMode = result.mode;
    const available = hapticMode === 'native' || hapticMode === 'browser';
    hapticButtons.forEach(function (button) { button.disabled = !available; });
    byId('haptic-provider').textContent = hapticMode === 'native' ? '已连接小红书原生震动 · 轻 / 中 / 重三档' :
      hapticMode === 'browser' ? '浏览器通过时长模拟三档；设备也可能没有震动硬件。' :
      result.reason === 'client' ? '当前小红书环境未提供震动能力，请使用 9.50 或更新版本。' :
      '当前浏览器不支持分级震动。请用小红书 App 扫码体验。';
    byId('haptic-enabled').disabled = !available;
  }

  function pauseAll() {
    statusRevision += 1;
    if (game) game.setPaused(true);
    paused = true;
    demoDeadline = null;
    silentTest = true;
    sound.stop(); haptics.stop(); stopFrame();
    animations.splice(0).forEach(function (item) { clearTimeout(item.timer); item.element.classList.remove(item.name); });
    arena.classList.remove('urgent');
    if (mode === 'practice') renderQuestion();
    else { renderTime(5000); byId('timer-label').textContent = '已暂停，点击命中继续'; }
  }

  byId('mode-demo').addEventListener('click', function () { switchMode('demo'); });
  byId('mode-practice').addEventListener('click', function () { switchMode('practice'); });
  stageButtons.forEach(function (button, index) {
    button.addEventListener('click', function () {
      if (mode !== 'demo') switchMode('demo');
      beginInteraction(); demoDeadline = null; demoCombo = model.levels[index].min;
      byId('timer-label').textContent = '随时点击，感受落点';
      renderLevel(); renderTime(5000);
      message('已切到' + model.levels[index].name + '，点「命中一次」试手感。');
      if (byId('sound-enabled').checked) sound.play('correction', index, true);
      schedule();
    });
  });
  byId('demo-hit').addEventListener('click', function () { demoHit('hit'); });
  byId('demo-up').addEventListener('click', function () { demoHit('milestone'); });
  byId('demo-record').addEventListener('click', function () { demoHit('record'); });
  byId('demo-break').addEventListener('click', function () { demoHit('break'); });
  byId('demo-time').addEventListener('click', function () {
    beginInteraction(); demoDeadline = performance.now() + 5000;
    byId('timer-label').textContent = '倒计时中，命中可补满 5 秒';
    message('最后两秒，感受紧张变化。');
    syncRhythm();
    if (byId('sound-enabled').checked) sound.play('correction', stage(), true);
    schedule();
  });
  byId('practice-toggle').addEventListener('click', function () {
    if (mode !== 'practice') return;
    beginInteraction();
    paused = !paused;
    game.setPaused(paused);
    if (paused) sound.stop();
    else if (byId('sound-enabled').checked) sound.play('correction', stage(), true);
    byId('timer-label').textContent = paused ? '已暂停，继续时保留剩余时间' : '首次答对才累计连击';
    message(paused ? '放松一下，随时继续。' : '认准，再点。');
    renderQuestion(); syncRhythm(); schedule();
  });
  answers.forEach(function (button, index) {
    button.addEventListener('click', function () {
      if (mode !== 'practice' || paused) return;
      beginInteraction(); handlePractice(game.answer(index), true);
    });
  });
  hapticButtons.forEach(function (button) {
    button.addEventListener('click', async function () {
      if (pureTestPending) return;
      pureTestPending = true;
      pauseAll();
      byId('haptic-result').textContent = '只发出震动请求，声画已暂停…';
      try { await pulse(button.getAttribute('data-haptic'), true); }
      finally { pureTestPending = false; }
    });
  });
  ['sound-enabled', 'rhythm-enabled'].forEach(function (id) {
    byId(id).addEventListener('change', function () {
      if (!byId('sound-enabled').checked) sound.stop();
      else { silentTest = false; sound.play('correction', stage(), true); }
      syncRhythm();
    });
  });
  byId('haptic-enabled').addEventListener('change', function () { if (!this.checked) haptics.stop(); });
  const reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)');
  byId('reduce-motion').checked = !!reduce && reduce.matches;
  function syncMotion() { document.body.classList.toggle('reduced', byId('reduce-motion').checked); }
  byId('reduce-motion').addEventListener('change', syncMotion);
  syncMotion();
  document.addEventListener('visibilitychange', function () {
    if (document.hidden) pauseAll();
    else prepareHaptics();
  });
  window.addEventListener('pagehide', pauseAll);
  document.addEventListener('keydown', function (event) {
    if (event.code === 'Space' && mode === 'demo' && !event.repeat &&
        !/INPUT|BUTTON|SELECT/.test(event.target.tagName)) {
      event.preventDefault(); demoHit('hit');
    }
  });
  platform.windowInsets().then(function (insets) {
    if (!insets) return;
    document.documentElement.style.setProperty('--safe-top', insets.top + 'px');
    document.documentElement.style.setProperty('--safe-bottom', insets.bottom + 'px');
  });
  prepareHaptics(); renderLevel(); renderTime(5000);
}());
