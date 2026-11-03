(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.KanaShare = factory();
}(typeof window === 'object' ? window : this, function () {
  'use strict';

  function prepareResult(stats, language, copy, date) {
    if (!stats.totalCount && !stats.bestStreak) return null;
    function seconds(value) {
      return copy.StatSeconds.replace('%@', value.toLocaleString(language, {
        minimumFractionDigits: 2, maximumFractionDigits: 2
      }));
    }
    const recent = stats.recentCosts.reduce(function (sum, cost) { return sum + cost; }, 0);
    const values = [stats.totalCount.toLocaleString(language),
      stats.totalCount ? seconds(stats.totalCost / stats.totalCount) : '—',
      stats.recentCosts.length ? seconds(recent / stats.recentCosts.length) : '—',
      stats.bestStreak.toLocaleString(language)];
    const labels = [copy.StatAnswers, copy.StatAverage, copy.StatRecent.replace('%d', '10'), copy.StatBest];
    return {
      title: copy.ShareNoteTitle,
      content: [copy.ShareNoteIntro].concat(values.map(function (value, index) {
        return labels[index] + ': ' + value;
      }), ['', copy.ShareCaption, '#五十音 #日语学习 #小红书小工具']).join('\n'),
      values: values,
      labels: labels,
      date: date.toLocaleDateString(language, { year: 'numeric', month: '2-digit', day: '2-digit' })
    };
  }

  function renderImage(document, result, copy) {
    const canvas = document.createElement('canvas');
    canvas.width = 1080;
    canvas.height = 1440;
    const context = canvas.getContext('2d');
    if (!context) throw new Error('Canvas is unavailable');
    const font = '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif';
    function text(value, x, y, size, color, maxWidth, weight) {
      context.font = (weight || '500') + ' ' + size + 'px ' + font;
      while (context.measureText(value).width > maxWidth && size > 16) {
        size -= 1;
        context.font = (weight || '500') + ' ' + size + 'px ' + font;
      }
      context.fillStyle = color;
      context.fillText(value, x, y);
    }
    context.fillStyle = '#f8f8f8';
    context.fillRect(0, 0, 1080, 1440);
    text('Kana · 五十音', 72, 112, 32, '#6e6963', 740);
    context.font = '108px KanaHand';
    context.fillStyle = '#c93332';
    context.textAlign = 'right';
    context.fillText('あ', 1008, 140);
    context.textAlign = 'left';
    text(copy.ShareNoteTitle, 72, 236, 54, '#171412', 936, '600');
    text(copy.Tagline, 72, 302, 30, '#6e6963', 936);

    context.textAlign = 'center';
    text(result.labels[3], 540, 462, 34, '#c93332', 936);
    text(result.values[3], 540, 748, 252, '#c93332', 936, '600');
    text(copy.PersonalBest, 540, 824, 28, '#6e6963', 936);

    context.fillStyle = '#fff';
    context.fillRect(0, 922, 1080, 518);
    for (let index = 0; index < 3; index++) {
      const x = 228 + index * 312;
      text(result.values[index], x, 1046, 58, '#171412', 276);
      text(result.labels[index], x, 1106, 26, '#6e6963', 276);
    }
    text(copy.Practice + ' · ' + result.date, 540, 1208, 25, '#6e6963', 936);
    context.fillStyle = '#c93332';
    context.fillRect(492, 1280, 96, 4);
    text(copy.ShareCaption, 540, 1362, 30, '#6e6963', 936);
    return canvas.toDataURL('image/png');
  }

  return { prepareResult: prepareResult, renderImage: renderImage };
}));
