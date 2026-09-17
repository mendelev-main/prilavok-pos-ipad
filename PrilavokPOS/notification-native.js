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

  // Web orders accepted by the POS are stored in the normal local parked list.
  // Add a server-backed Ready action only for those rows. Local parked checks are untouched.
  let readyBusy = false;
  const originalOpenParkedModal = typeof openParkedModal === 'function' ? openParkedModal : null;

  function readyButtonMarkup(order) {
    if (!order?.webOrderId || order.webReadyAt) return order?.webReadyAt
      ? '<span class="badge" style="background:var(--accent-soft);color:var(--accent);">✓ Готов</span>'
      : '';
    return `<button class="btn btn-primary web-ready-btn" style="flex:none;padding:9px 14px;" onclick="event.stopPropagation();markWebOrderReady('${escapeAttr(order.id)}')">Готов</button>`;
  }

  if (originalOpenParkedModal) {
    window.openParkedModal = function () {
      const list = state.parked.slice().sort((a,b)=>b.createdAt-a.createdAt);
      showModal(`
        <div class="modal-title">Отложенные чеки</div>
        ${list.length ? list.map(o=>`
          <div class="list-row">
            ${readyButtonMarkup(o)}
            <div style="flex:1;min-width:0;">
              <div class="list-row-name">${escapeHtml(o.orderLabel||'Без подписи')}</div>
              <div class="list-row-sub">${o.items.reduce((s,i)=>s+i.qty,0)} поз. · ${fullMoney(o.total)} · ${escapeHtml(o.orderType||'На месте')} · ${fmtDate(o.createdAt)}</div>
            </div>
            <button class="btn btn-outline" style="flex:none;padding:9px 14px;" onclick="resumeParked('${escapeAttr(o.id)}')">Открыть</button>
            <button class="icon-btn danger" onclick="deleteParked('${escapeAttr(o.id)}')">✕</button>
          </div>
        `).join('') : `<div class="center-note">Нет отложенных чеков</div>`}
        <div class="modal-actions"><button class="btn btn-secondary" style="width:100%;" onclick="closeModal()">Закрыть</button></div>
      `);
    };
  }

  window.markWebOrderReady = async function (parkedId) {
    if (readyBusy) return;
    const parked = state.parked.find(x=>x.id===parkedId);
    if (!parked?.webOrderId || parked.webReadyAt) return;
    const n = networkConfigFromState();
    if (!n.backendUrl || !n.deviceKey) { flash('Проверьте сетевые настройки'); return; }
    readyBusy = true;
    const button = document.querySelector('.web-ready-btn');
    if (button) { button.disabled = true; button.textContent = 'Отправляем…'; }
    try {
      const controller = new AbortController();
      const timeout = setTimeout(()=>controller.abort(), 30000);
      let response;
      try {
        response = await fetch(n.backendUrl.replace(/\/+$/,'')+'/api/orders/'+encodeURIComponent(parked.webOrderId)+'/ready', {
          method:'POST',
          headers:{'Content-Type':'application/json','X-Device-Key':n.deviceKey},
          body:'{}',
          cache:'no-store',
          signal:controller.signal
        });
      } finally { clearTimeout(timeout); }
      const data = await response.json().catch(()=>null);
      if (!response.ok) throw new Error(data?.error || ('HTTP '+response.status));

      const next = state.parked.map(x=>x.id===parkedId ? {...x,webReadyAt:Date.now()} : x);
      await window.PrilavokCore.Storage.set('parked', next);
      state.parked = next;
      window.openParkedModal();
      flash('Заказ отмечен как готов');
    } catch (e) {
      flash('Не удалось изменить статус: '+(e?.message||'ошибка сети'));
      window.openParkedModal();
    } finally {
      readyBusy = false;
    }
  };

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