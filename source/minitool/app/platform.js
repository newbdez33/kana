(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.KanaPlatform = factory();
}(typeof window === 'object' ? window : this, function () {
  'use strict';

  const STORAGE_KEY = 'kana.practice.v1';

  function getInsets(info) {
    if (!info || !Number.isFinite(info.windowWidth) || !Number.isFinite(info.windowHeight) ||
        info.windowWidth <= 0 || info.windowHeight <= 0) return null;
    const safe = info.safeArea || {};
    const buttons = info.menuButtons || {};
    const valid = function (value, limit) {
      return Number.isFinite(value) ? Math.max(0, Math.min(limit, value)) : 0;
    };
    let top = valid(safe.top, info.windowHeight);
    Object.keys(buttons).forEach(function (name) {
      const button = buttons[name];
      if (button && Number.isFinite(button.bottom)) top = Math.max(top, valid(button.bottom + 8, info.windowHeight));
    });
    return {
      top: top,
      right: Number.isFinite(safe.right) ? valid(info.windowWidth - safe.right, info.windowWidth) : 0,
      bottom: Number.isFinite(safe.bottom) ? valid(info.windowHeight - safe.bottom, info.windowHeight) : 0,
      left: valid(safe.left, info.windowWidth)
    };
  }

  function createPlatform(host) {
    let useNative = false;
    let writable = false;
    let queue = Promise.resolve();

    function miniTool() {
      return host.xhs && host.xhs.miniTool;
    }

    function supports(name) {
      const api = miniTool();
      return !!api && typeof api[name] === 'function';
    }

    async function version() {
      const read = function (options) {
        const env = options && options.miniToolEnv;
        return Math.floor((Number(env && env.buildVersion) || 0) / 1000);
      };
      const sync = read(host.xhs && host.xhs.launchOptions);
      if (sync) return sync;
      if (!supports('getLaunchOptions')) return 0;
      try { return read(await miniTool().getLaunchOptions()); }
      catch (error) { return 0; }
    }

    async function readNativeStorage() {
      try {
        const response = await miniTool().getStorage({ key: STORAGE_KEY });
        if (!response || (response.data !== null &&
            (typeof response.data !== 'string' || response.data === ''))) {
          throw new Error('Invalid storage response');
        }
        return response.data;
      } catch (error) {
        if (!supports('getStorageInfo')) throw error;
        const info = await miniTool().getStorageInfo();
        // Verify that the key is absent before treating a failed read as an empty record.
        if (!info || !Array.isArray(info.keys) ||
            !info.keys.every(function (key) { return typeof key === 'string'; }) ||
            info.keys.indexOf(STORAGE_KEY) !== -1) throw error;
        return null;
      }
    }

    async function load() {
      writable = false;
      try {
        useNative = (await version()) >= 9460 && supports('getStorage') && supports('setStorage');
        let raw;
        if (useNative) {
          raw = await readNativeStorage();
          if (raw === null) {
            let legacy = null;
            try { legacy = host.localStorage.getItem(STORAGE_KEY); }
            catch (error) { /* Native storage does not require browser storage. */ }
            if (legacy !== null) {
              JSON.parse(legacy);
              await miniTool().setStorage({ key: STORAGE_KEY, data: legacy });
              raw = legacy;
              try { host.localStorage.removeItem(STORAGE_KEY); }
              catch (error) { /* The confirmed native copy is authoritative. */ }
            }
          }
        } else raw = host.localStorage.getItem(STORAGE_KEY);
        const data = raw === null ? null : JSON.parse(raw);
        writable = true;
        return { data: data, failed: false };
      } catch (error) {
        return { data: null, failed: true };
      }
    }

    function save(data) {
      if (!writable) return Promise.resolve(false);
      let serialized;
      try { serialized = JSON.stringify(data); }
      catch (error) { return Promise.resolve(false); }
      // Preserve write order when the native bridge resolves calls at different speeds.
      queue = queue.then(async function () {
        try {
          if (useNative) await miniTool().setStorage({ key: STORAGE_KEY, data: serialized });
          else host.localStorage.setItem(STORAGE_KEY, serialized);
          return true;
        } catch (error) { return false; }
      });
      return queue;
    }

    async function windowInsets() {
      if (!supports('getWindowInfo') || (await version()) < 9490) return null;
      try { return getInsets(await miniTool().getWindowInfo()); }
      catch (error) { return null; }
    }

    async function saveImage(dataUrl) {
      if (!supports('saveImageToPhotosAlbum') || (await version()) < 9420) throw new Error('Image saving is unavailable');
      await miniTool().saveImageToPhotosAlbum({ filePath: dataUrl });
    }

    async function sharingOptions() {
      return {
        post: supports('postNote'),
        save: supports('saveImageToPhotosAlbum') && (await version()) >= 9420
      };
    }

    async function canFollow() {
      return supports('followAuthor') && supports('getFollowStatus') && (await version()) >= 9510;
    }

    async function followStatus() {
      if (!(await canFollow())) return null;
      try {
        const result = await miniTool().getFollowStatus();
        return result && [0, 1, 2].indexOf(result.follow_status) !== -1 ? result.follow_status : -1;
      } catch (error) { return -1; }
    }

    async function followAuthor() {
      if (!(await canFollow())) throw new Error('Following is unavailable');
      const result = await miniTool().followAuthor();
      return result && (result.follow_status === 1 || result.follow_status === 2) ? result.follow_status : -1;
    }

    async function share(dataUrl, title, content) {
      if (!supports('postNote')) throw new Error('Sharing is unavailable');
      await miniTool().postNote({
        title: title,
        content: content,
        pageType: 'photo_publish',
        mediaInfo: { image_resources: [{ url: dataUrl }] }
      });
    }

    return {
      load: load, save: save, supports: supports, windowInsets: windowInsets,
      saveImage: saveImage, share: share, sharingOptions: sharingOptions,
      followStatus: followStatus, followAuthor: followAuthor
    };
  }

  return { createPlatform: createPlatform, getInsets: getInsets };
}));
