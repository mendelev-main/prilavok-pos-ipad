// Synthetic failure diagnostics for audit 003. No device data and no network.
const fs = require('node:fs');
const path = require('node:path');
const Module = require('node:module');
const vm = require('node:vm');

const root = path.resolve(__dirname, '../..');
const fixtureFile = path.join(root, 'tests/product-stock.test.cjs');
const source = fs.readFileSync(fixtureFile, 'utf8');
const prefix = source.slice(0, source.indexOf("test('all inline JavaScript"));
if (!prefix.includes('function fixture()')) throw new Error('Fixture structure changed');
const mod = new Module(fixtureFile, module);
mod.filename = fixtureFile;
mod.paths = module.paths;
mod._compile(prefix + '\nmodule.exports=fixture;', fixtureFile);
const fixture = mod.exports;
const html = fs.readFileSync(path.join(root, 'PrilavokPOS/pos.html'), 'utf8');
const printerSwift = fs.readFileSync(path.join(root, 'PrilavokPOS/NetworkPrinterManager.swift'), 'utf8');
const appSwift = fs.readFileSync(path.join(root, 'PrilavokPOS/PrilavokPOSApp.swift'), 'utf8');

const plain = value => JSON.parse(JSON.stringify(value));
const settle = async () => { for (let i = 0; i < 8; i++) await Promise.resolve(); };

(async () => {
  const results = [];

  {
    const f = fixture();
    f.cart();
    f.state.orderLabel = 'Стол 1';
    f.c.saveCurrentOrderSession();
    await settle();
    const realSet = f.c.localStorage.setItem;
    f.c.localStorage.setItem = (key, value) => {
      if (key === 'prilavok_parked') throw new Error('injected parked failure');
      realSet(key, value);
    };
    f.c.parkOrderNow();
    await settle();
    const session = JSON.parse(f.data.get('prilavok_currentOrderSession'));
    results.push({
      id: 'A003-F01',
      reproduced: f.state.cart.length === 0 && !f.data.has('prilavok_parked') && session.items.length === 0,
      observed: { cartItems: f.state.cart.length, parkedStored: f.data.has('prilavok_parked'), sessionItems: session.items.length, message: f.messages.at(-1) }
    });
  }

  {
    const f = fixture();
    f.data.set('prilavok_shifts', JSON.stringify(plain(f.state.shifts)));
    f.fields['sf-counted'] = { value: '100' };
    let telegramSent = 0;
    f.c.sendTelegramShiftClosed = () => { telegramSent += 1; };
    const realSet = f.c.localStorage.setItem;
    f.c.localStorage.setItem = (key, value) => {
      if (key === 'prilavok_shifts') throw new Error('injected shift failure');
      realSet(key, value);
    };
    await f.c.submitCloseShift();
    await settle();
    const stored = JSON.parse(f.data.get('prilavok_shifts'))[0];
    results.push({
      id: 'A003-F02',
      reproduced: f.state.shifts[0].status === 'closed' && stored.status === 'open' && telegramSent === 1,
      observed: { memoryStatus: f.state.shifts[0].status, storedStatus: stored.status, telegramSent }
    });
  }

  {
    const f = fixture();
    const flour = f.c.getProduct('flour');
    flour.stock = 3;
    f.state.inventoryHistory = [];
    f.state.inventoryConfig = { enabled: true, frequency: 'monthly', productIds: ['flour'], lastCompletedAt: null };
    f.state.inventoryDraft = { id: 'inventory', type: 'scheduled', startedAt: 1, items: [{ productId: 'flour', name: 'Мука', unit: 'kg', expected: 10, actual: 3, difference: -7, fixedAt: 2 }] };
    const storedProducts = plain(f.state.products); storedProducts.find(x => x.id === 'flour').stock = 10;
    f.data.set('prilavok_products', JSON.stringify(storedProducts));
    f.data.set('prilavok_inventoryHistory', '[]');
    f.data.set('prilavok_inventoryConfig', JSON.stringify({ enabled: true, frequency: 'monthly', productIds: ['flour'], lastCompletedAt: null }));
    f.data.set('prilavok_inventoryDraft', JSON.stringify(plain(f.state.inventoryDraft)));
    const realSet = f.c.localStorage.setItem;
    f.c.localStorage.setItem = (key, value) => {
      if (key === 'prilavok_inventoryHistory') throw new Error('injected history failure');
      realSet(key, value);
    };
    f.c.confirmCompleteInventory();
    await settle();
    const storedStock = JSON.parse(f.data.get('prilavok_products')).find(x => x.id === 'flour').stock;
    const storedHistory = JSON.parse(f.data.get('prilavok_inventoryHistory'));
    const storedDraft = JSON.parse(f.data.get('prilavok_inventoryDraft'));
    results.push({
      id: 'A003-F03',
      reproduced: storedStock === 3 && storedHistory.length === 0 && storedDraft === null,
      observed: { storedStock, historyRows: storedHistory.length, storedDraft, message: f.messages.at(-1) }
    });
  }

  {
    const f = fixture();
    f.data.set('prilavok_products', '{}');
    let error = '';
    try { await f.c.loadAll(); } catch (caught) { error = String(caught?.message || caught); }
    results.push({ id: 'A003-F04', reproduced: /map is not a function/.test(error), observed: { error } });
  }

  {
    const f = fixture();
    f.data.set('prilavok_shifts', JSON.stringify(plain(f.state.shifts)));
    f.fields['sf-counted'] = { value: '-100' };
    await f.c.submitCloseShift();
    await settle();
    const stored = JSON.parse(f.data.get('prilavok_shifts'))[0];
    results.push({ id: 'A003-F05', reproduced: stored.countedCash === -100, observed: { countedCash: stored.countedCash } });
  }

  {
    const loyaltyBody = html.slice(html.indexOf('function loyaltyApi'), html.indexOf('async function searchCustomers'));
    const photoBody = html.slice(html.indexOf('async function saveProduct(editingId)'), html.indexOf('function canEditProductWebSetting'));
    results.push({
      id: 'A003-F06',
      reproduced: loyaltyBody.includes('fetch(') && !loyaltyBody.includes('AbortController') && !loyaltyBody.includes('signal:'),
      observed: { loyaltyHasTimeout: loyaltyBody.includes('AbortController') || loyaltyBody.includes('signal:') }
    });
    results.push({
      id: 'A003-F07',
      reproduced: photoBody.indexOf('/api/media/upload') < photoBody.indexOf("saveKey('products'") && !photoBody.includes('AbortController'),
      observed: { uploadBeforeLocalSave: photoBody.indexOf('/api/media/upload') < photoBody.indexOf("saveKey('products'"), uploadHasTimeout: photoBody.includes('AbortController') }
    });
    results.push({
      id: 'A003-F08',
      reproduced: !printerSwift.includes('NWConnection.State.waiting') && !printerSwift.includes('asyncAfter') && printerSwift.includes('networkConnections'),
      observed: { explicitDeadline: printerSwift.includes('asyncAfter'), handlesWaiting: printerSwift.includes('case .waiting') }
    });
    results.push({
      id: 'A003-F09',
      reproduced: appSwift.includes('contentController.add(self, name: "telegram")') && !appSwift.includes('removeScriptMessageHandler(forName: "telegram")'),
      observed: { removesPrinter: appSwift.includes('removeScriptMessageHandler(forName: "printer")'), removesTelegram: appSwift.includes('removeScriptMessageHandler(forName: "telegram")'), removesPhotoPicker: appSwift.includes('removeScriptMessageHandler(forName: "photoPicker")') }
    });
  }

  console.log(JSON.stringify(results, null, 2));
  if (results.some(result => !result.reproduced)) process.exitCode = 1;
})().catch(error => { console.error(error); process.exitCode = 1; });
