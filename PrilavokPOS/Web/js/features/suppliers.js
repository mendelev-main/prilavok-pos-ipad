function openSupplierModal(id=''){
  const supplier = state.suppliers.find(s=>s.id===id);
  const editing = !!supplier;
  const selected = new Set(Array.isArray(supplier?.productIds) ? supplier.productIds : []);
  const products = state.products.filter(p=>p.type==='simple').slice().sort((a,b)=>a.name.localeCompare(b.name,'ru'));
  showModal(`
    <div class="modal-title">${editing?'Товары поставщика':'Новый поставщик'}</div>
    <div class="field">
      <label>Название поставщика</label>
      <input id="sf-name" type="text" value="${escapeAttr(supplier?.name||'')}" placeholder="Например, ООО Поставщик">
    </div>
    <div style="font-weight:800;margin:14px 0 8px;">Товары на поставщике</div>
    <div class="settings-note" style="margin-bottom:10px;">Выберите товары, которые обычно закупаются у этого поставщика. В приёмке они будут показываться первыми.</div>
    <div class="field" style="margin-bottom:10px;"><input id="supplier-product-search" type="search" placeholder="Поиск товара или категории" autocomplete="off" oninput="filterSupplierProducts(this.value)"></div>
    <div id="supplier-product-list" style="max-height:360px;overflow:auto;border:1px solid var(--line);border-radius:12px;padding:6px;">
      ${products.length ? products.map(p=>`<label class="supplier-product-option" data-search="${escapeAttr((p.name+' '+(p.category||'')).toLocaleLowerCase('ru'))}" style="display:flex;align-items:center;gap:10px;padding:10px 8px;border-bottom:1px solid var(--line);cursor:pointer;">
        <input class="supplier-product-check" type="checkbox" value="${escapeAttr(p.id)}" ${selected.has(p.id)?'checked':''} style="width:20px;height:20px;">
        <span style="flex:1;min-width:0;">${escapeHtml(p.name)}</span>
        <span class="list-row-sub">${escapeHtml(p.category||'Без категории')}</span>
      </label>`).join('') : `<div class="center-note">Сначала создайте простые товары.</div>`}
      <div id="supplier-product-search-empty" class="center-note" style="display:none;">Товары не найдены.</div>
    </div>
    <div class="modal-actions">
      <button class="btn btn-secondary" onclick="closeModal()">Отмена</button>
      <button id="supplier-save-confirm" class="btn btn-primary" onclick="saveSupplier('${escapeAttr(id)}')">${editing?'Сохранить':'Создать'}</button>
    </div>`, true);
}

function filterSupplierProducts(value){
  const query=String(value||'').trim().toLocaleLowerCase('ru');
  const options=[...document.querySelectorAll('#supplier-product-list .supplier-product-option')];
  let visible=0;
  options.forEach(row=>{const show=!query||(row.dataset.search||'').includes(query);row.style.display=show?'flex':'none';if(show)visible++;});
  const empty=document.getElementById('supplier-product-search-empty');if(empty)empty.style.display=options.length&&!visible?'block':'none';
}

function deleteSupplier(id){
  if(!canEditCompanySettings()){
    flash('Удалять поставщиков может только администратор при открытой им смене');
    return;
  }
  const supplier=state.suppliers.find(s=>s.id===id);
  if(!supplier) return;
  showModal(`
    <div class="modal-title">Удаление поставщика</div>
    <div class="center-note" style="padding:8px 0 14px;">Удалить поставщика «${escapeHtml(supplier.name)}» из списка?</div>
    <div class="modal-actions">
      <button class="btn btn-secondary" onclick="closeModal()">Отмена</button>
      <button id="supplier-delete-confirm" class="btn btn-danger" onclick="confirmDeleteSupplier('${escapeAttr(id)}')">Удалить</button>
    </div>`, true);
}

async function confirmDeleteSupplier(id){
  if(window._supplierDeleteBusy)return false;
  if(!canEditCompanySettings()){
    closeModal();
    flash('Удалять поставщиков может только администратор при открытой им смене');
    return false;
  }
  if(!state.suppliers.some(s=>s.id===id))return false;
  const next=state.suppliers.filter(s=>s.id!==id);
  window._supplierDeleteBusy=true;
  const button=document.getElementById('supplier-delete-confirm');if(button)button.disabled=true;
  try{
    await window.PrilavokCore.Storage.set('suppliers',next);
    state.suppliers=next;
    closeModal();
    render();
    flash('Поставщик удалён');
    return true;
  }catch(e){
    markStorageBroken(e);
    flash('Не удалось удалить поставщика: '+(e?.message||'ошибка сохранения'));
    if(button)button.disabled=false;
    return false;
  }finally{
    window._supplierDeleteBusy=false;
  }
}

async function saveSupplier(id=''){
  if(window._supplierSaveBusy)return false;
  const name=(document.getElementById('sf-name')?.value||'').trim();
  if(!name){flash('Введите название поставщика');return false;}
  const productIds=[...document.querySelectorAll('.supplier-product-check:checked')].map(x=>x.value);
  const existingIndex=id ? state.suppliers.findIndex(x=>x.id===id) : -1;
  if(id && existingIndex<0){flash('Поставщик не найден');return false;}
  const next=storageSnapshot(state.suppliers);
  if(existingIndex>=0){
    next[existingIndex].name=name;
    next[existingIndex].productIds=productIds;
  }else{
    next.push({id:uid(),name,productIds});
  }
  window._supplierSaveBusy=true;
  const button=document.getElementById('supplier-save-confirm');if(button)button.disabled=true;
  try{
    await window.PrilavokCore.Storage.set('suppliers',next);
    state.suppliers=next;
    closeModal();
    render();
    flash(id?'Поставщик сохранён':'Поставщик создан');
    return true;
  }catch(e){
    markStorageBroken(e);
    flash('Не удалось сохранить поставщика: '+(e?.message||'ошибка сохранения'));
    if(button)button.disabled=false;
    return false;
  }finally{
    window._supplierSaveBusy=false;
  }
}
