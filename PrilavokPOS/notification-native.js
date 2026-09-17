(() => {
  const SOUND_OPTIONS = [
    ['default', 'Прилавок — мягкий'],
    ['chime', 'Chime — двойной'],
    ['glass', 'Glass — лёгкий звон'],
    ['ding', 'Ding — кассовый'],
    ['double', 'Double — два сигнала'],
    ['warm', 'Warm — тёплый'],
    ['pop', 'Pop — короткий'],
    ['bright', 'Bright — светлый'],
    ['soft', 'Soft — спокойный'],
    ['classic', 'Classic — колокольчик']
  ];

  function nativeSound(name) {
    const handler = window.webkit?.messageHandlers?.printer;
    if (!handler) {
      window.flash?.('Нативный звук доступен только в приложении на iPad');
      return false;
    }
    handler.postMessage({
      action: 'print',
      order: { __notificationSound: name || 'default' }
    });
    return true;
  }

  function notificationSettings() {
    let settings = { soundEnabled: true, sound: 'default' };
    try {
      settings = { ...settings, ...JSON.parse(localStorage.getItem('posNotificationSettings') || '{}') };
    } catch (_) {}
    return settings;
  }

  window.previewNotificationSound = () => {
    const sound = document.getElementById('notify-sound')?.value || 'default';
    nativeSound(sound);
  };

  window.playPOSEventSound = () => {
    const settings = notificationSettings();
    if (!settings.soundEnabled) return;
    nativeSound(settings.sound);
  };

  // network-printer.js owns the settings modal. Extend its selector without
  // duplicating that UI or changing the large POS HTML file.
  const originalOpenNotificationSettings = window.openNotificationSettings;
  if (typeof originalOpenNotificationSettings === 'function') {
    window.openNotificationSettings = (...args) => {
      const result = originalOpenNotificationSettings(...args);
      requestAnimationFrame(() => {
        const select = document.getElementById('notify-sound');
        if (!select) return;
        const selected = notificationSettings().sound;
        select.innerHTML = SOUND_OPTIONS.map(([value, label]) =>
          `<option value="${value}" ${value === selected ? 'selected' : ''}>${label}</option>`
        ).join('');
      });
      return result;
    };
  }

  // Detect the counter on the top-bar "События" control. The first value seen
  // after app launch is only a baseline, so old events never make noise again.
  // A sound is emitted once when the visible event count increases.
  let baselineReady = false;
  let lastEventCount = 0;
  let checkTimer = 0;

  function readEventsCount() {
    const controls = [...document.querySelectorAll('button, [role="button"]')];
    const control = controls.find(el => /события/i.test(el.textContent || ''));
    if (!control) return null;

    const badge = control.querySelector('.badge,.count,.counter,[class*="badge"],[class*="count"]');
    const badgeNumber = badge?.textContent?.match(/\d+/);
    if (badgeNumber) return Number(badgeNumber[0]);

    const text = (control.textContent || '').replace(/\s+/g, ' ').trim();
    const number = text.match(/(?:события)\D*(\d+)/i);
    return number ? Number(number[1]) : 0;
  }

  function checkForNewEvents() {
    checkTimer = 0;
    const count = readEventsCount();
    if (count == null) return;
    if (!baselineReady) {
      baselineReady = true;
      lastEventCount = count;
      return;
    }
    if (count > lastEventCount) window.playPOSEventSound?.();
    lastEventCount = count;
  }

  function scheduleCheck() {
    if (checkTimer) return;
    checkTimer = window.setTimeout(checkForNewEvents, 120);
  }

  const startObserver = () => {
    checkForNewEvents();
    const observer = new MutationObserver(scheduleCheck);
    observer.observe(document.body, { childList: true, subtree: true, characterData: true });
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', startObserver, { once: true });
  } else {
    startObserver();
  }
})();