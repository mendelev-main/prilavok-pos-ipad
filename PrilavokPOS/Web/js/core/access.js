/* Offline access authority lives in native Keychain; employee.role is only a legacy label. */
(function () {
  'use strict';
  let snapshot = null, sequence = 0, requests = new Map(), pendingRequest = null;
  const labels = {
    pos:'Касса и продажи','receipts.view':'Просмотр чеков','receipts.print':'Повторная печать чеков','receipts.return':'Возврат чеков',
    'products.view':'Просмотр товаров','products.edit':'Товары, рецептуры и категории','products.delete':'Удаление товаров и категорий',
    'stock.view':'Просмотр склада и поставок','stock.edit':'Остатки, заказы и приёмка','shifts.view':'Просмотр смен','shifts.manage':'Открытие и закрытие смен',
    'cash.manage':'Внесение и изъятие наличных','analytics.view':'Аналитика','analytics.export':'Экспорт отчётов',
    'settings.view':'Просмотр настроек','settings.edit':'Изменение настроек','network.manage':'Сеть и ручная синхронизация','bookings':'Бронирования','backup.export':'Резервная копия'
  };
  const esc = value => escapeHtml(String(value ?? ''));
  const arg = value => escapeAttr(JSON.stringify(String(value ?? '')));
  function native(action, data = {}) {
    return new Promise((resolve,reject) => {
      const bridge = window.webkit?.messageHandlers?.ownerAccess;
      if (!bridge) return reject(new Error('Управление доступом доступно в приложении на iPad'));
      const requestId = 'access-' + (++sequence);
      const timer = setTimeout(() => { requests.delete(requestId);reject(new Error('Проверка не завершена. Повторите действие.')); },300000);
      requests.set(requestId,{resolve,reject,timer});
      bridge.postMessage({...data,action,requestId});
    });
  }
  function accept(data) { if (typeof data?.configured === 'boolean') snapshot = data;return data; }
  async function call(action,data) { try{return accept(await native(action,data));}catch(e){if(['login','authorize'].includes(action))api.didLock();throw e;} }
  function can(permission) {
    if (!snapshot) return false;
    if (snapshot.configured && (!snapshot.actorId || Date.now() >= snapshot.expiresAt)) return false;
    return snapshot.isOwner || snapshot.permissions.includes(permission);
  }
  function requirePermission(permission) {
    if (can(permission)) return true;
    flash(snapshot?.configured ? 'Войдите под сотрудником с правом «'+(labels[permission]||'Управление владельцем')+'»' : 'Сначала настройте владельца в Настройки → Владелец и доступ');
    return false;
  }
  async function run(fn) {
    if (pendingRequest) return;
    pendingRequest = true;
    try { return await fn(); } catch(e) { flash(e.message || 'Не удалось проверить доступ'); }
    finally { pendingRequest = false; }
  }
  function roleLabel(id) {
    const account=snapshot?.accounts.find(a=>a.id===id);
    if (!account) return 'Доступ не назначен';
    return account.id===snapshot.ownerId ? 'Owner' : snapshot.roles.find(r=>r.id===account.roleId)?.name || 'Роль не найдена';
  }
  // Merge display records only. Privileges are never imported from POS backups.
  function employeeLabels(employees) {
    if (!snapshot?.configured) return employees;
    const next=employees.map(e=>({...e}));
    for (const a of snapshot.accounts) {
      let employee=next.find(e=>e.id===a.id);
      if (!employee) { employee={id:a.id,phone:''};next.push(employee); }
      employee.name=a.name;employee.role=a.roleId==='owner'||a.roleId==='admin'?'admin':'employee';
    }
    return next;
  }
  async function mergeAccounts() {
    const next=employeeLabels(state.employees);
    if (JSON.stringify(next)!==JSON.stringify(state.employees)) {
      await window.PrilavokCore.Storage.set('employees',next);state.employees=next;
    }
  }
  function panelHTML() {
    if (!snapshot) return '<p>Защищённое хранилище недоступно. Разблокируйте iPad и повторите проверку.</p><button class="btn btn-primary" onclick="POSAccess.open()">Повторить</button>';
    const accountOptions=state.employees.map(e=>`<option value="${esc(e.id)}">${esc(e.name)}</option>`).join('');
    let html=`<p class="setting-sub">${snapshot.actorId?'Вы вошли: '+esc(snapshot.actorName)+' · '+esc(roleLabel(snapshot.actorId)):'Вход не выполнен'}</p>`;
    if (!snapshot.configured) {
      html+=`<p>Один владелец управляет ролями и доступом на этом iPad.</p><div class="field"><label>Сотрудник</label><select id="owner-employee"><option value="">Новый сотрудник</option>${accountOptions}</select></div><div class="field"><label>ФИО нового владельца</label><input id="owner-name" maxlength="120" autocomplete="name"></div><div class="field"><label>Telegram ID владельца · необязательно</label><input id="owner-telegram-id" inputmode="numeric" maxlength="20"></div><p class="setting-sub">PIN хранится на этом iPad. Восстановление забытого PIN не предусмотрено. Сохраните его в надёжном месте.</p><button class="btn btn-primary" onclick="POSAccess.createOwner()">Создать владельца</button>`;
    } else {
      html+=`<div class="setting-row"><span>Telegram владельца</span><b>${esc(snapshot.telegramId||"Не указан")}</b></div><div class="modal-actions"><button class="btn btn-primary" onclick="POSAccess.login()">Войти / сменить сотрудника</button><button class="btn btn-secondary" onclick="POSAccess.logout()">Выйти</button></div>`;
      if (snapshot.isOwner && can('owner.manage')) {
        html+=`<div class="access-card"><h3>Сотрудники</h3>${state.employees.map(e=>`<div class="setting-row"><span>${esc(employeeDisplayName(e.name))}<small style="display:block;color:var(--muted)">${esc(roleLabel(e.id))}</small></span>${e.id===snapshot.ownerId?'<b>Owner</b>':`<button class="btn btn-secondary" onclick="POSAccess.employee(${arg(e.id)})">Изменить</button>`}</div>`).join('')}<button class="btn btn-primary" onclick="POSAccess.employee()">Добавить сотрудника</button></div>`;
        html+=`<div class="access-card"><h3>Роли и права</h3>${snapshot.roles.map(r=>`<div class="setting-row"><b>${esc(r.name)}</b><button class="btn btn-secondary" onclick="POSAccess.role(${arg(r.id)})">Настроить</button></div>`).join('')}<button class="btn btn-primary" onclick="POSAccess.role()">Создать роль</button></div>`;
      }
    }
    return html;
  }
  function showPanel() { showModal(`<div class="modal-title">Владелец и доступ</div><div style="max-height:68vh;overflow:auto">${panelHTML()}</div><div class="modal-actions"><button class="btn btn-secondary" onclick="closeModal()">Закрыть</button></div>`,true); }
  const api = {
    can,require:requirePermission,roleLabel,employeeLabels,
    matchesActor(id){return !!snapshot && (!snapshot.configured||snapshot.actorId===id && Date.now()<snapshot.expiresAt);},
    reply(message) {
      const request=requests.get(message.requestId);if(!request)return;
      requests.delete(message.requestId);clearTimeout(request.timer);
      if(message.error) request.reject(new Error(message.error));else request.resolve(message.data);
    },
    async initialize() { try { await Promise.race([call('status'),new Promise((_,reject)=>setTimeout(()=>reject(new Error('Модуль доступа не ответил. Перезапустите приложение.')),5000))]); } catch(e) { flash(e.message); } },
    async reconcile() { try { await mergeAccounts(); } catch(e) { markStorageBroken(e); } },
    didLock() { if(snapshot?.configured){snapshot.actorId='';snapshot.isOwner=false;snapshot.permissions=[];snapshot.expiresAt=0;}if(state.loaded)render(); },
    open() { return run(async()=>{await call('status');showPanel();}); },
    login() { return run(async()=>{await call('login');await mergeAccounts();render();showPanel();}); },
    logout() { return run(async()=>{await call('logout');render();showPanel();}); },
    createOwner() { return run(async()=>{
      const employeeId=document.getElementById('owner-employee')?.value||'';
      const employee=state.employees.find(e=>e.id===employeeId);
      const name=employee?.name||document.getElementById('owner-name')?.value?.trim()||'';
      const telegramId=document.getElementById('owner-telegram-id')?.value?.trim()||'';
      if(!name)throw new Error('Укажите ФИО владельца');
      await call('createOwner',{employeeId:employeeId||uid(),name,telegramId});
      await mergeAccounts();render();showPanel();flash('Владелец создан. Сохраните PIN: восстановления нет.');
    }); },
    employee(id='') { if(!requirePermission('owner.manage'))return;
      if(id===snapshot.ownerId)return flash('Владелец защищён от удаления и смены роли');
      const employee=state.employees.find(e=>e.id===id),account=snapshot.accounts.find(a=>a.id===id);
      showModal(`<div class="modal-title">${employee?'Сотрудник':'Новый сотрудник'}</div><div class="field"><label>ФИО</label><input id="access-name" maxlength="120" value="${esc(employee?.name)}"></div><div class="field"><label>Телефон</label><input id="access-phone" type="tel" value="${esc(employee?.phone)}"></div><div class="field"><label>Роль</label><select id="access-role">${snapshot.roles.map(r=>`<option value="${esc(r.id)}" ${r.id===(account?.roleId||'employee')?'selected':''}>${esc(r.name)}</option>`).join('')}</select></div><p class="setting-sub">При сохранении задайте личный PIN сотрудника на iPad.</p><div class="modal-actions"><button class="btn btn-secondary" onclick="POSAccess.open()">Назад</button><button class="btn btn-primary" onclick="POSAccess.saveEmployee(${arg(id)})">Сохранить и задать PIN</button></div>${employee?`<button class="btn btn-danger" style="margin-top:16px" onclick="POSAccess.deleteEmployee(${arg(id)})">Удалить сотрудника</button>`:''}`);
    },
    saveEmployee(id='') { return run(async()=>{
      const name=document.getElementById('access-name').value.trim(),phone=document.getElementById('access-phone').value.trim(),roleId=document.getElementById('access-role').value;
      if(!name)throw new Error('Введите ФИО');
      id=id||uid();await call('saveAccount',{id,name,roleId});await mergeAccounts();
      const next=state.employees.map(e=>e.id===id?{...e,phone}:e);await window.PrilavokCore.Storage.set('employees',next);state.employees=next;render();showPanel();
    }); },
    deleteEmployee(id) { if(!requirePermission('owner.manage'))return;
      if(id===snapshot.ownerId||id===snapshot.actorId||id===currentShift()?.employeeId)return flash('Нельзя удалить владельца, себя или сотрудника открытой смены');
      showModal(`<div class="modal-title">Удалить сотрудника?</div><p>История чеков и смен сохранится.</p><div class="modal-actions"><button class="btn btn-secondary" onclick="POSAccess.open()">Отмена</button><button class="btn btn-danger" onclick="POSAccess.confirmDeleteEmployee(${arg(id)})">Удалить</button></div>`);
    },
    confirmDeleteEmployee(id) { return run(async()=>{
      if(id===currentShift()?.employeeId)throw new Error('Нельзя удалить сотрудника открытой смены');
      // Revoke protected access first; a failed local display write cannot leave access active.
      await call('deleteAccount',{id});const next=state.employees.filter(e=>e.id!==id);await window.PrilavokCore.Storage.set('employees',next);state.employees=next;render();showPanel();
    }); },
    role(id='') { if(!requirePermission('owner.manage'))return;
      const role=snapshot.roles.find(r=>r.id===id);
      showModal(`<div class="modal-title">${role?'Права роли':'Новая роль'}</div><div class="field"><label>Название</label><input id="access-role-name" maxlength="80" value="${esc(role?.name)}"></div><div style="max-height:50vh;overflow:auto">${Object.entries(labels).map(([p,label])=>`<label class="setting-row" style="min-height:44px"><span>${esc(label)}</span><input class="access-permission" type="checkbox" value="${p}" ${role?.permissions.includes(p)?'checked':''}></label>`).join('')}</div><div class="modal-actions"><button class="btn btn-secondary" onclick="POSAccess.open()">Назад</button><button class="btn btn-primary" onclick="POSAccess.saveRole(${arg(id)})">Сохранить</button></div>${id&&!['admin','employee'].includes(id)?`<button class="btn btn-danger" style="margin-top:12px" onclick="POSAccess.deleteRole(${arg(id)})">Удалить роль</button>`:''}`,true);
    },
    saveRole(id) { return run(async()=>{await call('saveRole',{id:id||uid(),name:document.getElementById('access-role-name').value.trim(),permissions:[...document.querySelectorAll('.access-permission:checked')].map(e=>e.value)});render();showPanel();}); },
    deleteRole(id) { return run(async()=>{await call('deleteRole',{id});showPanel();}); },
    authorizeShift(callback) { return run(async()=>{
      const employeeId=document.getElementById('sf-employee')?.value||'';if(!employeeId)throw new Error('Выберите сотрудника');
      await call('authorize',{permission:'shifts.manage',employeeId});callback();
    }); },
    async authorizeTab(permission,callback) { return run(async()=>{await call('authorize',{permission});callback();}); }
  };
  window.POSAccess=api;
})();
