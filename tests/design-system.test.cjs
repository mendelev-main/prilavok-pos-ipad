const test=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');

const root=path.resolve(__dirname,'..');
const html=fs.readFileSync(path.join(root,'PrilavokPOS/pos.html'),'utf8');
const featureDir=path.join(root,'PrilavokPOS/Web/js/features');
const featureSourceByName=new Map(fs.readdirSync(featureDir).filter(name=>name.endsWith('.js')).map(name=>[name,fs.readFileSync(path.join(featureDir,name),'utf8')]));
const featureSources=[...featureSourceByName.values()];
const production=[html,...featureSources].join('\n');

test('design tokens referenced by static UI are declared or intentionally dynamic',()=>{
  const declared=new Set([...html.matchAll(/(--[a-zA-Z0-9_-]+)\s*:/g)].map(match=>match[1]));
  const dynamic=new Set(['--category-color','--drag-h','--drag-w','--folder-columns','--folder-width']);
  const used=new Set([...production.matchAll(/var\((--[a-zA-Z0-9_-]+)/g)].map(match=>match[1]));
  const missing=[...used].filter(name=>!declared.has(name)&&!dynamic.has(name));
  assert.deepEqual(missing,[]);
});

test('production UI uses only bundled Manrope font weights',()=>{
  assert.doesNotMatch(production,/font-weight\s*:\s*(?:750|850|900)\b/);
  assert.doesNotMatch(html,/fonts\.googleapis\.com/);
  assert.match(html,/Web\/fonts\/Manrope-Variable\.ttf/);
  assert.ok(fs.existsSync(path.join(root,'PrilavokPOS/Web/fonts/Manrope-Variable.ttf')));
});

test('button switches expose state to assistive technologies',()=>{
  const categories=featureSources.find(source=>source.includes('function openCategoriesModal'));
  const catalog=featureSources.find(source=>source.includes('function renderProducts'));
  assert.match(categories,/class="web-switch[^\n]+role="switch"[^\n]+aria-checked=/);
  assert.match(categories,/id="cf-web-toggle"[^\n]+role="switch"[^\n]+aria-checked=/);
  assert.match(catalog,/class="web-switch[^\n]+role="switch"[^\n]+aria-checked=/);
});

test('primary controls use semantic colors and standard touch sizes',()=>{
  assert.match(html,/\.btn-primary\{background:var\(--accent\);color:var\(--accent-ink\)/);
  assert.match(html,/\.icon-btn\{width:44px;height:44px/);
  assert.match(html,/\.settings-plus-btn\{width:44px;height:44px;min-width:44px/);
  assert.match(html,/\.cart-customer-button\{width:44px;height:44px/);
});

test('switches and common fields share canonical geometry tokens',()=>{
  assert.match(html,/--switch-width:48px/);
  assert.match(html,/--control-height:44px/);
  assert.match(html,/\.theme-switch\{[^}]+width:var\(--switch-width\)/);
  assert.match(html,/\.switch\{[^}]+width:var\(--switch-width\)/);
  assert.match(html,/\.analytics-filter input,[^}]+height:var\(--control-height\)/);
});

test('standalone control icons use the shared CSS icon set',()=>{
  assert.match(html,/\.ui-icon-close::before/);
  assert.match(html,/\.ui-icon-edit::before/);
  assert.doesNotMatch(production,/✕|✎|💬|⚠️|⌕/);
});

test('supply history and detail presentation use shared semantic classes',()=>{
  const supply=featureSourceByName.get('purchase-orders.js')+'\n'+featureSourceByName.get('receiving-ui.js');
  assert.doesNotMatch(supply,/style="/);
  assert.match(html,/\.supply-modal-meta\{/);
  assert.match(html,/\.receiving-detail-list\{/);
  assert.match(html,/\.purchase-status\.pending\{background:var\(--warning-soft\)/);
  assert.match(html,/\.purchase-status\.received\{background:var\(--success-soft\)/);
  assert.match(html,/\.purchase-status\.shortage\{background:var\(--danger-soft\)/);
});

test('catalog and workspace navigation isolate dynamic presentation',()=>{
  const catalog=featureSourceByName.get('product-catalog.js');
  const navigation=featureSourceByName.get('pos-navigation.js');
  assert.doesNotMatch(catalog,/style="/);
  assert.match(catalog,/row\.hidden=!show/);
  const dynamicStyles=[...navigation.matchAll(/style="([^"]*)"/g)].map(match=>match[1]);
  assert.deepEqual(dynamicStyles,['${pos}','--category-color:${categoryColor}']);
  assert.match(html,/\.products-search-clear\[hidden\]/);
  assert.match(html,/\.pos-folder-modal\[data-columns="4"\]/);
});

test('product configuration and categories isolate dynamic presentation',()=>{
  const configuration=featureSourceByName.get('product-configuration.js');
  const categories=featureSourceByName.get('product-categories.js');
  assert.doesNotMatch(configuration,/style="/);
  const dynamicStyles=[...categories.matchAll(/style="([^"]*)"/g)].map(match=>match[1]);
  assert.deepEqual(dynamicStyles,["--category-color:${state.categoryColors[c]||'#EEF1F5'}",'--category-color:${color}']);
  assert.match(html,/\.configuration-access-note\{/);
  assert.match(html,/\.category-swatch\{/);
});

test('bookings isolate dynamic hall geometry from static presentation',()=>{
  const bookings=featureSourceByName.get('hall-bookings.js');
  const dynamicStyles=[...bookings.matchAll(/style="([^"]*)"/g)].map(match=>match[1]);
  assert.deepEqual(dynamicStyles,["left:${t.x}%;top:${t.y}%;transform:rotate(${Number(t.rotation||0)}deg)${state.selectedHallTableId===t.id?' scale(1.015)':''};"]);
  assert.match(html,/\.hall-rotation-actions\{/);
  assert.match(html,/\.booking-card-actions\{/);
  assert.match(html,/\.booking-filters\.single-column\{/);
});

test('settings and suppliers use shared presentation classes',()=>{
  const suppliers=featureSourceByName.get('suppliers.js');
  assert.doesNotMatch(suppliers,/style="/);
  assert.match(suppliers,/class="supplier-product-list"/);
  assert.match(suppliers,/row\.hidden=!show/);
  assert.match(html,/\.settings-nav-card\{/);
  assert.match(html,/\.settings-section-title\{/);
  assert.match(html,/\.supplier-product-option\[hidden\]/);
});

test('loyalty and analytics isolate dynamic chart presentation',()=>{
  const loyalty=featureSourceByName.get('loyalty.js');
  const analytics=featureSourceByName.get('analytics.js');
  assert.doesNotMatch(loyalty,/style="/);
  const dynamicStyles=[...analytics.matchAll(/style="([^"]*)"/g)].map(match=>match[1]);
  assert.deepEqual(dynamicStyles,['width:${Math.max(2,x.value/max*100)}%','width:${Math.max(2,value/max*100)}%']);
  assert.match(html,/\.loyalty-customer-section-title\{/);
  assert.match(html,/\.analytics-section-gap\{/);
  assert.match(html,/\.hbar-value-hidden\{/);
});

test('WEB events and parked orders use shared presentation classes',()=>{
  const webOrders=featureSourceByName.get('web-orders.js');
  const parkedOrders=featureSourceByName.get('parked-orders.js');
  assert.doesNotMatch(webOrders,/style="/);
  assert.doesNotMatch(parkedOrders,/style="/);
  assert.match(html,/\.web-event-row\{/);
  assert.match(html,/\.web-recovery-note\{/);
  assert.match(html,/\.parked-order-main\{/);
  assert.match(html,/\.parked-order-comment\{/);
});

test('system and network settings contain no inline presentation',()=>{
  assert.doesNotMatch(html,/style="/);
  assert.doesNotMatch(html,/☀️|🌙/);
  assert.match(html,/\.network-card-title\{/);
  assert.match(html,/\.network-device-key\{/);
  assert.match(html,/\.telegram-token-row\{/);
  assert.match(html,/\.appearance-theme-options\{/);
});
