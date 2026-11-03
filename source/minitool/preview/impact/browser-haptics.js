(function () {
  'use strict';
  // This adapter is included only in the ordinary browser preview.
  window.KanaBrowserHaptics = {
    available: function () { return typeof navigator.vibrate === 'function'; },
    pulse: function (type) { return navigator.vibrate({ light: 12, medium: 24, heavy: 40 }[type]); },
    stop: function () {
      if (typeof navigator.vibrate === 'function') navigator.vibrate(0);
    }
  };
  document.addEventListener('DOMContentLoaded', function () {
    const control = document.getElementById('system-switch');
    if (!window.xhs && !window.KanaBrowserHaptics.available() && 'switch' in control) {
      document.getElementById('system-switch-test').hidden = false;
    }
  });
}());
