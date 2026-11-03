const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const { prepareResult } = require('../app/share.js');
const { emptyStats } = require('../app/core.js');
let appData;

test.before(async () => {
  const { readIOSData } = await import('../scripts/ios-data.mjs');
  appData = readIOSData();
});

function translations() {
  const context = { window: {} };
  vm.runInNewContext(fs.readFileSync(require.resolve('../app/copy.js'), 'utf8'), context);
  return Object.keys(appData.copy).map((language) => ({
    language,
    copy: Object.assign({}, appData.copy[language], context.window.KanaExtraCopy[language])
  }));
}

test('an empty practice record has no score card', () => {
  for (const { language, copy } of translations()) {
    assert.equal(prepareResult(emptyStats(), language, copy, new Date(2026, 10, 3)), null);
  }
});

test('card and note use one real snapshot without treating answer count as correct answers', () => {
  const { copy } = translations().find((entry) => entry.language === 'zh-Hans');
  const stats = { totalCount: 12, totalCost: 24, recentCosts: [1, 2, 3], bestStreak: 4 };
  const result = prepareResult(stats, 'zh-Hans', copy, new Date(2026, 10, 3));
  assert.deepEqual(result.values, ['12', '2.00秒', '2.00秒', '4']);
  assert.match(result.content, /累计答题[：:] ?12/);
  assert.match(result.content, /最长连对[：:] ?4/);
  assert.doesNotMatch(result.content, /正确率|排名|超过.*用户|今天.*12/);
  stats.totalCount = 30;
  stats.bestStreak = 25;
  stats.recentCosts.push(5);
  assert.equal(result.values[0], '12');
  assert.equal(result.values[3], '4');
});

test('a correction streak with no timed answers does not invent response times', () => {
  const { language, copy } = translations()[0];
  const stats = Object.assign(emptyStats(), { bestStreak: 1 });
  const result = prepareResult(stats, language, copy, new Date());
  assert.deepEqual(result.values, ['0', '—', '—', '1']);
  assert.doesNotMatch(result.content, /NaN|Infinity/);
});

test('every language stays within native note limits for large statistics', () => {
  for (const { language, copy } of translations()) {
    const result = prepareResult({
      totalCount: Number.MAX_SAFE_INTEGER, totalCost: Number.MAX_SAFE_INTEGER,
      recentCosts: [0.01, 4.99], bestStreak: Number.MAX_SAFE_INTEGER
    }, language, copy, new Date(2026, 10, 3));
    assert.ok(result.title.length <= 20, language);
    assert.ok(result.content.length <= 1000, language);
    assert.doesNotMatch(result.content, /undefined|NaN|Infinity|%[@ds]/);
    assert.match(result.content, /#五十音 #日语学习 #小红书小工具/);
    assert.ok(copy.Share && copy.FollowAuthor && copy.FollowFailed && copy.ShareEmpty, language);
  }
});
