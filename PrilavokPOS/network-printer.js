(() => {
  const NETWORK_PORT = 9100;

  function printerPost(payload) {
    const handler = window.webkit?.messageHandlers?.printer;
    if (!handler) {
      window.flash?.('Сетевой модуль печати доступен только в приложении на iPad');
      return false;
    }
    handler.postMessage(payload);
    return true;
  }

  function currentPrinterIp() {
    return (document.getElementById('printer-ip')?.value || window.state?.printer?.ip || '').trim();
  }

  function networkOrder(order, ip) {
    return {
      ...(order || {}),
      currency: order?.currency || window.state?.currency || 'BYN',
      __networkPrinterIp: ip,
      __networkPrinterPort: NETWORK_PORT
    };
  }

  function patchPrinterSettingsUi() {
    const portInput = document.getElementById('printer-port');
    if (!portInput) return;

    portInput.value = String(NETWORK_PORT);
    const portField = portInput.closest('.field');
    if (portField) portField.style.display = 'none';
    const grid = portInput.closest('.grid-2');
    if (grid) grid.style.gridTemplateColumns = '1fr';

    document.querySelectorAll('.settings-note').forEach(note => {
      if ((note.textContent || '').includes('Print Bridge')) {
        note.innerHTML = 'Принтер подключается напрямую к iPad по локальной сети. Укажите только IP-адрес принтера — технический порт <b>9100</b> приложение использует автоматически.';
      }
    });

    document.querySelectorAll('.setting-sub').forEach(block => {
      const text = block.textContent || '';
      if (text.includes('Укажите IP и порт 9100')) {
        block.innerHTML = '1. Подключите iPad и принтер к одной Wi‑Fi / LAN сети.<br>2. Узнайте IP-адрес принтера через self-test или настройки роутера.<br>3. Укажите IP-адрес здесь.<br>4. Нажмите «Проверить подключение».';
      }
    });

    const status = document.querySelector('.printer-status');
    if (status && window.state?.printer) {
      const p = window.state.printer;
      const configured = !!(p.ip && p.enabled);
      const safeIp = window.escapeHtml?.(p.ip) || p.ip;
      const desired = `<span class="dot ${configured ? 'on' : 'off'}"></span>${configured ? safeIp : 'Принтер не настроен'}`;
      if (status.innerHTML !== desired) status.innerHTML = desired;
    }
  }

  const originalRender = window.render;
  if (typeof originalRender === 'function') {
    window.render = function(...args) {
      const result = originalRender.apply(this, args);
      queueMicrotask(patchPrinterSettingsUi);
      return result;
    };
  }

  window.savePrinterSettings = function() {
    const ip = currentPrinterIp();
    window.state.printer = {
      ...(window.state.printer || {}),
      ip,
      port: NETWORK_PORT,
      bridgeUrl: '',
      enabled: !!document.getElementById('printer-enabled')?.checked,
      autoPrint: !!document.getElementById('printer-auto')?.checked
    };
    window.saveKey?.('printer', window.state.printer);
    window.render?.();
    window.flash?.('Настройки принтера сохранены');
  };

  window.testPrinterConnection = function() {
    const ip = currentPrinterIp();
    if (!ip) {
      window.flash?.('Введите IP-адрес принтера');
      return;
    }
    if (window.state?.printer) {
      window.state.printer.ip = ip;
      window.state.printer.port = NETWORK_PORT;
      window.state.printer.bridgeUrl = '';
      window.saveKey?.('printer', window.state.printer);
    }
    window.flash?.('Проверяем принтер…');
    printerPost({
      action: 'print',
      order: {
        __networkPrinterIp: ip,
        __networkPrinterPort: NETWORK_PORT,
        __networkTest: true
      }
    });
  };

  window.sendOrderToPrint = async function(order) {
    const p = window.state?.printer || {};
    if (!p.enabled || !p.ip) return;
    printerPost({ action: 'print', order: networkOrder(order, p.ip) });
  };

  const originalPrintReceipt = window.printReceipt;
  window.printReceipt = function(orderId) {
    const p = window.state?.printer || {};
    const order = window.state?.orders?.find?.(item => item.id === orderId);
    if (p.enabled && p.ip && order) {
      printerPost({ action: 'print', order: networkOrder(order, p.ip) });
      return;
    }
    return originalPrintReceipt?.(orderId);
  };

  window.__nativePrinterEvent = function(event) {
    if (!event) return;
    if (event.type === 'printed') {
      window.flash?.(event.message || 'Чек отправлен на принтер');
      return;
    }
    if (event.status === 'network_connected') {
      window.flash?.(`Принтер ${event.ip || ''} доступен`);
      return;
    }
    if (event.type === 'printError' || event.status === 'network_error') {
      window.flash?.(event.message || 'Принтер недоступен. Проверьте IP и сеть');
    }
  };

  const observer = new MutationObserver(() => patchPrinterSettingsUi());
  observer.observe(document.documentElement, { childList: true, subtree: true });
  patchPrinterSettingsUi();
})();
