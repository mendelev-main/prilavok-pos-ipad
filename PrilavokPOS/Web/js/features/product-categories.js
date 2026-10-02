/* Product categories runtime. Compatibility globals are intentional during gradual migration. */
function openCategoriesModal(){
  syncCategoryOrder();
  const cats=state.categoryOrder.slice();
  showModal(`
    <div class="modal-title">Категории</div>
    <div class="center-note" style="padding:0 0 12px;text-align:left;">Добавляйте, переименовывайте, настраивайте цвет и удаляйте категории.</div>
    <div style="display:flex;justify-content:flex-end;margin-bottom:10px;">
      <button class="btn btn-primary" style="width:auto;padding:10px 14px;" onclick="openCategoryModal(null)">+ Добавить категорию</button>
    </div>
    <div style="max-height:52vh;overflow:auto;">
      ${cats.length ? cats.map(c=>{
        const count=state.products.filter(p=>productCategoryKey(p)===c).length;
        return `<div class="category-row">
          <div class="category-main">
            <div class="category-name"><span style="display:inline-block;width:14px;height:14px;border-radius:4px;background:${state.categoryColors[c]||'#EEF1F5'};border:1px solid rgba(0,0,0,.12);margin-right:8px;vertical-align:-2px;"></span>${escapeHtml(c)}</div>
            <div class="category-sub">${count} ${count===1?'товар':'товаров'}</div>
          </div>
          <button type="button" class="web-switch ${state.categoryOnline[c]!==false?'on':''}" role="switch" aria-label="Публиковать категорию ${escapeAttr(c)} в WEB" aria-checked="${state.categoryOnline[c]!==false}" onclick="toggleCategoryOnline('${escapeAttr(c)}')" title="Публиковать в WEB"><span></span><b>WEB</b></button>
          <button type="button" class="icon-btn" aria-label="Изменить категорию ${escapeAttr(c)}" onclick="openCategoryModal('${escapeAttr(c)}')"><span class="ui-icon ui-icon-edit" aria-hidden="true"></span></button>
          <button type="button" class="icon-btn danger" aria-label="Удалить категорию ${escapeAttr(c)}" onclick="deleteCategory('${escapeAttr(c)}')"><span class="ui-icon ui-icon-close" aria-hidden="true"></span></button>
        </div>`;
      }).join('') : '<div class="center-note">Категорий пока нет.</div>'}
    </div>
    <div class="modal-actions">
      <button class="btn btn-secondary" onclick="closeModal()">Закрыть</button>
    </div>
  `);
}

function openCategoryModal(oldName){
  const returnToCategoryList = true;
  const editing = oldName !== null && oldName !== undefined;
  const colors = [
    '#EEF1F5','#DDEBFF','#DFF5E8','#FFF0C7','#FFE0E0',
    '#E9DDFB','#DDF4F4','#F5E1D3','#E5E5E5','#DCE6F7'
  ];
  const selectedColor = state.categoryColors[oldName] || colors[0];
  window._cmOnline = editing ? state.categoryOnline[oldName] !== false : true;
  showModal(`
    <div class="modal-title">${editing?'Изменить категорию':'Новая категория'}</div>
    <div class="field"><label>Название категории</label>
      <input type="text" id="cf-name" value="${editing?escapeAttr(oldName):''}" placeholder="Например, Напитки">
    </div>
    <div class="field"><label>Обозначение на плитке</label>
      <input type="text" id="cf-symbol" value="${editing?escapeAttr(state.categorySymbols[oldName]||''):''}" placeholder="До 3 символов: ☕ / К / КФ" autocomplete="off">
      <div class="center-note" style="padding:6px 0 0;text-align:left;">До 3 символов. Они будут отображаться по центру плитки в рабочей зоне.</div>
    </div>
    <div class="field"><label>Цвет категории</label>
      <div class="category-color-picker">
        ${colors.map(color=>`<button type="button" class="category-color-option ${selectedColor===color?'selected':''}" style="background:${color}" data-color="${color}" onclick="selectCategoryColor('${color}')" aria-label="Выбрать цвет"></button>`).join('')}
      </div>
      <input type="hidden" id="cf-color" value="${selectedColor}">
    </div>
    <div class="field">
      <div class="web-setting-row">
        <div><div style="font-weight:800;">Публиковать в WEB</div><div class="center-note" style="padding:3px 0 0;text-align:left;">Категория будет доступна клиентам онлайн.</div></div>
        <button type="button" id="cf-web-toggle" class="toggle-switch ${editing&&state.categoryOnline[oldName]===false?'':'on'}" role="switch" aria-label="Публиковать категорию в WEB" aria-checked="${editing&&state.categoryOnline[oldName]===false?'false':'true'}" onclick="toggleCategoryModalOnline()"><span></span></button>
      </div>
    </div>
    ${editing?`<div class="center-note" style="padding:0;text-align:left;">При переименовании категория изменится у всех товаров, которые к ней относятся.</div>`:''}
    <div class="modal-actions">
      <button class="btn btn-secondary" onclick="closeModal()">Отмена</button>
      <button class="btn btn-primary" onclick="saveCategory(${editing?`'${escapeAttr(oldName)}'`:'null'})">Сохранить</button>
    </div>
  `);
}
function selectCategoryColor(color){
  const input=document.getElementById('cf-color');
  if(input) input.value=color;
  document.querySelectorAll('.category-color-option').forEach(b=>b.classList.toggle('selected',b.dataset.color===color));
}

// Keep tile labels Unicode-safe. Emoji such as 👨‍🍳, ❤️ and flags can contain
// several UTF-16 code units while representing a single visible character.
function limitTileSymbol(value, maxSymbols=3){
  const text=(value||'').trim();
  if(!text) return '';
  try{
    if(typeof Intl!=='undefined' && Intl.Segmenter){
      const segmenter=new Intl.Segmenter(undefined,{granularity:'grapheme'});
      return Array.from(segmenter.segment(text), part=>part.segment).slice(0,maxSymbols).join('');
    }
  }catch(_){}
  // Fallback keeps Unicode code points intact on older WebKit.
  return Array.from(text).slice(0,maxSymbols).join('');
}

function saveCategory(oldName){
  const input=document.getElementById('cf-name');
  const name=(input?.value||'').trim();
  if(!name){ flash('Введите название категории'); return; }
  const duplicate=state.categoryOrder.some(c=>c.toLowerCase()===name.toLowerCase() && c!==oldName);
  if(duplicate){ flash('Такая категория уже существует'); return; }
  const color=document.getElementById('cf-color')?.value || '#EEF1F5';
  const symbol=limitTileSymbol(document.getElementById('cf-symbol')?.value||'');
  if(oldName===null || oldName===undefined){
    state.categoryOrder.push(name);
    state.categoryColors[name]=color;
    state.categoryOnline[name]=window._cmOnline !== false;
    if(symbol) state.categorySymbols[name]=symbol; else delete state.categorySymbols[name];
  } else {
    if(oldName!==name){const entry=state.posNavigation.categories.find(e=>e.category===oldName);if(entry){entry.category=name;saveKey('posNavigation',state.posNavigation);}}
    const idx=state.categoryOrder.indexOf(oldName);
    if(idx>=0) state.categoryOrder[idx]=name;
    state.products.forEach(p=>{ if(productCategoryKey(p)===oldName) p.category=name; });
    state.layoutTiles.forEach(t=>{ if(t.type==='category' && t.id===oldName) t.id=name; });
    if(oldName!==name) { delete state.categoryColors[oldName]; delete state.categorySymbols[oldName]; state.categoryOnline[name]=state.categoryOnline[oldName] !== false; delete state.categoryOnline[oldName]; }
    state.categoryColors[name]=color;
    state.categoryOnline[name]=window._cmOnline !== false;
    if(symbol) state.categorySymbols[name]=symbol; else delete state.categorySymbols[name];
    saveKey('products',state.products);
  }
  saveKey('layout',{categoryOrder:state.categoryOrder,categoryColors:state.categoryColors,categorySymbols:state.categorySymbols,categoryOnline:state.categoryOnline,tiles:state.layoutTiles});
  closeModal(); render(); flash(oldName===null||oldName===undefined?'Категория добавлена':'Категория изменена');
}
function toggleCategoryOnline(name){
  state.categoryOnline[name]=state.categoryOnline[name]===false;
  saveKey('layout',{categoryOrder:state.categoryOrder,categoryColors:state.categoryColors,categorySymbols:state.categorySymbols,categoryOnline:state.categoryOnline,tiles:state.layoutTiles});
  const rows=document.querySelectorAll('#modal-root .category-row');
  rows.forEach(row=>{
    const btn=row.querySelector('.web-switch');
    const nameEl=row.querySelector('.category-name');
    if(btn && nameEl && nameEl.textContent.trim()===name){
      const enabled=state.categoryOnline[name]!==false;
      btn.classList.toggle('on',enabled);
      btn.setAttribute('aria-checked',String(enabled));
    }
  });
  flash(state.categoryOnline[name]?'Категория опубликована в WEB':'Категория снята с публикации WEB');
}
function toggleCategoryModalOnline(){
  window._cmOnline=!window._cmOnline;
  const b=document.getElementById('cf-web-toggle');
  if(b){ b.classList.toggle('on',window._cmOnline); b.setAttribute('aria-checked',String(window._cmOnline)); }
}

function deleteCategory(name){
  const used=state.products.some(p=>productCategoryKey(p)===name);
  if(used){ flash('Нельзя удалить категорию: в ней есть товары'); return; }
  if(!state.categoryOrder.includes(name)) return;
  requestDelete('category', name);
}
