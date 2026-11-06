const WARMUP_MS = 60000;
const AD_TIME_SHARE = 0.2;

function call(ad, method, ...args) {
  try { ad[method]?.(...args); } catch { /* Ad failures must not block practice. */ }
}

export class PracticeBanner {
  constructor({ host, adUnitId, placement, render, clock = () => performance.now(),
    schedule = (callback, delay) => setTimeout(callback, delay),
    cancel = timer => clearTimeout(timer) }) {
    Object.assign(this, { host, adUnitId, placement, render, clock, schedule, cancel });
    this.active = true;
    this.lastTime = clock();
    this.sessionMs = 0;
    this.displayMs = 0;
    this.current = null;
    this.timer = null;
  }

  accountTime() {
    const now = this.clock();
    const elapsed = Math.max(0, now - this.lastTime);
    if (this.active) {
      this.sessionMs += elapsed;
      if (this.current?.visible) this.displayMs += elapsed;
    }
    this.lastTime = now;
  }

  remainingDisplayTime() {
    this.accountTime();
    // Display time also increases session time: A + t <= share * (S + t).
    return Math.max(0, (this.sessionMs * AD_TIME_SHARE - this.displayMs) / (1 - AD_TIME_SHARE));
  }

  setActive(active) {
    this.accountTime();
    this.active = active;
    if (!active) this.hide();
  }

  show() {
    this.hide();
    if (!this.active || !this.adUnitId || typeof this.host?.createBannerAd !== 'function' ||
        this.sessionMs < WARMUP_MS || this.remainingDisplayTime() < 1000) return;
    let entry;
    try {
      const position = this.placement({ width: 0, height: 50 });
      if (!position) return;
      const ad = this.host.createBannerAd({ adUnitId: this.adUnitId, style: { ...position } });
      entry = { ad, size: { width: position.width, height: position.height }, visible: false };
      this.current = entry;
      entry.listeners = {
        Resize: size => this.resize(entry, size),
        Error: () => { if (this.current === entry) this.hide(); },
        Load: () => this.present(entry)
      };
      for (const [event, listener] of Object.entries(entry.listeners)) {
        if (this.current !== entry) break;
        ad[`on${event}`](listener);
      }
    } catch {
      if (!entry || this.current === entry) this.hide();
    }
  }

  resize(entry, size) {
    if (this.current !== entry) return;
    if (!Number.isFinite(size?.width) || size.width < 300 ||
        !Number.isFinite(size?.height) || size.height <= 0) {
      this.hide();
      return;
    }
    entry.size = { width: size.width, height: size.height };
    this.reposition();
  }

  reposition() {
    const entry = this.current;
    if (!entry) return;
    try {
      const position = this.placement(entry.size);
      if (!position) { this.hide(); return; }
      for (const property of ['left', 'top', 'width']) {
        if (entry.ad.style[property] !== position[property]) entry.ad.style[property] = position[property];
      }
      if (entry.visible) this.render(position);
    } catch { this.hide(); }
  }

  present(entry) {
    if (this.current !== entry || entry.visible) return;
    try {
      const duration = this.remainingDisplayTime();
      if (!this.active || duration < 1000) { this.hide(); return; }
      const { realWidth, realHeight } = entry.ad.style;
      if (realWidth > 0 && realHeight > 0) entry.size = { width: realWidth, height: realHeight };
      this.reposition();
      if (this.current !== entry) return;
      const position = this.placement(entry.size);
      if (!position) { this.hide(); return; }
      entry.visible = true;
      this.render(position);
      this.timer = this.schedule(() => {
        if (this.current === entry) this.hide();
      }, duration);
      Promise.resolve(entry.ad.show()).then(() => {
        if (this.current !== entry) {
          call(entry.ad, 'hide');
          call(entry.ad, 'destroy');
        }
      }, () => {
        if (this.current === entry) this.hide();
      });
    } catch { if (this.current === entry) this.hide(); }
  }

  hide() {
    this.accountTime();
    const entry = this.current;
    this.current = null;
    if (this.timer !== null) this.cancel(this.timer);
    this.timer = null;
    if (entry) {
      for (const [event, listener] of Object.entries(entry.listeners ?? {})) {
        call(entry.ad, `off${event}`, listener);
      }
      call(entry.ad, 'hide');
      call(entry.ad, 'destroy');
    }
    this.render(null);
  }
}
