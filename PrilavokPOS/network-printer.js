(() => {
  const NETWORK_PORT = 9100;
  const STORAGE_KEY = 'printers';
  const DEFAULTS = {
    paperWidth: 80,
    printMode: 'graphic',
    printWidth: 'auto',
    dpi: 203,
    initCommand: '1B,40',
    cutCommand: '1D,56,42,00',
    drawerCommand: '1B,70,00,19,FA',
    printReceipts: true,
    printOrders: false,
    enabled: true
  };

  const esc = s => window.escapeHtml?.(String(s ?? '')) || String(s ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const uid = () => 'printer-' + Date.now().toString(36) + '-' + Math.random().toString(36).slice(2,7);
  const normalize = p => ({...DEFAULTS, ...p, id:p?.id || uid(), name:p?.name || 'Чековый принтер', ip:(p?.ip || '').trim(), port:NETWORK_PORT});

  function loadPrinters(){
    let list = [];
    try { list = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]'); } catch(_) {}
    if (!Array.isArray(list)) list=[];
    if (!list.length && window.state?.printer?.ip) {
      list=[normalize({name:'Чековый принтер', ip:window.state.printer.ip, enabled:window.state.printer.enabled !== false, printReceipts:true})];
      savePrinters(list, false);
    }
    return list.map(normalize);
  }
  function savePrinters(list, rerender=true){
    const clean=list.map(normalize);
    localStorage.setItem(STORAGE_KEY, JSON.stringify(clean));
    if(window.state) window.state.printers=clean;
    if(rerender) window.render?.();
    return clean;
  }
  function printerPost(payload){
    const h=window.webkit?.messageHandlers?.printer;
    if(!h){ window.flash?.('Сетевой модуль печати доступен только в приложении на iPad'); return false; }
    h.postMessage(payload); return true;
  }
  function info(title,text){
    window.showModal?.(`<div class="modal-title">${esc(title)}</div><div class="settings-note" style="line-height:1.6">${text}</div><div class="modal-actions"><button class="btn btn-primary" onclick="closeModal()">Понятно</button></div>`);
  }
  window.printerInfo=(key)=>{
    const data={
      list:['Принтеры','Добавьте один или несколько сетевых чековых принтеров. Каждый принтер может отдельно печатать чеки/счета и заказы.'],
      name:['Название принтера','Понятное название устройства внутри POS, например «Касса», «Кухня» или «Бар».'],
      ip:['IP-адрес','Локальный IP-адрес принтера. iPad и принтер должны быть в одной сети. Пример: <b>192.168.1.105</b>. Порт 9100 используется автоматически.'],
      paper:['Ширина бумаги','Выберите фактическую ширину рулона: 58 или 80 мм. От неё зависит компоновка чека.'],
      mode:['Режим печати','<b>Графический</b> — стабильный внешний вид, кириллица и сложная верстка. <b>Текстовый</b> — быстрые ESC/POS-команды для совместимых принтеров.'],
      width:['Ширина печати','Фактическая печатная область. «Автоматически» использует подходящее значение для выбранной бумаги. 64/72 мм нужны для тонкой настройки конкретной модели.'],
      dpi:['Разрешение печати','Плотность термоголовки принтера. Большинство современных чековых принтеров используют 203 dpi (8 точек/мм).'],
      init:['ESC/POS: инициализация','Команда сброса/инициализации принтера перед печатью. Стандартное значение: <b>1B,40</b>. Не меняйте без необходимости.'],
      cut:['ESC/POS: обрезчик','Команда автоматической обрезки бумаги после чека. Стандарт: <b>1D,56,42,00</b>.'],
      drawer:['ESC/POS: денежный ящик','Команда открытия денежного ящика, физически подключённого к принтеру. Стандарт: <b>1B,70,00,19,FA</b>.'],
      receipts:['Печатать чеки и счета','Этот принтер будет получать оплаченные чеки и счета. Можно включить на нескольких принтерах одновременно.'],
      orders:['Печатать заказы','Этот принтер будет получать производственные/кухонные заказы. Удобно для отдельного принтера на кухне или баре.']
    };
    const x=data[key]; if(x) info(x[0],x[1]);
  };

  function iButton(key){ return `<button type="button" onclick="event.stopPropagation();printerInfo('${key}')" style="width:26px;height:26px;border-radius:50%;border:1px solid var(--line);background:var(--card);font-weight:900;color:var(--muted);cursor:pointer">i</button>`; }

  window.openPrintersManager=()=>{
    const list=loadPrinters();
    const cards=list.length ? list.map(p=>`<button class="btn" onclick="openPrinterEditor('${p.id}')" style="width:100%;height:auto;padding:15px 16px;display:flex;align-items:center;justify-content:space-between;text-align:left;margin-bottom:10px"><span><b style="font-size:15px">${esc(p.name)}</b><br><span class="setting-sub">${esc(p.ip || 'IP не указан')} · ${p.paperWidth} мм · ${p.printMode==='graphic'?'Графический':'Текстовый'}</span></span><span style="font-size:20px">›</span></button>`).join('') : '<div class="settings-note">Принтеры пока не добавлены.</div>';
    window.showModal?.(`<div class="modal-title" style="display:flex;align-items:center;gap:8px">Принтеры ${iButton('list')}</div><div style="margin-top:14px">${cards}</div><div class="modal-actions"><button class="btn" onclick="closeModal()">Закрыть</button><button class="btn btn-primary" onclick="openPrinterEditor()">Добавить принтер</button></div>`);
  };

  window.openPrinterEditor=(id)=>{
    const existing=loadPrinters().find(p=>p.id===id); const p=normalize(existing||{});
    const row=(label,key,control)=>`<div class="field" style="margin-bottom:13px"><label style="display:flex;align-items:center;justify-content:space-between;gap:8px"><span>${label}</span>${iButton(key)}</label>${control}</div>`;
    const html=`<div class="modal-title">${existing?'Настройки принтера':'Добавить принтер'}</div>
      <input type="hidden" id="mp-id" value="${esc(existing?.id||'')}">
      ${row('Название','name',`<input id="mp-name" value="${esc(p.name)}" placeholder="Например, Касса">`)}
      ${row('IP-адрес','ip',`<input id="mp-ip" inputmode="decimal" value="${esc(p.ip)}" placeholder="192.168.1.105">`)}
      ${row('Ширина бумаги','paper',`<select id="mp-paper"><option value="58" ${p.paperWidth==58?'selected':''}>58 мм</option><option value="80" ${p.paperWidth==80?'selected':''}>80 мм</option></select>`)}
      <details style="border:1px solid var(--line);border-radius:14px;padding:12px 14px;margin:14px 0"><summary style="font-weight:800;cursor:pointer">Дополнительные настройки</summary><div style="padding-top:14px">
        ${row('Режим печати','mode',`<select id="mp-mode"><option value="graphic" ${p.printMode==='graphic'?'selected':''}>Графический</option><option value="text" ${p.printMode==='text'?'selected':''}>Текстовый</option></select>`)}
        ${row('Ширина печати','width',`<select id="mp-width"><option value="auto" ${p.printWidth==='auto'?'selected':''}>Автоматически</option><option value="64" ${p.printWidth==='64'?'selected':''}>64 мм</option><option value="72" ${p.printWidth==='72'?'selected':''}>72 мм</option></select>`)}
        ${row('Разрешение печати','dpi',`<select id="mp-dpi"><option value="203" ${p.dpi==203?'selected':''}>203 dpi (8 точек/мм)</option><option value="180" ${p.dpi==180?'selected':''}>180 dpi (7,1 точки/мм)</option></select>`)}
        ${row('ESC/POS команды инициализации','init',`<input id="mp-init" value="${esc(p.initCommand)}">`)}
        ${row('ESC/POS команды обрезчика','cut',`<input id="mp-cut" value="${esc(p.cutCommand)}">`)}
        ${row('ESC/POS команды денежного ящика','drawer',`<input id="mp-drawer" value="${esc(p.drawerCommand)}">`)}
      </div></details>
      <div class="setting-row"><div><div class="setting-title" style="display:flex;gap:8px;align-items:center">Печатать чеки и счета ${iButton('receipts')}</div></div><label class="switch"><input id="mp-receipts" type="checkbox" ${p.printReceipts?'checked':''}><span></span></label></div>
      <div class="setting-row"><div><div class="setting-title" style="display:flex;gap:8px;align-items:center">Печатать заказы ${iButton('orders')}</div></div><label class="switch"><input id="mp-orders" type="checkbox" ${p.printOrders?'checked':''}><span></span></label></div>
      <div class="modal-actions" style="justify-content:space-between"><div>${existing?'<button class="btn" style="color:#d33" onclick="deletePrinter(\''+p.id+'\')">Удалить</button>':''}</div><div style="display:flex;gap:8px"><button class="btn" onclick="testPrinterFromEditor()">Пробная печать</button><button class="btn btn-primary" onclick="savePrinterFromEditor()">Сохранить</button></div></div>`;
    window.showModal?.(html);
  };

  function editorValue(id){return document.getElementById(id)?.value?.trim()||'';}
  function editorPrinter(){
    return normalize({id:editorValue('mp-id')||uid(),name:editorValue('mp-name')||'Чековый принтер',ip:editorValue('mp-ip'),paperWidth:Number(editorValue('mp-paper'))||80,printMode:editorValue('mp-mode')||'graphic',printWidth:editorValue('mp-width')||'auto',dpi:Number(editorValue('mp-dpi'))||203,initCommand:editorValue('mp-init'),cutCommand:editorValue('mp-cut'),drawerCommand:editorValue('mp-drawer'),printReceipts:!!document.getElementById('mp-receipts')?.checked,printOrders:!!document.getElementById('mp-orders')?.checked});
  }
  window.savePrinterFromEditor=()=>{ const p=editorPrinter(); if(!p.ip){window.flash?.('Введите IP-адрес принтера');return;} let list=loadPrinters(); const i=list.findIndex(x=>x.id===p.id); if(i>=0)list[i]=p;else list.push(p); savePrinters(list,false); window.closeModal?.(); window.flash?.('Принтер сохранён'); window.render?.(); };
  window.deletePrinter=(id)=>{ savePrinters(loadPrinters().filter(p=>p.id!==id),false); window.closeModal?.(); window.flash?.('Принтер удалён'); window.render?.(); };
  window.testPrinterFromEditor=()=>{ const p=editorPrinter(); if(!p.ip){window.flash?.('Введите IP-адрес принтера');return;} window.flash?.('Отправляем пробную печать…'); printerPost({action:'print',order:{__networkPrinterIp:p.ip,__networkPrinterPort:NETWORK_PORT,__networkTest:true,__printerConfig:p}}); };

  function decorateSettings(){
    const port=document.getElementById('printer-port'); if(!port)return;
    const anchor=port.closest('.settings-card')||port.parentElement?.parentElement;
    if(!anchor||anchor.dataset.multiPrinter==='1')return;
    anchor.dataset.multiPrinter='1';
    anchor.innerHTML=`<div style="display:flex;align-items:center;justify-content:space-between;gap:12px"><div><div class="setting-title" style="display:flex;align-items:center;gap:8px">Чековые принтеры ${iButton('list')}</div><div class="setting-sub">Добавляйте несколько принтеров и назначайте, что печатает каждый из них.</div></div><button class="btn btn-primary" onclick="openPrintersManager()">Принтеры</button></div><div style="margin-top:12px" class="printer-status"><span class="dot ${loadPrinters().length?'on':'off'}"></span>${loadPrinters().length?`Настроено: ${loadPrinters().length}`:'Принтеры не настроены'}</div>`;
  }

  const originalRender=window.render;
  if(typeof originalRender==='function') window.render=function(...a){const r=originalRender.apply(this,a);queueMicrotask(decorateSettings);return r;};

  function configuredFor(kind){return loadPrinters().filter(p=>p.enabled!==false && p.ip && (kind==='orders'?p.printOrders:p.printReceipts));}
  function networkOrder(order,p){return {...(order||{}),currency:order?.currency||window.state?.currency||'BYN',__networkPrinterIp:p.ip,__networkPrinterPort:NETWORK_PORT,__printerConfig:p};}
  window.sendOrderToPrint=async order=>{configuredFor('receipts').forEach(p=>printerPost({action:'print',order:networkOrder(order,p)}));};
  window.sendKitchenOrderToPrint=order=>{configuredFor('orders').forEach(p=>printerPost({action:'print',order:networkOrder(order,p)}));};
  const originalPrintReceipt=window.printReceipt;
  window.printReceipt=function(orderId){const order=window.state?.orders?.find?.(o=>o.id===orderId);const ps=configuredFor('receipts');if(order&&ps.length){ps.forEach(p=>printerPost({action:'print',order:networkOrder(order,p)}));return;}return originalPrintReceipt?.(orderId);};

  window.__nativePrinterEvent=e=>{if(!e)return;if(e.type==='printed'||e.status==='network_connected')window.flash?.(e.message||`Принтер ${e.ip||''} доступен`);else if(e.type==='printError'||e.status==='network_error')window.flash?.(e.message||'Принтер недоступен. Проверьте IP и сеть');};
  if(window.state) window.state.printers=loadPrinters();
  new MutationObserver(decorateSettings).observe(document.documentElement,{childList:true,subtree:true});
  decorateSettings();
})();
