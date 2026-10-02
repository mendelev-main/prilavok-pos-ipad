/* Inventory runtime. Compatibility globals are intentional during gradual migration. */
function inventoryDateOnly(value){if(!value)return null;const d=value instanceof Date?new Date(value):new Date(String(value).length===10?value+'T00:00:00':value);if(Number.isNaN(d.getTime()))return null;return new Date(d.getFullYear(),d.getMonth(),d.getDate());}
function inventoryPeriodStart(date=new Date(),frequency=state.inventoryConfig?.frequency){
 const d=inventoryDateOnly(date)||inventoryDateOnly(new Date());
 if(frequency==='weekly'){const day=(d.getDay()+6)%7;const start=new Date(d);start.setDate(d.getDate()-day);return start;}
 if(frequency==='quarterly')return new Date(d.getFullYear(),Math.floor(d.getMonth()/3)*3,1);
 return new Date(d.getFullYear(),d.getMonth(),1);
}
function inventoryPeriodEnd(start,frequency=state.inventoryConfig?.frequency){
 const s=inventoryDateOnly(start);if(!s)return null;
 if(frequency==='weekly'){const e=new Date(s);e.setDate(e.getDate()+6);return e;}
 if(frequency==='quarterly')return new Date(s.getFullYear(),s.getMonth()+3,0);
 return new Date(s.getFullYear(),s.getMonth()+1,0);
}
function inventoryWindow(){
 const c=state.inventoryConfig||{};if(!c.enabled||!c.productIds?.length)return null;
 const frequency=['weekly','monthly','quarterly'].includes(c.frequency)?c.frequency:'monthly',today=inventoryDateOnly(new Date()),start=inventoryPeriodStart(today,frequency),windowEnd=new Date(start);windowEnd.setDate(start.getDate()+6);
 const periodEnd=inventoryPeriodEnd(start,frequency);if(windowEnd>periodEnd)windowEnd.setTime(periodEnd.getTime());
 const last=inventoryDateOnly(c.lastCompletedAt),completed=!!(last&&last>=start&&last<=periodEnd);
 return {frequency,start,end:windowEnd,periodEnd,today,active:today>=start&&today<=windowEnd&&!completed,completed};
}
function inventoryNextDate(){
 const w=inventoryWindow();if(!w)return null;if(w.active)return w.start;
 const next=new Date(w.start);
 if(w.frequency==='weekly')next.setDate(next.getDate()+7);
 else if(w.frequency==='quarterly')next.setMonth(next.getMonth()+3);
 else next.setMonth(next.getMonth()+1);
 return next;
}
function inventoryDaysUntil(){const w=inventoryWindow();if(w?.active)return 0;const n=inventoryNextDate();return n?Math.ceil((n-inventoryDateOnly(new Date()))/86400000):null;}
function renderInventoryTopbarReminder(){const w=inventoryWindow();if(!state.inventoryDraft&&!w?.active)return '';return '<button class="tab '+(state.tab==='inventoryWork'?'active':'')+'" style="color:#FFD86B;background:rgba(255,216,107,.1);white-space:nowrap;" onclick="openInventoryWork()">Инвентаризация</button>';}
function inventoryTrackedProducts(){const ids=new Set(state.inventoryConfig?.productIds||[]);return state.products.filter(p=>ids.has(p.id)&&productTracksStock(p));}
function setInventoryFrequency(v){state.inventoryConfig.frequency=['weekly','monthly','quarterly'].includes(v)?v:'monthly';render();}
function filterInventoryProducts(value){
 const q=String(value||'').trim().toLocaleLowerCase('ru');document.querySelectorAll('[data-inventory-product-row]').forEach(row=>{row.style.display=!q||String(row.dataset.inventoryProductName||'').includes(q)?'flex':'none';});
}
function saveInventorySettings(){
 const productIds=[...document.querySelectorAll('[data-inventory-product]:checked')].map(x=>x.value);
 if(!productIds.length){flash('Выберите хотя бы один товар');return;}
 const frequency=['weekly','monthly','quarterly'].includes(state.inventoryConfig.frequency)?state.inventoryConfig.frequency:'monthly';
 state.inventoryConfig={...state.inventoryConfig,enabled:true,frequency,productIds};
 delete state.inventoryConfig.monthDay;delete state.inventoryConfig.customDates;
 saveKey('inventoryConfig',state.inventoryConfig);render();flash('Настройки инвентаризации сохранены');
}
function startInventory(type='scheduled'){
 const ps=inventoryTrackedProducts();if(!ps.length){flash('Нет товаров для инвентаризации');return false;}
 state.inventoryDraft={id:uid(),type,startedAt:Date.now(),scheduledDate:type==='adhoc'?Date.now():(inventoryWindow()?.start||inventoryDateOnly(new Date())).getTime(),items:ps.map(p=>({productId:p.id,name:p.name,unit:stockUnit(p),expected:roundStockQty(Number(p.stock)||0),actual:null}))};
 saveKey('inventoryDraft',state.inventoryDraft);return true;
}
function openInventoryWork(){if(!state.inventoryDraft&&!startInventory('scheduled'))return;state.tab='inventoryWork';render();}
function startAdhocInventory(){
 if(state.inventoryDraft){state.tab='inventoryWork';render();flash('Сначала завершите текущую инвентаризацию');return;}
 if(!startInventory('adhoc'))return;state.tab='inventoryWork';render();
}
function updateInventoryActual(id,v){const x=state.inventoryDraft?.items.find(i=>i.productId===id);if(!x||x.fixedAt)return;const n=Number(String(v).replace(',','.'));x.actual=Number.isFinite(n)&&n>=0?roundStockQty(n):null;saveKey('inventoryDraft',state.inventoryDraft);}
async function fixInventoryItem(id){
 if(criticalOperationBusy){flash('Сохранение операции ещё не завершено');return false;}
 const d=state.inventoryDraft,x=d?.items.find(i=>i.productId===id);if(!x||x.fixedAt)return false;
 const actual=Number(x.actual);if(x.actual===null||!Number.isFinite(actual)||actual<0){flash('Введите корректный остаток товара');return false;}
 const p=getProduct(x.productId);if(!productTracksStock(p)){flash('Для товара недоступен учёт остатков');return false;}
 const nextProducts=storageSnapshot(state.products),nextDraft=storageSnapshot(d),nextProduct=nextProducts.find(item=>item.id===p.id),nextItem=nextDraft.items.find(item=>item.productId===id);
 nextItem.expected=roundStockQty(Number(nextProduct.stock)||0);nextItem.actual=roundStockQty(actual);nextItem.difference=roundStockQty(nextItem.actual-nextItem.expected);nextItem.fixedAt=Date.now();nextProduct.stock=nextItem.actual;
 criticalOperationBusy=true;
 try{await commitCriticalStorage('inventory-fix',{products:nextProducts,inventoryDraft:nextDraft})}
 catch(e){flash('Остаток не зафиксирован: '+(e?.message||e));return false}
 finally{criticalOperationBusy=false}
 state.products=nextProducts;state.inventoryDraft=nextDraft;void publishAvailability();render();flash('Остаток зафиксирован');return true;
}
function requestCancelInventory(){
 if(!state.inventoryDraft)return;
 if(!currentShiftEmployeeIsAdmin()){flash('Отменить инвентаризацию может только администратор');return;}
 showModal(`<div class="modal-title">Отменить инвентаризацию?</div>
   <div class="center-note" style="padding:4px 0 14px;text-align:left;">Текущая инвентаризация будет отменена. Введённые и зафиксированные в ней данные не будут сохранены.</div>
   <div class="modal-actions"><button class="btn btn-secondary" onclick="closeModal()">Нет, продолжить</button><button class="btn btn-danger" onclick="confirmCancelInventory()">Да, отменить</button></div>`,true);
}
function confirmCancelInventory(){
 if(!currentShiftEmployeeIsAdmin()){closeModal();flash('Отменить инвентаризацию может только администратор');return;}
 if(!state.inventoryDraft){closeModal();return;}
 state.inventoryDraft=null;
 saveKey('inventoryDraft',null);
 closeModal();
 state.tab='inventory';
 render();
 flash('Инвентаризация отменена');
}
function pauseInventory(){saveKey('inventoryDraft',state.inventoryDraft);state.tab='pos';render();flash('Инвентаризация сохранена. Можно продолжить позже');}
function completeInventory(){
 const d=state.inventoryDraft;if(!d)return;if(d.items.some(x=>!x.fixedAt)){flash('Сначала зафиксируйте остаток каждого товара');return;}
 showInventorySummary();
}
function inventorySummaryData(){
 const d=state.inventoryDraft;if(!d)return {rows:[],loss:0,shortages:0,surpluses:0};
 let loss=0,shortages=0,surpluses=0;
 const rows=d.items.map(x=>{const p=getProduct(x.productId),difference=roundStockQty(Number(x.difference||0)),cost=Number(p?.cost)||0,lossAmount=difference<0?Math.abs(difference)*cost:0;if(difference<0)shortages++;if(difference>0)surpluses++;loss+=lossAmount;return {...x,difference,cost,lossAmount};});
 return {rows,loss,shortages,surpluses};
}
function showInventorySummary(){
 const d=state.inventoryDraft;if(!d)return;
 const summary=inventorySummaryData();
 const changed=summary.rows.filter(x=>x.difference!==0);
 showModal(`<div class="modal-title">Сводка инвентаризации</div>
   <div class="grid-3" style="margin-bottom:14px;">
     <div class="stat-box"><div class="label">Недостачи</div><div class="value">${summary.shortages}</div></div>
     <div class="stat-box"><div class="label">Излишки</div><div class="value">${summary.surpluses}</div></div>
     <div class="stat-box"><div class="label">Примерный убыток</div><div class="value">${money(summary.loss)}</div></div>
   </div>
   <div style="max-height:46vh;overflow:auto;border-top:1px solid var(--border);">
     ${changed.length?changed.map(x=>`<div class="list-row"><div style="flex:1;min-width:0;"><div class="list-row-name">${escapeHtml(x.name)}</div><div class="setting-sub">Было: ${stockQtyText(x.expected)} ${unitLabel(x.unit)} · Стало: ${stockQtyText(x.actual)} ${unitLabel(x.unit)}</div></div><div style="text-align:right;"><div style="font-weight:850;color:${x.difference<0?'var(--danger)':'var(--accent)'};">${x.difference>0?'+':''}${stockQtyText(x.difference)} ${unitLabel(x.unit)}</div>${x.lossAmount>0?`<div class="setting-sub">≈ −${money(x.lossAmount)}</div>`:''}</div></div>`).join(''):'<div class="center-note">Расхождений нет</div>'}
   </div>
   <div class="modal-actions"><button class="btn btn-secondary" onclick="closeModal()">Вернуться</button><button class="btn btn-primary" onclick="confirmCompleteInventory()">Завершить инвентаризацию</button></div>`,true);
}
async function confirmCompleteInventory(){
 if(criticalOperationBusy){flash('Сохранение операции ещё не завершено');return false;}
 const d=state.inventoryDraft;if(!d)return false;
 if(!Array.isArray(d.items)||!d.items.length||d.items.some(x=>!x.fixedAt)){flash('Сначала зафиксируйте остаток каждого товара');return false;}
 const completedAt=Date.now(),summary=inventorySummaryData(),nextProducts=storageSnapshot(state.products),nextHistory=storageSnapshot(state.inventoryHistory),nextConfig=storageSnapshot(state.inventoryConfig);
 nextHistory.unshift({...storageSnapshot(d),completedAt,estimatedLoss:summary.loss,items:storageSnapshot(d.items)});if(d.type!=='adhoc')nextConfig.lastCompletedAt=completedAt;
 criticalOperationBusy=true;
 try{await commitCriticalStorage('inventory-complete',{products:nextProducts,inventoryHistory:nextHistory,inventoryConfig:nextConfig,inventoryDraft:null})}
 catch(e){flash('Инвентаризация не завершена: '+(e?.message||e));return false}
 finally{criticalOperationBusy=false}
 state.products=nextProducts;state.inventoryHistory=nextHistory;state.inventoryConfig=nextConfig;state.inventoryDraft=null;void publishAvailability();state.tab='pos';closeModal();render();flash('Инвентаризация завершена');return true;
}
function renderInventoryScreen(){
 const c=state.inventoryConfig||{};if(!['weekly','monthly','quarterly'].includes(c.frequency))c.frequency='monthly';
 const tracked=state.products.filter(productTracksStock).sort((a,b)=>a.name.localeCompare(b.name,'ru')),w=inventoryWindow(),next=inventoryNextDate();
 const rows=tracked.map(p=>`<label data-inventory-product-row data-inventory-product-name="${escapeAttr(String(p.name||'').toLocaleLowerCase('ru'))}" class="list-row" style="cursor:pointer;"><input data-inventory-product type="checkbox" value="${escapeAttr(p.id)}" ${(c.productIds||[]).includes(p.id)?'checked':''} style="width:20px;height:20px;"><div style="flex:1;"><div class="list-row-name">${escapeHtml(p.name)}</div><div class="setting-sub">Остаток: ${stockQtyText(p.stock)} ${unitLabel(stockUnit(p))}</div></div></label>`).join('');
 const scheduleText=w?.active?`Окно инвентаризации открыто до ${w.end.toLocaleDateString('ru-RU')} включительно.`:w?.completed?'Инвентаризация в текущем периоде завершена.':next?`Следующее окно начнётся ${next.toLocaleDateString('ru-RU')}.`:'После сохранения настроек окно будет открываться автоматически.';
 return `<div class="screen content-screen ${state.tab==='inventory'?'active':''}"><div class="content-head"><div style="display:flex;align-items:center;gap:12px;"><button class="btn btn-secondary" style="width:auto;padding:10px 16px;" onclick="state.settingsAdminPanel=true;setTab('settings')">← Назад</button><div class="content-title">Инвентаризация</div></div></div><div style="overflow:auto;min-height:0;flex:1;padding-right:4px;">
 <div class="card" style="margin-bottom:16px;"><div style="font-size:17px;font-weight:850;">График</div><div class="setting-sub" style="margin:4px 0 8px;">${scheduleText} На проведение даётся 7 дней с начала периода.</div><div style="font-size:15px;font-weight:800;margin-bottom:16px;">Следующая инвентаризация: ${next?next.toLocaleDateString('ru-RU'):'—'}</div>
 <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin-bottom:12px;"><button class="btn ${c.frequency==='weekly'?'btn-primary':'btn-secondary'}" onclick="setInventoryFrequency('weekly')">Раз в неделю</button><button class="btn ${c.frequency==='monthly'?'btn-primary':'btn-secondary'}" onclick="setInventoryFrequency('monthly')">Раз в месяц</button><button class="btn ${c.frequency==='quarterly'?'btn-primary':'btn-secondary'}" onclick="setInventoryFrequency('quarterly')">Раз в квартал</button></div><button class="btn btn-secondary" style="width:100%;" onclick="startAdhocInventory()">Внеплановая инвентаризация</button></div>
 <div class="card" style="margin-bottom:16px;"><div style="font-size:17px;font-weight:850;">Товары для инвентаризации</div><div class="setting-sub" style="margin:4px 0 12px;">Выберите товары, которые нужно пересчитывать. Товары с остатком ∞ исключены.</div><input type="search" placeholder="Поиск товара" oninput="filterInventoryProducts(this.value)" style="width:100%;padding:11px 14px;border:1px solid var(--border);border-radius:12px;background:var(--surface);color:var(--ink);font:inherit;margin-bottom:10px;"><div style="max-height:360px;overflow:auto;border-top:1px solid var(--border);">${rows||'<div class="center-note">Нет товаров с учётом остатков</div>'}</div><button class="btn btn-primary" style="width:100%;margin-top:14px;" onclick="saveInventorySettings()">Сохранить настройки</button></div>
 <div class="card"><div style="display:flex;align-items:center;justify-content:space-between;gap:12px;margin-bottom:10px;"><div style="font-size:17px;font-weight:850;">История</div></div>${state.inventoryHistory.length?state.inventoryHistory.slice(0,50).map(r=>`<div class="list-row"><div><div class="list-row-name">${fmtDate(r.completedAt)}${r.type==='adhoc'?' · Внеплановая':''}</div><div class="setting-sub">${r.items.length} товаров · расхождений: ${r.items.filter(x=>Number(x.difference)!==0).length} · недостач: ${r.items.filter(x=>Number(x.difference)<0).length}</div></div></div>`).join(''):'<div class="center-note">Инвентаризаций пока не было</div>'}</div></div></div>`;
}

function renderInventoryWorkScreen(){
 const d=state.inventoryDraft;
 if(!d)return `<div class="screen content-screen ${state.tab==='inventoryWork'?'active':''}"><div class="center-note" style="margin:auto;">Нет активной инвентаризации.</div></div>`;
 const isAdmin=currentShiftEmployeeIsAdmin(),fixed=d.items.filter(x=>!!x.fixedAt).length;
 const rows=d.items.map(x=>{
   const unit=unitLabel(x.unit),done=!!x.fixedAt,p=getProduct(x.productId),currentExpected=done?roundStockQty(Number(x.expected)||0):roundStockQty(Number(p?.stock)||0),diff=roundStockQty(Number(x.difference||0)),diffText=diff>0?'+'+stockQtyText(diff):stockQtyText(diff);
   const before=done?`<div class="setting-sub" style="margin-top:5px;">Расчётный остаток: ${stockQtyText(currentExpected)} ${unit}</div><div style="margin-top:5px;font-weight:800;color:${diff<0?'#D95C54':diff>0?'#42A66B':'var(--muted)'};">Разница: ${diffText} ${unit}</div>`:(isAdmin?`<div class="setting-sub">Учётный остаток: ${stockQtyText(currentExpected)} ${unit}</div>`:'');
   const control=done?`<div style="min-width:190px;text-align:right;"><div class="setting-sub">Зафиксированный остаток</div><div style="font-size:18px;font-weight:850;margin-top:4px;">${stockQtyText(x.actual)} ${unit}</div></div>`:`<div style="width:230px;"><div class="setting-sub" style="margin-bottom:5px;">Остаток, ${escapeHtml(unit)}</div><div style="display:flex;gap:8px;"><input type="number" min="0" step="0.001" inputmode="decimal" value="${x.actual===null?'':escapeAttr(String(x.actual))}" placeholder="0" style="min-width:0;flex:1;padding:11px 12px;border:1px solid var(--border);border-radius:11px;background:var(--surface);color:var(--ink);font:inherit;" onchange="updateInventoryActual('${escapeAttr(x.productId)}',this.value)"><button class="btn btn-primary" style="width:auto;padding:0 14px;" onclick="fixInventoryItem('${escapeAttr(x.productId)}')">Фиксировать</button></div></div>`;
   return `<div class="list-row" style="align-items:center;gap:16px;padding-top:14px;padding-bottom:14px;"><div style="flex:1;min-width:0;"><div class="list-row-name">${escapeHtml(x.name)}</div>${before}</div>${control}</div>`;
 }).join('');
 return `<div class="screen content-screen ${state.tab==='inventoryWork'?'active':''}">
   <div class="content-head" style="align-items:center;"><div><div class="content-title">${d.type==='adhoc'?'Внеплановая инвентаризация':'Инвентаризация'}</div><div class="setting-sub">Зафиксировано: ${fixed} из ${d.items.length}</div></div>${isAdmin?'<button class="btn btn-danger" style="width:auto;padding:10px 16px;" onclick="requestCancelInventory()">Отменить инвентаризацию</button>':''}</div>
   <div style="display:flex;flex-direction:column;min-height:0;flex:1;">
     <div class="card" style="flex:1;min-height:0;overflow:auto;padding-top:4px;">${rows||'<div class="center-note">Нет товаров для пересчёта</div>'}</div>
     <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;padding-top:14px;flex:0 0 auto;">
       <button class="btn btn-secondary" style="min-height:50px;" onclick="pauseInventory()">Продолжить позже</button>
       <button class="btn btn-primary" style="min-height:50px;" onclick="completeInventory()">Завершить инвентаризацию</button>
     </div>
   </div>
 </div>`;
}
