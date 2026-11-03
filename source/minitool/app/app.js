(function () {
  'use strict';

  const data = window.KanaData;
  const core = window.KanaCore;
  const platform = window.KanaPlatform.createPlatform(window);
  const byId = function (id) { return document.getElementById(id); };
  const buttons = Array.prototype.slice.call(document.querySelectorAll('[data-answer]'));
  const pool = [].concat.apply([], data.rows).filter(function (kana) { return kana[0] !== ''; });
  const params = new URLSearchParams(window.location.search);
  const requested = params.get('lang') || navigator.language || 'en';
  const language = selectLanguage(requested);
  const copy = Object.assign({}, data.copy[language], window.KanaExtraCopy[language]);
  let session;
  let menuOpen = false;
  let modal = null;
  let background = document.hidden;
  let chartForm = 1;
  let timer;
  let noticeTimer;
  let canSave = true;
  let storageWarning = false;
  let shareBusy = false;
  let returnFocus = null;
  let shareDataUrl = '';
  let shareResult = null;
  let followState = null;
  let followBusy = false;
  let followRevision = 0;
  let feedback;

  function selectLanguage(value) {
    if (data.copy[value]) return value;
    const normalized = value.toLowerCase();
    if (/^zh-(tw|hk|mo|hant)/.test(normalized)) return 'zh-Hant';
    if (normalized.indexOf('zh') === 0) return 'zh-Hans';
    const base = normalized.split('-')[0];
    return data.copy[base] ? base : 'en';
  }

  function translate() {
    document.documentElement.lang = language;
    document.querySelectorAll('[data-text]').forEach(function (element) {
      element.textContent = copy[element.getAttribute('data-text')].replace('%d', '10');
    });
    byId('menu-toggle').setAttribute('aria-label', copy.Menu);
    byId('more-toggle').setAttribute('aria-label', copy.More);
    byId('chart-close').setAttribute('aria-label', copy.Close);
    byId('share-close').setAttribute('aria-label', copy.Close);
    byId('hiragana').setAttribute('aria-label', copy.Hiragana);
    byId('katakana').setAttribute('aria-label', copy.Katakana);
    byId('answers').setAttribute('aria-label', copy.ChooseAnswer);
    byId('workspace').setAttribute('aria-label', copy.Practice);
    byId('share-image').alt = copy.Practice;
    byId('chart-scroll').querySelector('.chart-switch').setAttribute('aria-label', copy.Chart);
  }

  function showNotice(message) {
    clearTimeout(noticeTimer);
    byId('notice').textContent = message;
    byId('notice').hidden = false;
    noticeTimer = setTimeout(function () { byId('notice').hidden = true; }, 5000);
  }

  function integer(value) { return value.toLocaleString(language); }
  function decimal(value) {
    return value.toLocaleString(language, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  }

  function fitMetric(element) {
    element.style.fontSize = '';
    let size = parseFloat(window.getComputedStyle(element).fontSize);
    while (element.scrollWidth > element.clientWidth && size > 15) {
      size -= 1;
      element.style.fontSize = size + 'px';
    }
  }

  function renderTime(id, value, hasAnswers) {
    const element = byId(id);
    element.textContent = '';
    if (!hasAnswers) { element.textContent = '—'; return; }
    const number = decimal(value);
    const formatted = copy.StatSeconds.replace('%@', number);
    const parts = formatted.split(number);
    if (parts[0]) {
      const prefix = document.createElement('small');
      prefix.textContent = parts[0];
      element.appendChild(prefix);
    }
    element.appendChild(document.createTextNode(number));
    if (parts[1]) {
      const unit = document.createElement('small');
      unit.textContent = parts[1];
      element.appendChild(unit);
    }
  }

  function renderStatistics() {
    const stats = session.snapshot();
    const hasAnswers = stats.totalCount > 0;
    const recent = stats.recentCosts.reduce(function (sum, value) { return sum + value; }, 0);
    byId('total-value').textContent = integer(stats.totalCount);
    byId('best-value').textContent = integer(stats.bestStreak);
    renderTime('average-value', stats.totalCost / stats.totalCount, hasAnswers);
    renderTime('recent-value', recent / stats.recentCosts.length, hasAnswers);
    ['total-value', 'average-value', 'recent-value', 'best-value'].forEach(function (id) { fitMetric(byId(id)); });
  }

  function renderQuestion() {
    const question = session.question;
    byId('question').textContent = question.prompt;
    buttons.forEach(function (button, index) {
      const label = question.answers[index].label;
      const revealed = session.phase === 'revealed' && index === question.correctIndex;
      button.textContent = label;
      button.classList.toggle('correct', revealed);
      button.setAttribute('aria-label', revealed ? copy.CorrectAnswer.replace('%s', label) : label);
      button.disabled = session.pausedAt !== null && !menuOpen;
    });
  }

  function persist() {
    if (!canSave) return;
    platform.save(session.snapshot()).then(function (saved) {
      if (!saved && !storageWarning) showNotice(copy.WriteFailed);
      storageWarning = !saved;
    });
  }

  function handleResult(result, userGesture) {
    if (result.kind === 'idle') return;
    renderStatistics();
    renderQuestion();
    feedback.handle(result, userGesture === true);
    byId('announcement').textContent = result.kind === 'correct' ? '' :
      copy.CorrectAnswer.replace('%s', session.question.answers[session.question.correctIndex].label);
    persist();
    scheduleTimer();
  }

  function scheduleTimer() {
    clearTimeout(timer);
    if (!session || session.phase !== 'answering' || session.pausedAt !== null) return;
    timer = setTimeout(function () {
      const result = session.tick();
      if (result.kind === 'idle') scheduleTimer();
      else handleResult(result);
    }, Math.max(1, session.remaining()));
  }

  function syncPause() {
    if (!session) return;
    session.setPaused(menuOpen || modal !== null || background);
    if (feedback) feedback.sync();
    renderQuestion();
    scheduleTimer();
  }

  function closeMore() {
    byId('more-menu').hidden = true;
    byId('more-toggle').setAttribute('aria-expanded', 'false');
  }

  function setMenu(open) {
    if (!session || modal) return;
    // Resolve a deadline before opening the menu can pause it.
    handleResult(session.tick());
    menuOpen = open;
    byId('menu').hidden = !open;
    byId('menu-toggle').setAttribute('aria-expanded', String(open));
    byId('menu-toggle').setAttribute('aria-label', open ? copy.CloseMenu : copy.Menu);
    byId('menu-icon').setAttribute('d', open ? 'M5 15l7-7 7 7' : 'M3 6h18M3 12h18M3 18h18');
    closeMore();
    syncPause();
    if (open) refreshFollow();
  }

  function openModal(name) {
    if (!session) return;
    returnFocus = document.activeElement;
    closeMore();
    modal = name;
    byId(name + '-modal').hidden = false;
    byId('app').setAttribute('aria-hidden', 'true');
    syncPause();
    byId(name + '-close').focus();
  }

  function closeModal() {
    if (!modal || shareBusy) return;
    byId(modal + '-modal').hidden = true;
    modal = null;
    byId('app').removeAttribute('aria-hidden');
    syncPause();
    if (returnFocus && returnFocus.offsetParent !== null) returnFocus.focus();
    else byId('menu-toggle').focus();
  }

  function renderChart() {
    const chart = byId('kana-chart');
    chart.textContent = '';
    data.rows.forEach(function (row) {
      const rowElement = document.createElement('div');
      rowElement.className = 'kana-row';
      row.forEach(function (kana) {
        const cell = document.createElement('div');
        cell.className = 'kana-cell';
        cell.appendChild(document.createTextNode(kana[chartForm]));
        const romaji = document.createElement('small');
        romaji.textContent = kana[0];
        cell.appendChild(romaji);
        if (!kana[0]) cell.setAttribute('aria-hidden', 'true');
        rowElement.appendChild(cell);
      });
      chart.appendChild(rowElement);
    });
    byId('hiragana').classList.toggle('selected', chartForm === 1);
    byId('katakana').classList.toggle('selected', chartForm === 2);
    byId('hiragana').setAttribute('aria-pressed', String(chartForm === 1));
    byId('katakana').setAttribute('aria-pressed', String(chartForm === 2));
  }

  async function openShare() {
    if (!session || modal) return;
    handleResult(session.tick());
    shareResult = window.KanaShare.prepareResult(session.snapshot(), language, copy, new Date());
    if (!shareResult) { showNotice(copy.ShareEmpty); return; }
    openModal('share');
    byId('save-image').hidden = true;
    byId('post-note').hidden = true;
    byId('share-help').textContent = copy.OpenInXhs;
    try {
      shareDataUrl = window.KanaShare.renderImage(document, shareResult, copy);
      byId('share-image').src = shareDataUrl;
      const options = await platform.sharingOptions();
      if (modal !== 'share') return;
      byId('save-image').hidden = !options.save;
      byId('post-note').hidden = !options.post;
      byId('share-help').textContent = options.post ? copy.ShareReady : copy.OpenInXhs;
    } catch (error) {
      closeModal();
      showNotice(copy.ShareFailed);
    }
  }

  function renderFollow() {
    byId('follow-menu').hidden = followState === null;
    byId('follow-author').disabled = followBusy || followState === 1 || followState === 2;
    byId('follow-label').textContent = followBusy ? copy.Following :
      followState === 1 ? copy.Followed : followState === 2 ? copy.AuthorSelf : copy.FollowAuthor;
  }

  async function refreshFollow() {
    if (followBusy) return;
    const revision = ++followRevision;
    const state = await platform.followStatus();
    // Ignore a query that began before a newer query or an explicit follow action.
    if (revision !== followRevision || followBusy) return;
    followState = state;
    renderFollow();
  }

  async function followAuthor() {
    if (followBusy || followState === null || followState === 1 || followState === 2) return;
    followRevision += 1;
    followBusy = true;
    renderFollow();
    try {
      followState = await platform.followAuthor();
      if (followState === -1) showNotice(copy.FollowFailed);
    } catch (error) {
      if (error && error.errCode === 15404) showNotice(copy.FollowLimited);
      else if (!isCancelled(error) && (!error || error.errCode !== 10003)) showNotice(copy.FollowFailed);
    } finally {
      followBusy = false;
      renderFollow();
    }
  }

  function isCancelled(error) {
    return !!error && (error.errCode === 20002 || /\bcancel(?:led|ed)?\b/i.test(error.errMsg || ''));
  }

  async function exportImage(save) {
    if (shareBusy || !shareDataUrl) return;
    shareBusy = true;
    byId('save-image').disabled = true;
    byId('post-note').disabled = true;
    const button = byId(save ? 'save-image' : 'post-note');
    button.textContent = save ? copy.Saving : copy.Sharing;
    try {
      if (save) {
        await platform.saveImage(shareDataUrl);
        showNotice(copy.Saved);
      } else await platform.share(shareDataUrl, shareResult.title, shareResult.content);
    } catch (error) {
      if (!isCancelled(error)) showNotice(save ? copy.SaveFailed : copy.ShareFailed);
    }
    finally {
      shareBusy = false;
      byId('save-image').disabled = false;
      byId('post-note').disabled = false;
      byId('save-image').textContent = copy.SaveImage;
      byId('post-note').textContent = copy.PublishNote;
    }
  }

  function updateViewport() {
    document.documentElement.style.setProperty('--viewport-height', window.innerHeight + 'px');
    if (session) renderStatistics();
  }

  async function updateInsets() {
    const insets = await platform.windowInsets();
    if (insets) Object.keys(insets).forEach(function (side) {
      document.documentElement.style.setProperty('--safe-' + side, insets[side] + 'px');
    });
    updateViewport();
  }

  function bindEvents() {
    byId('menu-toggle').addEventListener('click', function () { setMenu(!menuOpen); });
    byId('chart-open').addEventListener('click', function () { renderChart(); openModal('chart'); });
    byId('chart-close').addEventListener('click', closeModal);
    byId('share-close').addEventListener('click', closeModal);
    byId('share-open').addEventListener('click', openShare);
    byId('follow-author').addEventListener('click', followAuthor);
    byId('more-toggle').addEventListener('click', function () {
      const open = byId('more-menu').hidden;
      byId('more-menu').hidden = !open;
      byId('more-toggle').setAttribute('aria-expanded', String(open));
    });
    byId('hiragana').addEventListener('click', function () { chartForm = 1; renderChart(); });
    byId('katakana').addEventListener('click', function () { chartForm = 2; renderChart(); });
    byId('save-image').addEventListener('click', function () { exportImage(true); });
    byId('post-note').addEventListener('click', function () { exportImage(false); });
    buttons.forEach(function (button, index) {
      button.addEventListener('click', function () {
        if (!session || modal) return;
        if (menuOpen) setMenu(false);
        handleResult(session.answer(index), true);
      });
    });
    ['chart', 'share'].forEach(function (name) {
      byId(name + '-modal').addEventListener('click', function (event) {
        if (event.target === byId(name + '-modal')) closeModal();
      });
    });
    document.addEventListener('click', function (event) {
      if (!event.target.closest('.more-wrapper')) closeMore();
    });
    document.addEventListener('keydown', function (event) {
      if (event.key === 'Escape') {
        if (modal) closeModal();
        else if (!byId('more-menu').hidden) { closeMore(); byId('more-toggle').focus(); }
        else if (menuOpen) { setMenu(false); byId('menu-toggle').focus(); }
      }
      if (event.key === 'Tab' && modal) {
        const controls = Array.prototype.slice.call(byId(modal + '-modal').querySelectorAll('button')).filter(function (button) {
          return !button.disabled && !button.hidden;
        });
        const first = controls[0];
        const last = controls[controls.length - 1];
        if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); }
        else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
      }
    });
    let touch = null;
    byId('question-pane').addEventListener('touchstart', function (event) {
      if (event.touches.length !== 1 || event.target.closest('button')) return;
      touch = { x: event.touches[0].clientX, y: event.touches[0].clientY };
    }, { passive: true });
    byId('question-pane').addEventListener('touchend', function (event) {
      if (!touch || !event.changedTouches.length) return;
      const dx = event.changedTouches[0].clientX - touch.x;
      const dy = event.changedTouches[0].clientY - touch.y;
      touch = null;
      if (Math.abs(dx) < Math.abs(dy) && dy > 60) setMenu(true);
      else if (Math.abs(dx) < Math.abs(dy) && dy < -60) setMenu(false);
    }, { passive: true });
    byId('question-pane').addEventListener('touchcancel', function () { touch = null; });
    document.addEventListener('visibilitychange', function () {
      background = document.hidden;
      if (background && session) handleResult(session.tick());
      if (background && feedback) feedback.stop();
      syncPause();
      if (!background) { updateInsets(); refreshFollow(); if (feedback) feedback.prepare(); }
    });
    window.addEventListener('pagehide', function () { background = true; if (feedback) feedback.stop(); syncPause(); });
    window.addEventListener('pageshow', function () { background = document.hidden; syncPause(); });
    let resizeTimer;
    window.addEventListener('resize', function () {
      updateViewport();
      clearTimeout(resizeTimer);
      resizeTimer = setTimeout(updateInsets, 150);
    });
  }

  async function start() {
    translate();
    updateViewport();
    bindEvents();
    const fonts = document.fonts && document.fonts.load ? document.fonts.load('155px KanaHand') : Promise.resolve();
    const results = await Promise.all([platform.load(), fonts.catch(function () {}), updateInsets()]);
    const stored = results[0];
    canSave = !stored.failed && (stored.data === null || core.isValidStats(stored.data));
    session = new core.PracticeSession(pool, {
      now: function () { return performance.now(); },
      stats: canSave ? stored.data : null
    });
    session.start();
    feedback = window.KanaFeedback.createFeedback(window, session, copy);
    byId('menu-toggle').disabled = false;
    byId('share-open').disabled = false;
    refreshFollow();
    byId('app').setAttribute('aria-busy', 'false');
    renderStatistics();
    syncPause();
    if (!canSave) showNotice(copy.ReadFailed);
  }

  start().catch(function () { showNotice(copy.LoadingFailed); });
}());
