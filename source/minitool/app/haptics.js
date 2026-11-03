(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.KanaHaptics = factory();
}(typeof window === 'object' ? window : this, function () {
  'use strict';
  function createHaptics(host, browser, clock) {
    const now = clock || function () { return Date.now(); };
    let mode = 'loading';
    let reason = '';
    let pending = false;
    let last = -Infinity;
    async function bounded(request) {
      let timer;
      try {
        return await Promise.race([request, new Promise(function (resolve, reject) {
          timer = setTimeout(function () { reject({ errCode: 'timeout' }); }, 1500);
        })]);
      } finally { clearTimeout(timer); }
    }
    function version(options) {
      const env = options && options.miniToolEnv;
      return Math.floor((Number(env && env.buildVersion) || 0) / 1000);
    }
    async function prepare() {
      const xhs = host.xhs;
      if (xhs) {
        const api = xhs.miniTool;
        let client = version(xhs.launchOptions);
        if (!client && api && typeof api.getLaunchOptions === 'function') {
          try { client = version(await bounded(api.getLaunchOptions())); }
          catch (error) { client = 0; }
        }
        mode = client >= 9500 && api && typeof api.vibrateShort === 'function' ? 'native' : 'unsupported';
        reason = mode === 'native' ? '' : 'client';
      } else {
        mode = browser && browser.available() ? 'browser' : 'unsupported';
        reason = mode === 'browser' ? '' : 'browser';
      }
      return { mode: mode, reason: reason };
    }
    async function pulse(type, userGesture) {
      if (!userGesture || (host.document && host.document.hidden) || ['light', 'medium', 'heavy'].indexOf(type) < 0) {
        return { status: 'skipped', mode: mode, type: type };
      }
      if (mode !== 'native' && mode !== 'browser') return { status: 'unsupported', mode: mode, type: type };
      if (pending || now() - last < 180) return { status: 'skipped', mode: mode, type: type };
      last = now();
      pending = true;
      try {
        if (mode === 'native') await bounded(host.xhs.miniTool.vibrateShort({ type: type }));
        else if (!browser.pulse(type)) return { status: 'failed', mode: mode, type: type };
        // Acceptance by an API is not proof that the device produced a physical pulse.
        return { status: 'requested', mode: mode, type: type };
      } catch (error) {
        return { status: 'failed', mode: mode, type: type, code: error && error.errCode };
      } finally { pending = false; }
    }
    function stop() {
      if (mode === 'browser' && browser && browser.stop) browser.stop();
    }
    return { prepare: prepare, pulse: pulse, stop: stop };
  }
  return { createHaptics: createHaptics };
}));
