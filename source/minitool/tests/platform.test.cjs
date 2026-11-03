const test = require('node:test');
const assert = require('node:assert/strict');
const { createPlatform, getInsets } = require('../app/platform.js');

function localStorage(data = null) {
  return {
    getItem() { return data; },
    setItem(key, value) { data = value; },
    removeItem() { data = null; }
  };
}

function nativeHost(overrides = {}) {
  return {
    localStorage: localStorage(),
    xhs: {
      launchOptions: { miniToolEnv: { buildVersion: 9462004 } },
      miniTool: Object.assign({
        getStorage: async () => ({ data: null }),
        setStorage: async () => ({ errMsg: 'setStorage:ok' })
      }, overrides)
    }
  };
}

test('modern clients use native storage and serialize all writes in order', async () => {
  const writes = [];
  const host = nativeHost({
    getStorage: async () => ({ data: '{"count":3}' }),
    setStorage: async (args) => { writes.push(args.data); }
  });
  host.localStorage.getItem = () => { throw new Error('Unexpected fallback'); };
  const platform = createPlatform(host);
  assert.deepEqual(await platform.load(), { data: { count: 3 }, failed: false });
  assert.deepEqual(await Promise.all([platform.save({ count: 4 }), platform.save({ count: 5 })]), [true, true]);
  assert.deepEqual(writes, ['{"count":4}', '{"count":5}']);
});

test('an unavailable native read never overwrites a record with an empty session', async () => {
  let writes = 0;
  const platform = createPlatform(nativeHost({
    getStorage: async () => { throw new Error('Read failed'); },
    setStorage: async () => { writes++; }
  }));
  assert.equal((await platform.load()).failed, true);
  assert.equal(await platform.save({ count: 0 }), false);
  assert.equal(writes, 0);
});

test('a missing native key can be initialized and restored after reopening', async () => {
  const records = new Map();
  const host = nativeHost({
    getStorage: async ({ key }) => {
      if (!records.has(key)) throw { errMsg: 'getStorage:fail key not found' };
      return { data: records.get(key) };
    },
    getStorageInfo: async () => ({ keys: Array.from(records.keys()), usedBytes: 0, limitBytes: 10485760 }),
    setStorage: async ({ key, data }) => { records.set(key, data); }
  });
  const first = createPlatform(host);
  assert.deepEqual(await first.load(), { data: null, failed: false });
  const stats = { version: 1, totalCount: 1, totalCost: 0.5, recentCosts: [0.5], currentStreak: 1, bestStreak: 1 };
  assert.equal(await first.save(stats), true);
  host.localStorage = localStorage();
  assert.deepEqual(await createPlatform(host).load(), { data: stats, failed: false });
});

test('an empty native response is accepted only when the key is absent', async () => {
  for (const data of [undefined, '']) {
    const platform = createPlatform(nativeHost({
      getStorage: async () => ({ data }),
      getStorageInfo: async () => ({ keys: [] })
    }));
    assert.deepEqual(await platform.load(), { data: null, failed: false });
    assert.equal(await platform.save({ count: 1 }), true);
  }
});

test('an existing or unknown native key is protected when reading fails', async () => {
  for (const keys of [['kana.practice.v1'], undefined]) {
    let writes = 0;
    const platform = createPlatform(nativeHost({
      getStorage: async () => { throw new Error('Read failed'); },
      getStorageInfo: async () => ({ keys }),
      setStorage: async () => { writes++; }
    }));
    assert.equal((await platform.load()).failed, true);
    assert.equal(await platform.save({ count: 0 }), false);
    assert.equal(writes, 0);
  }
});

test('failed native writes do not fork data into browser storage', async () => {
  const host = nativeHost({ setStorage: async () => { throw new Error('Disk full'); } });
  const platform = createPlatform(host);
  await platform.load();
  assert.equal(await platform.save({ count: 3 }), false);
  assert.equal(host.localStorage.getItem(), null);
});

test('old clients and browser previews use guarded local storage', async () => {
  const platform = createPlatform({ localStorage: localStorage('{"count":2}') });
  assert.deepEqual((await platform.load()).data, { count: 2 });
  assert.equal(await platform.save({ count: 3 }), true);
  const blocked = createPlatform({ get localStorage() { throw new Error('Unavailable'); } });
  assert.equal((await blocked.load()).failed, true);
  assert.equal(await blocked.save({ count: 3 }), false);
});

test('upgrade migrates browser data only after a confirmed native write', async () => {
  let saved;
  const host = nativeHost({ setStorage: async (args) => { saved = args.data; } });
  host.localStorage = localStorage('{"count":7}');
  const platform = createPlatform(host);
  assert.deepEqual((await platform.load()).data, { count: 7 });
  assert.equal(saved, '{"count":7}');
  assert.equal(host.localStorage.getItem(), null);
});

test('an async launch configuration uses the same version rule', async () => {
  let nativeReads = 0;
  const host = nativeHost({
    getLaunchOptions: async () => ({ miniToolEnv: { buildVersion: 9460001 } }),
    getStorage: async () => { nativeReads++; return { data: null }; }
  });
  delete host.xhs.launchOptions;
  await createPlatform(host).load();
  assert.equal(nativeReads, 1);
});

test('corrupt stored JSON is reported as a read failure', async () => {
  const platform = createPlatform({ localStorage: localStorage('{broken') });
  assert.equal((await platform.load()).failed, true);
  assert.equal(await platform.save({ count: 0 }), false);
});

test('a slow native write cannot complete after a newer write', async () => {
  let release;
  const writes = [];
  const platform = createPlatform(nativeHost({
    setStorage: async (args) => {
      writes.push(args.data);
      if (writes.length === 1) await new Promise((resolve) => { release = resolve; });
    }
  }));
  await platform.load();
  const first = platform.save({ count: 1 });
  const second = platform.save({ count: 2 });
  await Promise.resolve();
  assert.deepEqual(writes, ['{"count":1}']);
  release();
  assert.deepEqual(await Promise.all([first, second]), [true, true]);
  assert.deepEqual(writes, ['{"count":1}', '{"count":2}']);
});

test('failed migration retains the browser record and prevents replacement writes', async () => {
  let writes = 0;
  const host = nativeHost({ setStorage: async () => { writes++; throw new Error('Unavailable'); } });
  host.localStorage = localStorage('{"count":7}');
  const platform = createPlatform(host);
  assert.equal((await platform.load()).failed, true);
  assert.equal(host.localStorage.getItem(), '{"count":7}');
  assert.equal(await platform.save({ count: 0 }), false);
  assert.equal(writes, 1);
});

test('safe area and every visible native button are kept clear', () => {
  assert.deepEqual(getInsets({
    windowWidth: 393, windowHeight: 852,
    safeArea: { left: 0, top: 59, right: 393, bottom: 818 },
    menuButtons: { back: { bottom: 94 }, me: null, share: { bottom: 102 } }
  }), { top: 110, right: 0, bottom: 34, left: 0 });
  assert.equal(getInsets({ windowHeight: NaN }), null);
});

test('sharing forwards image media and does not report failure as success', async () => {
  let note;
  const host = nativeHost({
    postNote: async (args) => { note = args; },
    saveImageToPhotosAlbum: async () => { throw { errMsg: 'saveImageToPhotosAlbum:fail denied' }; }
  });
  const platform = createPlatform(host);
  await platform.share('data:image/png;base64,abc', 'Kana', 'Practice');
  assert.equal(note.mediaInfo.image_resources[0].url, 'data:image/png;base64,abc');
  assert.equal(note.pageType, 'photo_publish');
  await assert.rejects(platform.saveImage('data:image/png;base64,abc'));
});

test('score notes use only public fields and preserve cancellation', async () => {
  const calls = [];
  const platform = createPlatform(nativeHost({ postNote: async (options) => { calls.push(options); } }));
  await platform.share('data:image/png;base64,score', 'My kana practice', 'Best streak: 12');
  assert.deepEqual(calls, [{
    title: 'My kana practice', content: 'Best streak: 12', pageType: 'photo_publish',
    mediaInfo: { image_resources: [{ url: 'data:image/png;base64,score' }] }
  }]);
  const cancelled = { errCode: 20002, errMsg: 'postNote:fail cancel' };
  const rejected = createPlatform(nativeHost({ postNote: async () => { throw cancelled; } }));
  await assert.rejects(rejected.share('image', 'title', 'content'), (error) => error === cancelled);
});

test('follow requires client 9.51 and both public methods', async () => {
  let calls = 0;
  const host = nativeHost({
    getFollowStatus: async () => { calls++; return { follow_status: 0 }; },
    followAuthor: async () => { calls++; return { follow_status: 1 }; }
  });
  const platform = createPlatform(host);
  assert.equal(await platform.followStatus(), null);
  await assert.rejects(platform.followAuthor());
  assert.equal(calls, 0);
  host.xhs.launchOptions.miniToolEnv.buildVersion = 9510001;
  assert.equal(await platform.followStatus(), 0);
  assert.equal(await platform.followAuthor(), 1);
  assert.equal(calls, 2);
  delete host.xhs.miniTool.followAuthor;
  assert.equal(await platform.followStatus(), null);
});

test('follow passes no author ID and distinguishes failed, followed, and self states', async () => {
  const host = nativeHost();
  host.xhs.launchOptions.miniToolEnv.buildVersion = 9510001;
  for (const status of [-1, 0, 1, 2, undefined]) {
    host.xhs.miniTool.getFollowStatus = async (...args) => {
      assert.deepEqual(args, []);
      return { follow_status: status };
    };
    host.xhs.miniTool.followAuthor = async (...args) => {
      assert.deepEqual(args, []);
      return { follow_status: status };
    };
    const platform = createPlatform(host);
    assert.equal(await platform.followStatus(), status === undefined ? -1 : status);
    assert.equal(await platform.followAuthor(), status === 1 || status === 2 ? status : -1);
  }
});

test('follow preserves cancellation and rate limits, then permits a retry', async () => {
  const host = nativeHost({ getFollowStatus: async () => { throw new Error('Unavailable'); } });
  host.xhs.launchOptions.miniToolEnv.buildVersion = 9510001;
  for (const code of [20002, 15404, 10003]) {
    host.xhs.miniTool.followAuthor = async () => { throw { errCode: code }; };
    const platform = createPlatform(host);
    assert.equal(await platform.followStatus(), -1);
    await assert.rejects(platform.followAuthor(), (error) => error.errCode === code);
    host.xhs.miniTool.followAuthor = async () => ({ follow_status: 1 });
    assert.equal(await platform.followAuthor(), 1);
  }
});
