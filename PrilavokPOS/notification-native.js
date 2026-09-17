(() => {
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

  window.previewNotificationSound = () => {
    const sound = document.getElementById('notify-sound')?.value || 'default';
    nativeSound(sound);
  };

  window.playPOSEventSound = () => {
    let settings = { soundEnabled: true, sound: 'default' };
    try {
      settings = { ...settings, ...JSON.parse(localStorage.getItem('posNotificationSettings') || '{}') };
    } catch (_) {}
    if (!settings.soundEnabled) return;
    nativeSound(settings.sound);
  };
})();