import test from 'node:test';
import assert from 'node:assert/strict';
import { PracticeBanner } from '../../../build/h5/ads.mjs';

function fixture({ adUnitId = 'test-banner', hostAvailable = true, placement } = {}) {
  let now = 0;
  let timerId = 0;
  const timers = new Map();
  const ads = [];
  const changes = [];
  const host = {
    createBannerAd(options) {
      const listeners = new Map();
      const ad = {
        options,
        style: { ...options.style },
        showCount: 0,
        hideCount: 0,
        destroyCount: 0,
        show() { this.showCount++; return this.pendingShow ?? Promise.resolve(); },
        hide() { this.hideCount++; },
        destroy() { this.destroyCount++; },
        emit(name, value) { listeners.get(name)?.(value); },
        listenerCount() { return listeners.size; }
      };
      for (const event of ['Load', 'Resize', 'Error']) {
        ad[`on${event}`] = listener => listeners.set(event, listener);
        ad[`off${event}`] = listener => {
          if (listeners.get(event) === listener) listeners.delete(event);
        };
      }
      ads.push(ad);
      return ad;
    }
  };
  const banner = new PracticeBanner({
    host: hostAvailable ? host : undefined,
    adUnitId,
    clock: () => now,
    schedule: (callback, milliseconds) => {
      const id = ++timerId;
      timers.set(id, { callback, at: now + milliseconds });
      return id;
    },
    cancel: id => timers.delete(id),
    placement: placement ?? (size => size.height <= 80 ? {
      left: 8, top: 480 - size.height, width: 368, height: size.height
    } : null),
    render: value => changes.push(value)
  });
  return {
    banner, ads, changes, host,
    advance(milliseconds) {
      const end = now + milliseconds;
      while (true) {
        const next = [...timers].filter(([, task]) => task.at <= end)
          .sort((a, b) => a[1].at - b[1].at)[0];
        if (!next) break;
        now = next[1].at;
        timers.delete(next[0]);
        next[1].callback();
      }
      now = end;
    }
  };
}

test('ordinary browsers and builds without an ad unit do not request or reserve ads', () => {
  for (const options of [{ hostAvailable: false }, { adUnitId: '' }]) {
    const f = fixture(options);
    f.advance(120000);
    f.banner.show();
    assert.equal(f.ads.length, 0);
    assert.ok(f.changes.every(value => value === null));
  }
});

test('the first minute is ad-free and background time does not count', async () => {
  const f = fixture();
  f.advance(30000);
  f.banner.setActive(false);
  f.advance(300000);
  f.banner.setActive(true);
  f.advance(29999);
  f.banner.show();
  assert.equal(f.ads.length, 0);
  f.advance(1);
  f.banner.show();
  assert.equal(f.ads.length, 1);
  assert.equal(f.ads[0].showCount, 0);
  assert.ok(f.changes.every(value => value === null));
  f.ads[0].emit('Load');
  await Promise.resolve();
  assert.equal(f.ads[0].showCount, 1);
  assert.equal(f.changes.at(-1).height, 50);
});

test('leaving a correction removes the native banner and its listeners', async () => {
  const f = fixture();
  f.advance(60000);
  f.banner.show();
  const ad = f.ads[0];
  ad.emit('Resize', { width: 368, height: 60 });
  ad.emit('Load');
  await Promise.resolve();
  assert.equal(ad.style.top, 420);
  f.banner.hide();
  assert.equal(ad.hideCount, 1);
  assert.equal(ad.destroyCount, 1);
  assert.equal(ad.listenerCount(), 0);
  assert.equal(f.changes.at(-1), null);
});

test('an ad that finishes showing after the next question cannot reappear', async () => {
  const f = fixture();
  f.advance(60000);
  f.banner.show();
  const first = f.ads[0];
  let resolveShow;
  first.pendingShow = new Promise(resolve => { resolveShow = resolve; });
  first.emit('Load');
  f.banner.hide();
  f.banner.show();
  const second = f.ads[1];
  second.emit('Load');
  await Promise.resolve();
  resolveShow();
  await Promise.resolve();
  assert.equal(second.destroyCount, 0);
  assert.equal(second.hideCount, 0);
  assert.ok(first.hideCount >= 1);
  assert.equal(f.changes.at(-1).height, 50);
});

test('load failures and show failures release all reserved space', async () => {
  const f = fixture();
  f.advance(60000);
  f.banner.show();
  f.ads[0].emit('Error', { errCode: 1004 });
  assert.equal(f.changes.at(-1), null);
  assert.equal(f.ads[0].destroyCount, 1);
  f.banner.show();
  const ad = f.ads[1];
  ad.pendingShow = Promise.reject(new Error('No fill'));
  ad.emit('Load');
  await Promise.resolve();
  await Promise.resolve();
  assert.equal(f.changes.at(-1), null);
  assert.equal(ad.destroyCount, 1);
});

test('invalid or oversized native dimensions hide the banner', () => {
  for (const size of [{ width: 368, height: 100 }, { width: 368, height: NaN }]) {
    const f = fixture();
    f.advance(60000);
    f.banner.show();
    f.ads[0].emit('Resize', size);
    f.ads[0].emit('Load');
    assert.equal(f.ads[0].showCount, 0);
    assert.equal(f.ads[0].destroyCount, 1);
    assert.equal(f.changes.at(-1), null);
  }
});

test('a layout change that cannot fit the banner removes it', async () => {
  let fits = true;
  const f = fixture({ placement: size => fits ? {
    left: 8, top: 480 - size.height, width: 368, height: size.height
  } : null });
  f.advance(60000);
  f.banner.show();
  f.ads[0].emit('Load');
  await Promise.resolve();
  fits = false;
  f.banner.reposition();
  assert.equal(f.ads[0].destroyCount, 1);
  assert.equal(f.changes.at(-1), null);
});

test('banner time is limited to twenty percent of foreground session time', async () => {
  const f = fixture();
  f.advance(60000);
  f.banner.show();
  f.ads[0].emit('Load');
  await Promise.resolve();
  f.advance(14999);
  assert.equal(f.ads[0].destroyCount, 0);
  f.advance(1);
  assert.equal(f.ads[0].destroyCount, 1);
  assert.equal(f.changes.at(-1), null);
  f.banner.show();
  assert.equal(f.ads.length, 1);
  f.advance(60000);
  f.banner.show();
  assert.equal(f.ads.length, 2);
});

test('background entry removes an ad without consuming hidden display time', async () => {
  const f = fixture();
  f.advance(60000);
  f.banner.show();
  f.ads[0].emit('Load');
  await Promise.resolve();
  f.advance(1000);
  f.banner.setActive(false);
  assert.equal(f.ads[0].destroyCount, 1);
  f.advance(300000);
  f.banner.show();
  assert.equal(f.ads.length, 1);
  f.banner.setActive(true);
  f.banner.show();
  assert.equal(f.ads.length, 2);
});

test('an unavailable SDK cannot interrupt the game', () => {
  const f = fixture();
  f.host.createBannerAd = () => { throw new Error('Unsupported runtime'); };
  f.advance(60000);
  assert.doesNotThrow(() => f.banner.show());
  assert.equal(f.changes.at(-1), null);
});

test('default timers do not use the banner as their browser receiver', t => {
  let now = 0;
  let cancelled = false;
  t.mock.method(globalThis, 'setTimeout', function (callback, delay) {
    assert.equal(this, undefined);
    assert.equal(delay, 15000);
    return 7;
  });
  t.mock.method(globalThis, 'clearTimeout', function (timer) {
    assert.equal(this, undefined);
    assert.equal(timer, 7);
    cancelled = true;
  });
  const f = fixture();
  const banner = new PracticeBanner({
    host: f.host,
    adUnitId: 'test-banner',
    clock: () => now,
    placement: size => ({ left: 8, top: 430, width: 368, height: size.height }),
    render() {}
  });
  now = 60000;
  banner.show();
  f.ads[0].emit('Load');
  assert.equal(f.ads[0].showCount, 1);
  banner.hide();
  assert.equal(cancelled, true);
});
