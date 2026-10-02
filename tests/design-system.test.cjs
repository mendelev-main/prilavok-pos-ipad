const test=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');

const root=path.resolve(__dirname,'..');
const html=fs.readFileSync(path.join(root,'PrilavokPOS/pos.html'),'utf8');
const featureDir=path.join(root,'PrilavokPOS/Web/js/features');
const featureSources=fs.readdirSync(featureDir).filter(name=>name.endsWith('.js')).map(name=>fs.readFileSync(path.join(featureDir,name),'utf8'));
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
