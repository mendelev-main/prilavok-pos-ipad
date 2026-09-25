// Run from any directory: node --test tests/product-stock.test.cjs
// Executes the actual POS functions with synthetic storage; no device data or network.
const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const vm=require('node:vm');
const root=path.resolve(__dirname,'..');
const html=fs.readFileSync(path.join(root,'PrilavokPOS/pos.html'),'utf8');
const inline=[...html.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/g)].map(m=>m[1]).join('\n');
const adapter=fs.readFileSync(path.join(root,'PrilavokPOS/Web/js/core/storage.js'),'utf8');
const plain=x=>JSON.parse(JSON.stringify(x));
const near=(actual,expected)=>assert.ok(Math.abs(actual-expected)<1e-10,`${actual} != ${expected}`);
function fixture(){
 const data=new Map(),messages=[],writes=[],fields={},events=[];
 const document={getElementById:id=>fields[id]||null,querySelector:()=>null,addEventListener:()=>{}};
 const c={console:{error:()=>{}},document,crypto:{randomUUID:()=> 'device-test'},setTimeout:()=>0,clearTimeout:()=>{},AbortController,localStorage:{getItem:k=>data.has(k)?data.get(k):null,setItem:(k,v)=>{data.set(k,String(v));writes.push(k);},removeItem:k=>data.delete(k)},fetch:()=>{throw Error('Network is prohibited in this test');},setInterval:()=>{throw Error('Timer is prohibited in this test');}};
 c.window=c;vm.createContext(c);vm.runInContext(adapter,c);vm.runInContext(inline.replace(/loadAll\(\);\s*$/,''),c);
 c.flash=m=>messages.push(m);c.render=()=>{};c.showReceipt=()=>{};c.closeModal=()=>{};c.applyTheme=()=>{};
 const state=vm.runInContext('state',c);
 state.products=[{id:'flour',name:'Мука',type:'simple',stock:10,cost:2,price:2,category:'Сырьё',sortOrder:0,availableOnline:false,imageUrl:''},{id:'water',name:'Вода',type:'simple',stock:10,cost:1,price:1},{id:'dough',name:'Тесто',type:'composite',components:[{productId:'flour',qty:0.2},{productId:'water',qty:0.1}]},{id:'pizza',name:'Пицца',type:'composite',price:10,components:[{productId:'dough',qty:1}]}];
 state.shifts=[{id:'shift',status:'open',openingCash:100}];state.orders=[];state.cart=[];state.printer={autoPrint:false};state.discounts=[];
 function cart(id='pizza',qty=1){state.cart=[{productId:id,name:c.getProduct(id)?.name||id,price:10,qty}];}
 function sale(payments){cart();c.finalizePayment(payments||[{method:'cash',amount:10}]);return state.orders[0];}
 return {c,state,data,messages,writes,fields,events,cart,sale};
}
test('all inline JavaScript and adapter parse',()=>{new vm.Script(inline);new vm.Script(adapter);});
test('nested recipe multiplies quantities and aggregates repeated ingredients',()=>{
 const f=fixture();f.c.getProduct('pizza').components=[{productId:'dough',qty:2},{productId:'flour',qty:0.1}];
 const quantities=f.c.productIngredients(f.c.getProduct('pizza'),3);
 near(quantities.get('flour'),1.5);near(quantities.get('water'),0.6);
 near(f.c.compositeCost(f.c.getProduct('pizza')),1.2);
 f.c.getProduct('flour').stock=1;assert.equal(f.c.availableStock(f.c.getProduct('pizza')),2);
});
test('sale writes nested stock snapshot through real adapter; same receipt survives restart',async()=>{
 const f=fixture(),order=f.sale();near(f.c.getProduct('flour').stock,9.8);near(f.c.getProduct('water').stock,9.9);
 assert.deepEqual(plain(order.stockConsumption),{version:1,items:[{productId:'flour',qty:0.2},{productId:'water',qty:0.1}]});
 const saved=JSON.parse(f.data.get('prilavok_orders'));assert.deepEqual(saved[0].stockConsumption,plain(order.stockConsumption));
 const next=fixture();for(const [k,v] of f.data)next.data.set(k,v);await next.c.loadAll();
 assert.deepEqual(plain(next.state.orders[0].stockConsumption),saved[0].stockConsumption);
 assert.ok(f.writes.every(k=>k.startsWith('prilavok_')));
});
test('cash, card and split payments create one receipt and retain payment data',()=>{
 for(const payments of [[{method:'cash',amount:10,cashGiven:20,change:10}],[{method:'card',amount:10}],[{method:'cash',amount:4,cashGiven:5,change:1},{method:'card',amount:6}]]){
  const f=fixture(),order=f.sale(payments);assert.equal(f.state.orders.length,1);assert.equal(order.total,10);
  assert.equal(order.payments.length,payments.length);near(f.c.getProduct('flour').stock,9.8);
  f.c.finalizePayment(payments);assert.equal(f.state.orders.length,1,'empty cart cannot create duplicate receipt');
 }
});

test('web order context is cleared after payment and after removing the last cart item',()=>{
 const paid=fixture();paid.state.orderComment='Комментарий с WEB';paid.state.currentOrderSource='web';paid.state.currentWebOrderId='web-1';paid.state.currentWebOrderStatus='accepted';
 paid.sale();assert.equal(paid.state.orderComment,'');assert.equal(paid.state.currentOrderSource,'');assert.equal(paid.state.currentWebOrderId,'');assert.equal(paid.state.currentWebOrderStatus,'');
 const removed=fixture();removed.cart();removed.state.orderComment='Не оставлять';removed.state.currentOrderSource='web';removed.state.currentWebOrderId='web-2';removed.state.currentWebOrderStatus='accepted';
 removed.c.removeFromCart('pizza');assert.equal(removed.state.cart.length,0);assert.equal(removed.state.orderComment,'');assert.equal(removed.state.currentOrderSource,'');assert.equal(removed.state.currentWebOrderId,'');assert.equal(removed.state.currentWebOrderStatus,'');
 const saved=JSON.parse(removed.data.get('prilavok_currentOrderSession'));assert.equal(saved.orderComment,'');assert.equal(saved.webOrderId,'');
});

test('stock arithmetic is normalized to at most three decimal places',()=>{
 const sale=fixture();sale.c.getProduct('pizza').components=[{productId:'flour',qty:0.1}];sale.c.getProduct('flour').stock=15.1;sale.sale();
 assert.equal(sale.c.getProduct('flour').stock,15);assert.equal(sale.c.stockQtyText(15.0000000000002),'15');assert.equal(sale.c.stockQtyText(1.2345),'1.235');
 sale.c.processFullReturn(sale.state.orders[0].id);assert.equal(sale.c.getProduct('flour').stock,15.1);
});

test('modifier stock is aggregated with base recipe and survives exact return',()=>{
 const f=fixture();
 f.state.products.push({id:'bacon',name:'Бекон',type:'simple',stock:1,cost:10,price:10});
 const pizza=f.c.getProduct('pizza');pizza.modifierGroups=[{id:'filling',name:'Начинка',min:1,max:1,options:[{id:'bacon-opt',productId:'bacon',qty:.05,priceDelta:1.5}]}];
 f.state.cart=[{cartLineId:'line-1',productId:'pizza',name:'Пицца',price:11.5,qty:2,selectedModifiers:[{groupId:'filling',groupName:'Начинка',optionId:'bacon-opt',productId:'bacon',name:'Бекон',qty:.05,priceDelta:1.5}]}];
 const plan=f.c.checkedStockConsumption(f.state.cart);
 near(plan.items.find(i=>i.productId==='flour').qty,.4);near(plan.items.find(i=>i.productId==='water').qty,.2);near(plan.items.find(i=>i.productId==='bacon').qty,.1);
 f.c.finalizePayment([{method:'cash',amount:23}]);near(f.c.getProduct('bacon').stock,.9);
 const order=f.state.orders[0];assert.equal(order.items[0].selectedModifiers[0].name,'Бекон');near(order.total,23);
 f.c.processFullReturn(order.id);near(f.c.getProduct('bacon').stock,1);
});
test('modifier can be composite and expands recursively into simple stock',()=>{
 const f=fixture();
 f.state.products.push({id:'sauce',name:'Соус',type:'composite',components:[{productId:'water',qty:.2},{productId:'flour',qty:.1}]});
 const items=[{productId:'pizza',qty:1,selectedModifiers:[{productId:'sauce',qty:.5,priceDelta:0}]}];
 const plan=f.c.checkedStockConsumption(items);
 near(plan.items.find(i=>i.productId==='flour').qty,.25);near(plan.items.find(i=>i.productId==='water').qty,.2);
});
test('modifier shortage rejects cart without stock mutation',()=>{
 const f=fixture();f.state.products.push({id:'bacon',name:'Бекон',type:'simple',stock:.04,cost:10,price:10});
 const before=JSON.stringify(f.state.products);
 f.c.addConfiguredCartItem(f.c.getProduct('pizza'),[{groupId:'filling',productId:'bacon',name:'Бекон',qty:.05,priceDelta:1.5}]);
 assert.equal(f.state.cart.length,0);assert.equal(JSON.stringify(f.state.products),before);assert.match(f.messages.at(-1),/Недостаточно остатка: Бекон/);
});
test('same modifier selection merges, different selection stays separate and legacy cart remains compatible',()=>{
 const f=fixture();f.state.products.push({id:'bacon',name:'Бекон',type:'simple',stock:10},{id:'ham',name:'Ветчина',type:'simple',stock:10});
 const p=f.c.getProduct('pizza'),b=[{groupId:'f',productId:'bacon',name:'Бекон',qty:.05,priceDelta:1}],h=[{groupId:'f',productId:'ham',name:'Ветчина',qty:.05,priceDelta:0}];
 f.c.addConfiguredCartItem(p,b);f.c.addConfiguredCartItem(p,b);f.c.addConfiguredCartItem(p,h);
 assert.equal(f.state.cart.length,2);assert.equal(f.state.cart[0].qty,2);assert.equal(f.state.cart[0].price,11);assert.equal(f.state.cart[1].price,10);
 f.state.cart=[{productId:'pizza',name:'Пицца',price:10,qty:1}];assert.doesNotThrow(()=>f.c.checkedStockConsumption(f.state.cart));assert.equal(f.c.cartItemKey(f.state.cart[0]),'pizza');
});
test('shared ingredients across different cart products reject overselling without mutation',()=>{
 const f=fixture();f.c.getProduct('flour').stock=0.3;f.state.products.push({id:'second',name:'Вторая пицца',type:'composite',price:10,components:[{productId:'flour',qty:0.2}]});
 f.c.addToCart('pizza');f.c.addToCart('second');assert.equal(f.state.cart.length,1);assert.match(f.messages.at(-1),/Недостаточно остатка/);
 f.state.cart.push({productId:'second',name:'Вторая',qty:1,price:10});
 const before=JSON.stringify(f.state);f.c.finalizePayment([{method:'cash',amount:20}]);assert.equal(JSON.stringify(f.state),before);assert.equal(f.writes.filter(k=>k==='prilavok_orders').length,0);
});
test('same ingredient sold directly and in recipe counts once in aggregate',()=>{
 const f=fixture();f.cart();f.state.cart.push({productId:'flour',qty:2,price:2});
 const plan=f.c.checkedStockConsumption(f.state.cart);near(plan.items.find(i=>i.productId==='flour').qty,2.2);
});
test('cart quantity increase checks other products, decrease remains possible',()=>{
 const f=fixture();f.c.getProduct('flour').stock=0.5;f.cart();f.state.cart.push({productId:'flour',qty:0.2,price:2});
 f.c.changeQty('pizza',1);assert.equal(f.state.cart[0].qty,1);f.c.changeQty('pizza',-1);assert.equal(f.state.cart.length,1);
});
test('fractional consumption permits exact stock, never consumes a material shortage',()=>{
 const f=fixture();f.c.getProduct('pizza').components=[{productId:'flour',qty:0.1}];f.c.getProduct('flour').stock=0.3;
 assert.equal(f.c.availableStock(f.c.getProduct('pizza')),3);f.cart('pizza',3);f.c.finalizePayment([{method:'cash',amount:30}]);near(f.c.getProduct('flour').stock,0);
 const missing=fixture();missing.c.getProduct('flour').stock=0.199;assert.throws(()=>missing.c.checkedStockConsumption([{productId:'pizza',qty:1}]),/Недостаточно/);
 missing.c.getProduct('flour').stock=0;assert.throws(()=>missing.c.checkedStockConsumption([{productId:'flour',qty:1e-20}]),/Недостаточно/);
});
test('return uses sold recipe after edit and ignores current tracking flag',()=>{
 const f=fixture(),order=f.sale();f.c.getProduct('dough').components[0].qty=0.8;f.c.getProduct('flour').noStockTracking=true;
 f.c.processFullReturn(order.id);near(f.c.getProduct('flour').stock,10);near(f.c.getProduct('water').stock,10);assert.ok(order.returnedAt);
 const first=JSON.stringify(f.state);f.c.processFullReturn(order.id);assert.equal(JSON.stringify(f.state),first,'second return cannot add stock or cash twice');
});
test('deleted sold composite does not affect return of recorded ingredients',()=>{
 const f=fixture(),order=f.sale();f.state.products=f.state.products.filter(p=>p.id!=='pizza'&&p.id!=='dough');f.c.restoreOrderStock(order);near(f.c.getProduct('flour').stock,10);
});
test('untracked ingredients are not deducted or restored, even if flag later changes',()=>{
 const f=fixture();f.c.getProduct('flour').noStockTracking=true;const order=f.sale();assert.equal(order.stockConsumption.items.length,1);f.c.getProduct('flour').noStockTracking=false;f.c.restoreOrderStock(order);near(f.c.getProduct('flour').stock,10);
 const all=fixture();all.c.getProduct('flour').noStockTracking=true;all.c.getProduct('water').noStockTracking=true;assert.equal(all.c.availableStock(all.c.getProduct('pizza')),Infinity);const o=all.sale();assert.deepEqual(plain(o.stockConsumption.items),[]);all.c.restoreOrderStock(o);
});
test('legacy receipt has no fabricated snapshot and retains legacy one-level return',()=>{
 const f=fixture();const order={id:'old',items:[{productId:'pizza',qty:1}]};f.c.restoreOrderStock(order);near(f.c.getProduct('flour').stock,10);assert.equal('stockConsumption' in order,false);
 f.c.getProduct('pizza').components=[{productId:'flour',qty:0.2}];f.c.restoreOrderStock(order);near(f.c.getProduct('flour').stock,10.2);
});
test('invalid snapshot or missing target cannot partially change stock, cash or receipt',()=>{
 for(const snapshot of [null,{version:2,items:[]},{version:1,items:[{productId:'flour',qty:0.2},{productId:'missing',qty:0.1}]},{version:1,items:[{productId:'flour',qty:-1}]},{version:1,items:[{productId:'flour',qty:1},{productId:'flour',qty:1}]}]){
  const f=fixture(),order=f.sale();order.stockConsumption=snapshot;const before=JSON.stringify(f.state);f.c.processFullReturn(order.id);assert.equal(JSON.stringify(f.state),before);assert.match(f.messages.at(-1),/Не удалось выполнить возврат/);
 }
});
test('cycles, absent ingredients, empty recipe and invalid quantity fail safely',()=>{
 for(const components of [[{productId:'pizza',qty:1}],[{productId:'absent',qty:1}],[],[{productId:'flour',qty:0}],[{productId:'flour',qty:-1}],[{productId:'flour',qty:Infinity}]]){
  const f=fixture();f.c.getProduct('pizza').components=components;
  assert.equal(f.c.availableStock(f.c.getProduct('pizza')),0);assert.equal(f.c.compositeCost(f.c.getProduct('pizza')),0);
  assert.throws(()=>f.c.productIngredients(f.c.getProduct('pizza')));const before=JSON.stringify(f.state.products);f.sale();assert.equal(f.state.orders.length,0);assert.equal(JSON.stringify(f.state.products),before);
 }
});
test('cannot add indirect cycle into editor draft',()=>{
 const f=fixture();f.c._pmEditingId='dough';f.c._pmComponents=plain(f.c.getProduct('dough').components);const before=JSON.stringify(f.c._pmComponents);
 f.c.addComponent('pizza',1);assert.equal(JSON.stringify(f.c._pmComponents),before);assert.match(f.messages.at(-1),/Циклический состав/);
});
test('save validation rejects cycle before product mutation or any write',async()=>{
 const f=fixture();Object.assign(f.fields,{'pf-name':{value:'Тесто'},'pf-category':{value:'Сырьё'},'pf-price':{value:'5'}});
 f.c._pmType='composite';f.c._pmComponents=[{productId:'pizza',qty:1}];const before=JSON.stringify(f.state.products);
 await f.c.saveProduct('dough');assert.equal(JSON.stringify(f.state.products),before);assert.equal(f.writes.length,0);assert.match(f.messages.at(-1),/Циклический состав/);
});
test('cannot delete or change type of a tracked product needed by an unreturned new receipt',async()=>{
 const f=fixture();f.sale();Object.assign(f.fields,{'pf-name':{value:'Мука'},'pf-category':{value:'Сырьё'},'pf-price':{value:'2'}});
 f.c._pmType='composite';f.c._pmComponents=[{productId:'water',qty:1}];const before=JSON.stringify(f.state.products);await f.c.saveProduct('flour');assert.equal(JSON.stringify(f.state.products),before);assert.match(f.messages.at(-1),/Нельзя изменить тип/);
 f.state.products=f.state.products.filter(p=>p.type==='simple');
 f.fields['delete-password']={value:html.match(/function confirmDelete[\s\S]*?pass!=='([^']+)'/)[1]};
 f.c.confirmDelete('product','flour');assert.ok(f.c.getProduct('flour'));assert.match(f.messages.at(-1),/Товар нужен для возврата/);
 assert.equal(f.c.hasUnreturnedStockConsumption('flour'),true);f.state.orders[0].returnedAt=1;assert.equal(f.c.hasUnreturnedStockConsumption('flour'),false);
});
test('insufficient stock blocks payment screen before card-terminal instruction',()=>{
 const f=fixture();f.cart();f.c.getProduct('flour').stock=0;let shown=false;f.c.renderPaymentScreen=()=>{shown=true;};f.c.openCardPartConfirmation=()=>{shown=true;};f.c.openPaymentModal();f.c.confirmPaymentScreen('card');assert.equal(shown,false);
});
test('print bridge still receives original receipt fields plus ignored stock snapshot',()=>{
 const f=fixture(),order=f.sale();let sent;f.c.sendOrderToPrint=o=>{sent=o;};f.c.printReceipt(order.id);
 assert.equal(sent.total,10);assert.equal(sent.items[0].productId,'pizza');assert.equal(sent.stockConsumption.version,1);
 assert.match(f.c.receiptBodyHtml(order),/Пицца/);
});

test('existing backup export/import retains new snapshot and old receipt without adding fields',()=>{
 const f=fixture(),order=f.sale();const legacy={id:'old',items:[],total:0};f.state.orders.push(legacy);let backup;
 f.c.Blob=class{constructor(parts){this.parts=parts;}};
 f.c.URL={createObjectURL:b=>{backup=JSON.parse(b.parts.join(''));return 'blob:test';},revokeObjectURL:()=>{}};
 f.c.document.createElement=()=>({click(){}});f.c.exportBackup();
 assert.deepEqual(backup.orders[0].stockConsumption,plain(order.stockConsumption));assert.equal('stockConsumption' in backup.orders[1],false);
 const restored=fixture();restored.c.FileReader=class{readAsText(file){this.result=file.text;this.onload();}};
 restored.c.document.createElement=()=>({files:[{text:JSON.stringify(backup)}],click(){this.onchange();}});
 restored.c.importBackup();assert.deepEqual(plain(restored.state.orders),backup.orders);
 restored.c.restoreOrderStock(restored.state.orders[0]);near(restored.c.getProduct('flour').stock,10);
});
test('valid nested recipe edit retains product ID and existing component shape',async()=>{
 const f=fixture();Object.assign(f.fields,{'pf-name':{value:'Пицца обновлённая'},'pf-category':{value:'Пицца'},'pf-price':{value:'10'}});
 f.c._pmType='composite';f.c._pmComponents=[{productId:'dough',qty:2},{productId:'flour',qty:0.1}];
 await f.c.saveProduct('pizza');assert.equal(f.c.getProduct('pizza').id,'pizza');assert.deepEqual(plain(f.c.getProduct('pizza').components),f.c._pmComponents);
 assert.ok(f.data.has('prilavok_products'));assert.equal(f.state.products.length,4);assert.match(f.messages.at(-1),/Товар сохранён/);
});


// v130.19 editor draft/save regression checks.
function editorFixture(){
 const f=fixture();Object.assign(f.fields,{'pf-name':{value:'Мука новая'},'pf-category':{value:'Сырьё'},'pf-price':{value:'3'},'pf-cost':{value:'2'},'pf-stock':{value:'10'},'pf-symbol':{value:''},'pf-no-stock':{checked:false}});
 f.c._pmType='simple';f.c._pmComponents=[];f.c._pmOnline=false;f.c._pmRemoveImage=false;f.c._pmImageData=null;
 return f;
}
test('editor draft snapshot notices changes without mutating saved product',()=>{
 const f=editorFixture(),before=JSON.stringify(f.state.products);f.c._pmInitial=f.c.productEditorSnapshot();
 assert.equal(f.c.productEditorDirty(),false);f.fields['pf-name'].value='Черновик';assert.equal(f.c.productEditorDirty(),true);
 f.fields['pf-name'].value='Мука новая';assert.equal(f.c.productEditorDirty(),false);f.c._pmOnline=true;assert.equal(f.c.productEditorDirty(),true);
 assert.equal(JSON.stringify(f.state.products),before);assert.equal(f.writes.length,0);
});
test('photo failure preserves existing product and does not create a new product',async()=>{
 for(const id of ['flour','']){
  const f=editorFixture(),before=JSON.stringify(f.state.products);f.c._pmImageData='data:image/jpeg;base64,AA';
  f.c.networkConfigFromState=()=>({backendUrl:'https://test.invalid',deviceKey:'test'});f.c.fetch=async()=>{throw Error('offline');};
  assert.equal(await f.c.saveProduct(id),undefined);assert.equal(JSON.stringify(f.state.products),before);assert.equal(f.writes.length,0);assert.match(f.messages.at(-1),/offline/);
 }
});
test('photo upload cannot overwrite a stock change occurring while save awaits network',async()=>{
 const f=editorFixture();f.c._pmImageData='data:image/jpeg;base64,AA';f.c.networkConfigFromState=()=>({backendUrl:'https://test.invalid',deviceKey:'test'});
 f.c.fetch=async()=>{f.c.getProduct('flour').stock=9;return {ok:true,json:async()=>({url:'test-image'})};};
 assert.equal(await f.c.saveProduct('flour'),undefined);assert.equal(f.c.getProduct('flour').stock,9);assert.equal(f.c.getProduct('flour').name,'Мука');assert.equal(f.writes.length,0);
});
test('ordinary product save uses original local key and preserves extra fields',async()=>{
 const f=editorFixture();f.c.getProduct('flour').futureField={keep:true};
 assert.equal(await f.c.saveProduct('flour'),true);assert.equal(f.c.getProduct('flour').id,'flour');assert.deepEqual(plain(f.c.getProduct('flour').futureField),{keep:true});
 assert.equal(JSON.parse(f.data.get('prilavok_products')).find(p=>p.id==='flour').name,'Мука новая');
 assert.equal(f.state.products.length,4);
});
test('usage shows direct and nested recipe links and escapes product names',()=>{
 const f=editorFixture();f.c.getProduct('dough').name='<Тесто>';const result=f.c.renderProductUsage('flour');
 assert.match(result,/&lt;Тесто&gt;/);assert.match(result,/Прямой состав/);assert.match(result,/Через другие составные товары/);
 assert.match(result,/Пицца/);assert.doesNotMatch(result,/<Тесто>/);
});
test('dirty back navigation waits for explicit save/discard decision',()=>{
 const f=editorFixture();f.c._pmInitial=f.c.productEditorSnapshot();f.fields['pf-name'].value='Черновик';let dialog='',finished=false;
 f.c.showModal=html=>{dialog=html;};f.c.finishProductEditor=()=>{finished=true;};f.c.requestCloseProductEditor('pizza');
 assert.equal(finished,false);assert.match(dialog,/Сохранить и продолжить/);assert.match(dialog,/Не сохранять/);f.c._pmExitAction();assert.equal(finished,true);
});

test('unit conversions accept mass/volume pairs and reject cross dimension conversions',()=>{
 const f=fixture();near(f.c.convertProductQty(250,'g','kg'),0.25);near(f.c.convertProductQty(1.5,'l','ml'),1500);
 near(f.c.convertProductQty(7,'',''),7);assert.throws(()=>f.c.convertProductQty(1,'kg','l'));assert.throws(()=>f.c.convertProductQty(1,'piece','g'));
});
test('recipe input grams normalizes to original kg; sale and return preserve snapshot',()=>{
 const f=fixture();f.c.getProduct('flour').stockUnit='kg';f.c._pmComponents=[{productId:'flour',qty:0.2,displayUnit:'g'}];f.c.renderTypeFields=()=>{};
 f.c.setComponentQty(0,'250');near(f.c._pmComponents[0].qty,0.25);near(f.c.componentDisplayQty(f.c._pmComponents[0]),250);
 f.c.getProduct('pizza').components=plain(f.c._pmComponents);const order=f.sale();near(f.c.getProduct('flour').stock,9.75);near(order.stockConsumption.items[0].qty,0.25);
 f.c.getProduct('flour').stockDisplayUnit='g';f.c.restoreOrderStock(order);near(f.c.getProduct('flour').stock,10);
});
test('unit selector changes presentation without changing recipe consumption',()=>{
 const f=fixture();f.c.getProduct('water').stockUnit='l';f.c._pmComponents=[{productId:'water',qty:0.15}];f.c.renderTypeFields=()=>{};
 f.c.changeComponentDisplayUnit(0,'ml');near(f.c._pmComponents[0].qty,0.15);near(f.c.componentDisplayQty(f.c._pmComponents[0]),150);
 f.c.changeComponentDisplayUnit(0,'kg');assert.equal(f.c._pmComponents[0].displayUnit,'ml');
});
test('stock display conversion saves stock/cost/minimum in unchanged base units',async()=>{
 const f=editorFixture();Object.assign(f.c.getProduct('flour'),{stockUnit:'kg',stockDisplayUnit:'kg'});
 f.c._pmBaseUnit='kg';f.c._pmUnit='g';f.fields['pf-stock'].value='10000';f.fields['pf-cost'].value='0.002';f.fields['pf-min-stock']={value:'500'};
 assert.equal(await f.c.saveProduct('flour'),true);const p=f.c.getProduct('flour');near(p.stock,10);near(p.cost,2);near(p.minStock,0.5);assert.equal(p.stockUnit,'kg');assert.equal(p.stockDisplayUnit,'g');
});
test('first explicit unit assignment retains legacy stock/cost/recipe quantities',async()=>{
 const f=editorFixture(),recipe=JSON.stringify(f.c.getProduct('dough').components);f.c._pmBaseUnit='kg';f.c._pmUnit='kg';
 await f.c.saveProduct('flour');near(f.c.getProduct('flour').stock,10);near(f.c.getProduct('flour').cost,2);assert.equal(JSON.stringify(f.c.getProduct('dough').components),recipe);
});
test('legacy ordinary save does not add unit fields',async()=>{
 const f=editorFixture();await f.c.saveProduct('flour');assert.equal('stockUnit' in f.c.getProduct('flour'),false);assert.equal('stockDisplayUnit' in f.c.getProduct('flour'),false);
});
test('configuration persists locally and internal note never enters menu payload',async()=>{
 const f=editorFixture();f.fields['pf-sku']={value:' RAW-001 '};f.fields['pf-note']={value:' Секрет рецептуры '};f.fields['pf-min-stock']={value:'2'};
 await f.c.saveProduct('flour');const saved=JSON.parse(f.data.get('prilavok_products')).find(p=>p.id==='flour');assert.equal(saved.sku,'RAW-001');assert.equal(saved.internalNote,'Секрет рецептуры');near(saved.minStock,2);
 assert.doesNotMatch(JSON.stringify(f.c.buildMenuSyncPayload()),/Секрет рецептуры|internalNote/);
});
test('negative minimum is rejected before local mutation',async()=>{
 const f=editorFixture();f.fields['pf-min-stock']={value:'-1'};const before=JSON.stringify(f.state.products);await f.c.saveProduct('flour');assert.equal(JSON.stringify(f.state.products),before);assert.equal(f.writes.length,0);
});
test('configured base unit cannot be replaced with another unit',async()=>{
 const f=editorFixture();f.c.getProduct('flour').stockUnit='kg';f.c._pmBaseUnit='g';f.c._pmUnit='g';const before=JSON.stringify(f.state.products);await f.c.saveProduct('flour');assert.equal(JSON.stringify(f.state.products),before);
});


test('card unit switch converts cost, stock and minimum while preserving base',()=>{
 const f=editorFixture();f.c._pmBaseUnit='kg';f.c._pmUnit='kg';f.fields['pf-min-stock']={value:'0.5'};f.c.renderTypeFields=()=>{};
 f.c.changeProductDisplayUnit('g');near(f.fields['pf-stock'].value,10000);near(f.fields['pf-cost'].value,0.002);near(f.fields['pf-min-stock'].value,500);assert.equal(f.c._pmBaseUnit,'kg');
 f.c.changeProductDisplayUnit('kg');near(f.fields['pf-stock'].value,10);near(f.fields['pf-cost'].value,2);
});
test('new configuration and recipe display unit survive loadAll restart',async()=>{
 const f=editorFixture();f.c._pmUnit='kg';f.c._pmBaseUnit='kg';f.fields['pf-sku']={value:'F1'};f.fields['pf-note']={value:'test'};f.fields['pf-min-stock']={value:'1'};
 await f.c.saveProduct('flour');f.c.getProduct('dough').components[0].displayUnit='g';await f.c.saveKey('products',f.state.products);
 const next=fixture();for(const [k,v] of f.data)next.data.set(k,v);await next.c.loadAll();assert.deepEqual(plain(next.c.getProduct('flour')),plain(f.c.getProduct('flour')));assert.deepEqual(plain(next.c.getProduct('dough').components),plain(f.c.getProduct('dough').components));near(next.c.componentDisplayQty(next.c.getProduct('dough').components[0]),200);
});

// Supplier order / TTN workflow uses synthetic local state only.
test('supplier requests preserve packages independently from expected warehouse quantity',()=>{
 const f=fixture(),p=f.c.getProduct('flour');p.stockUnit='kg';
 const unknown=f.c.makePurchaseLine(p,4,'pack','');assert.equal(unknown.qty,0);assert.equal(unknown.expectedQty,null);assert.equal(f.c.requestedQuantityText(unknown),'4 упаковка');
 const known=f.c.makePurchaseLine(p,4,'pack',2.5);near(known.expectedQty,10);near(known.requestedQty,4);
 near(f.c.makePurchaseLine(p,20000,'g','').expectedQty,20);assert.throws(()=>f.c.makePurchaseLine(p,2,'l',''));assert.throws(()=>f.c.makePurchaseLine(p,2,'box',-1));
});
test('invoice normalizes grams and uses invoice total as acquisition cost',()=>{
 const f=fixture();f.c.getProduct('flour').stockUnit='kg';
 const [item]=f.c.invoiceReceivingItems({lines:[{productId:'flour',qtyInput:'1500',unit:'g',totalInput:'30'}]});near(item.qty,1.5);near(item.unitCost,20);near(item.invoiceUnitPrice,0.02);
});
test('weighted cost is 16 for 2 kg at 10 plus 3 kg at 20',()=>{
 const f=fixture();Object.assign(f.c.getProduct('flour'),{stock:2,cost:10});
 const [u]=f.c.receivingStockUpdates([{productId:'flour',qty:3,totalCost:60}]);near(u.stock,5);near(u.cost,16);near(f.c.getProduct('flour').stock,2);
});
test('small unit costs retain precision and duplicate invoice lines accumulate',()=>{
 const f=fixture();Object.assign(f.c.getProduct('flour'),{stock:2000,cost:0.002});
 const [u]=f.c.receivingStockUpdates([{productId:'flour',qty:1000,totalCost:3},{productId:'flour',qty:2000,totalCost:5}]);near(u.stock,5000);near(u.cost,0.0024);
});
test('incomplete or invalid invoice never generates stock updates',()=>{
 const f=fixture();for(const line of [{productId:'flour',qtyInput:'',totalInput:'3',unit:''},{productId:'flour',qtyInput:'-1',totalInput:'3',unit:''},{productId:'flour',qtyInput:'0',totalInput:'3',unit:''},{productId:'missing',qtyInput:'2',totalInput:'3',unit:''}])assert.throws(()=>f.c.invoiceReceivingItems({lines:[line]}));
 const zero=f.c.invoiceReceivingItems({lines:[{productId:'flour',qtyInput:'0',totalInput:'0',unit:''}]});assert.equal(f.c.receivingStockUpdates(zero).length,0);
});
test('quantity/price/total editing recalculates invoice fields',()=>{
 const f=fixture();f.c._receivingDraft={lines:[{qtyInput:'2',unit:'kg',priceInput:'10',totalInput:'20',priceMode:'price'}]};
 f.c.updateInvoiceLine(0,'qtyInput','3');near(f.c._receivingDraft.lines[0].totalInput,30);
 f.c.updateInvoiceLine(0,'totalInput','60');near(f.c._receivingDraft.lines[0].priceInput,20);
 f.c.updateInvoiceLine(0,'unit','g');near(f.c._receivingDraft.lines[0].qtyInput,3000);near(f.c._receivingDraft.lines[0].priceInput,0.02);near(f.c._receivingDraft.lines[0].totalInput,60);
});
test('unknown package weight is not falsely compared to warehouse units',()=>{
 const f=fixture();const order={items:[{productId:'flour',qty:0,expectedQty:null,requestedQty:4,requestedUnit:'pack'}]};
 assert.equal(f.c.receivingDiscrepancy(order,[{productId:'flour',qty:7.7}]),false);assert.equal(f.c.receivingDiscrepancy(order,[{productId:'flour',qty:0}]),true);
 assert.equal(f.c.receivingDiscrepancy({items:[{productId:'flour',qty:10}]},[{productId:'flour',qty:8}]),true);
});
function invoiceFixture(){
 const f=fixture();f.state.suppliers=[{id:'supplier',name:'Поставщик',productIds:['flour']}];f.state.purchaseOrders=[{id:'purchase',supplierId:'supplier',supplierName:'Поставщик',items:[{productId:'flour',qty:3}],status:'pending'}];f.state.receivings=[];
 f.c._receivingPending={orderId:'purchase',draft:{invoiceNumber:'ТТН-001',invoiceDate:'2026-09-14',supplierId:'supplier',lines:[{productId:'flour',qtyInput:'3',unit:'',totalInput:'60'}]}};return f;
}
test('confirmation applies current weighted cost once and persists TTN history',()=>{
 const f=invoiceFixture();Object.assign(f.c.getProduct('flour'),{stock:2,cost:10});
 f.c.applyReceivingDocument();near(f.c.getProduct('flour').stock,5);near(f.c.getProduct('flour').cost,16);assert.equal(f.state.receivings.length,1);assert.equal(f.state.receivings[0].invoiceNumber,'ТТН-001');assert.equal(f.state.purchaseOrders[0].status,'received');
 f.c.applyReceivingDocument();assert.equal(f.state.receivings.length,1);near(f.c.getProduct('flour').stock,5);assert.ok(f.data.has('prilavok_receivings'));
});
test('deleted order cannot be received and missing product cannot partially apply TTN',()=>{
 const f=invoiceFixture();f.state.purchaseOrders[0].status='deleted';const before=JSON.stringify(f.state);f.c.applyReceivingDocument();assert.equal(JSON.stringify(f.state),before);
 const g=invoiceFixture();g.c._receivingPending.draft.lines.push({productId:'missing',qtyInput:'2',unit:'',totalInput:'3'});const original=JSON.stringify(g.state);g.c.applyReceivingDocument();assert.equal(JSON.stringify(g.state),original);
});
test('cost cannot be manually changed in an existing product save',async()=>{
 const f=editorFixture();f.fields['pf-cost'].value='999';await f.c.saveProduct('flour');near(f.c.getProduct('flour').cost,2);
});
test('text and native share payload preserve fractional package request',()=>{
 const f=fixture();const order={id:'p',supplierName:'Supplier',items:[{productId:'flour',productName:'Мука',qty:0,requestedQty:1.5,requestedUnit:'box'}],timestamp:1};f.state.purchaseOrders=[order];
 assert.match(f.c.purchaseOrderText(order),/1.5 коробка/);let payload;f.c.webkit={messageHandlers:{printer:{postMessage:p=>payload=p}}};f.c.sharePurchaseOrder('p');assert.equal(payload.order.items[0].qty,1.5);assert.equal(payload.order.items[0].quantityText,'1.5 коробка');
});
test('standalone invoice has same cost calculation and no purchase order requirement',()=>{
 const f=invoiceFixture();f.c._receivingPending.orderId=null;f.c.applyReceivingDocument();near(f.c.getProduct('flour').stock,13);near(f.c.getProduct('flour').cost,80/13);assert.equal(f.state.receivings[0].type,'purchase');assert.equal(f.state.purchaseOrders[0].status,'pending');
});

test('standalone TTN draft is local and can be reopened without applying stock',async()=>{
 const f=invoiceFixture(),before=JSON.stringify(f.state.products);f.c._receivingDraft={version:1,orderId:null,supplierId:'supplier',invoiceNumber:'DRAFT',invoiceDate:'',lines:[{productId:'flour',qtyInput:'2',unit:'',priceInput:'3',totalInput:'6',priceMode:'total'}]};
 f.c.receivingDocumentInput=()=>{};f.c.renderReceivingDocument=()=>{};await f.c.saveReceivingDraft();assert.equal(JSON.stringify(f.state.products),before);assert.ok(f.data.has('prilavok_receivingDraft'));
 f.c._receivingDraft=null;await f.c.openReceivingDocument();assert.equal(f.c._receivingDraft.invoiceNumber,'DRAFT');assert.equal(f.c._receivingDraft.lines[0].qtyInput,'2');
});
test('legacy receiving draft opens with unchanged amounts and no stock mutation',async()=>{
 const f=invoiceFixture(),before=JSON.stringify(f.state.products);f.state.purchaseOrders[0].receivingDraft={flour:{qty:2,totalCost:'14'}};f.c.renderReceivingDocument=()=>{};
 await f.c.openReceivingDocument('purchase');assert.equal(f.c._receivingDraft.lines[0].qtyInput,2);assert.equal(f.c._receivingDraft.lines[0].totalInput,'14');assert.equal(JSON.stringify(f.state.products),before);
});
test('backup export preserves TTN invoice and original normalized amounts',()=>{
 const f=invoiceFixture();f.c.applyReceivingDocument();let backup;f.c.Blob=class{constructor(parts){this.parts=parts;}};f.c.URL={createObjectURL:b=>{backup=JSON.parse(b.parts.join(''));return 'blob:test';},revokeObjectURL:()=>{}};f.c.document.createElement=()=>({click(){}});f.c.exportBackup();
 assert.equal(backup.receivings[0].invoiceNumber,'ТТН-001');near(backup.receivings[0].items[0].qty,3);near(backup.receivings[0].items[0].totalCost,60);
});


test('supply sections have matching vertical controls and render inline invoice',()=>{
 const f=invoiceFixture();f.state.purchaseOrderCart=[];f.state.purchaseOrderSupplierId='supplier';
 const orders=f.c.renderPurchaseOrdersScreen(),receiving=f.c.renderReceivingScreen();
 assert.match(orders,/supply-stack-actions/);assert.match(receiving,/supply-stack-actions/);assert.doesNotMatch(orders,/content-title/);assert.doesNotMatch(receiving,/content-title/);
 assert.match(orders,/purchase-expand-panel/);assert.match(receiving,/receiving-inline-panel/);
 f.c._receivingDraft={supplierId:'supplier',invoiceNumber:'',invoiceDate:'',lines:[]};assert.match(f.c.receivingDocumentMarkup(),/ttn-number/);
});
test('inline receiving renders without a modal and can collapse without losing draft',()=>{
 const f=fixture();let expanded;f.c._receivingDraft={supplierId:'',invoiceNumber:'DRAFT',invoiceDate:'',lines:[]};
 f.fields['receiving-inline-panel']={innerHTML:'',hidden:true,scrollIntoView(){}};f.fields['receiving-expand-button']={setAttribute(k,v){expanded=v;}};
 f.c.renderReceivingDocument();assert.equal(expanded,'true');assert.match(f.fields['receiving-inline-panel'].innerHTML,/DRAFT/);assert.equal(f.fields['receiving-inline-panel'].hidden,false);
 f.c.toggleReceivingPanel();assert.equal(f.fields['receiving-inline-panel'].hidden,true);assert.equal(f.c._receivingDraft.invoiceNumber,'DRAFT');
});


test('purchase history includes older entries and all requested status labels',()=>{
 const f=fixture();f.state.purchaseOrders=Array.from({length:60},(_,i)=>({id:String(i),timestamp:i,supplierName:'Supplier',items:[],status:i===0?'deleted':i<3?'received':'pending',shortage:i===1}));
 const markup=f.c.purchaseHistoryMarkup();assert.equal((markup.match(/purchase-history-row/g)||[]).length,60);
 for(const label of ['Удалено администратором','Ожидается приёмка','Принят','Недовоз'])assert.ok(markup.includes(label));
});
test('quantity keypad supports replacement, decimal, backspace and clear without changing order',()=>{
 const f=fixture();f.state.purchaseOrderCart=[];f.c._purchaseQuantity={productId:'flour',value:'8',replace:true};
 f.c.purchaseQuantityKey('1');f.c.purchaseQuantityKey(',');f.c.purchaseQuantityKey('5');assert.equal(f.c._purchaseQuantity.value,'1.5');f.c.purchaseQuantityKey(',');assert.equal(f.c._purchaseQuantity.value,'1.5');
 f.c.purchaseQuantityKey('⌫');assert.equal(f.c._purchaseQuantity.value,'1.');f.c.purchaseQuantityKey('clear');assert.equal(f.c._purchaseQuantity.value,'');assert.equal(f.state.purchaseOrderCart.length,0);
});
test('quantity keypad commits to existing order input only on Done',()=>{
 const f=fixture(),input={value:'8'};let updated;f.c.document.querySelectorAll=()=>[{dataset:{purchaseRow:'flour'},querySelector:()=>input}];f.c.updatePurchaseRequest=id=>{updated=id;};
 f.c._purchaseQuantity={productId:'flour',value:'1.5',replace:false};assert.equal(input.value,'8');f.c.applyPurchaseQuantity();assert.equal(input.value,'1.5');assert.equal(updated,'flour');assert.equal(f.c._purchaseQuantity,null);
});


test('package keypad shares numeric input without changing requested order quantity',()=>{
 const f=fixture(),qty={value:'4'},size={value:'2'};let html='';f.c.showModal=value=>{html=value;};f.c.document.querySelectorAll=()=>[{dataset:{purchaseRow:'flour'},querySelector:s=>s==='[data-request-size]'?size:qty}];f.c.updatePurchaseRequest=()=>{};
 f.c.openPurchaseQuantity('flour','size');assert.match(html,/В упаковке/);assert.doesNotMatch(html,/>Отмена</);
 f.c.purchaseQuantityKey('1');f.c.purchaseQuantityKey(',');f.c.purchaseQuantityKey('5');f.c.applyPurchaseQuantity();assert.equal(size.value,'1.5');assert.equal(qty.value,'4');
});

test('opening supply pre-fills ordered base quantity and persists started draft without stock change',async()=>{
 const f=invoiceFixture(),before=JSON.stringify(f.state.products);f.c.renderReceivingDocument=()=>{};
 await f.c.openReceivingDocument('purchase');assert.equal(f.c._receivingDraft.lines[0].qtyInput,3);assert.equal(f.state.purchaseOrders[0].receivingIncomplete,true);assert.equal(JSON.stringify(f.state.products),before);assert.ok(JSON.parse(f.data.get('prilavok_purchaseOrders'))[0].receivingDraftV2);
 assert.doesNotMatch(f.c.receivingDocumentMarkup(),/ttn-add-product/);assert.match(f.c.receivingDocumentMarkup(),/Завершить приёмку позже/);
});
test('unknown pack weight stays blank and saved zero quantity is retained',async()=>{
 const f=invoiceFixture();f.state.purchaseOrders[0].items[0].expectedQty=null;f.c.renderReceivingDocument=()=>{};
 await f.c.openReceivingDocument('purchase');assert.equal(f.c._receivingDraft.lines[0].qtyInput,'');f.state.purchaseOrders[0].receivingDraftV2.lines[0].qtyInput=0;
 await f.c.openReceivingDocument('purchase');assert.equal(f.c._receivingDraft.lines[0].qtyInput,0);
});
test('supply opens independent page and excludes duplicate inline fields',()=>{
 const f=invoiceFixture();f.c._receivingDraft={...f.c._receivingPending.draft,orderId:'purchase'};
 f.fields['receiving-page-root']={innerHTML:''};f.fields.app={inert:false};f.fields['receiving-inline-panel']={innerHTML:'old',hidden:false};
 f.c.renderReceivingDocument();assert.equal(f.fields.app.inert,true);assert.match(f.fields['receiving-page-root'].innerHTML,/Приёмка поставки/);assert.equal(f.fields['receiving-inline-panel'].innerHTML,'');assert.equal(f.fields['receiving-inline-panel'].hidden,true);
 f.c.finishReceivingPage();assert.equal(f.fields.app.inert,false);assert.equal(f.fields['receiving-page-root'].innerHTML,'');
});

function warehouseFixture(){
 const f=fixture();f.state.products=[{id:'flour',name:'Мука',type:'simple',stockUnit:'kg',stock:10,cost:2,minStock:3}];f.state.receivings=[];f.state.orders=[];
 const ts=day=>new Date(2026,8,day,12).getTime();return {...f,ts};
}
test('warehouse report filters movement dates and reconstructs boundaries from current balance',()=>{
 const f=warehouseFixture();f.state.receivings=[{id:'r1',timestamp:f.ts(3),items:[{productId:'flour',qty:4,totalCost:20,stockUnit:'kg'}]},{id:'r2',timestamp:f.ts(10),items:[{productId:'flour',qty:3,totalCost:12,stockUnit:'kg'}]}];
 f.state.orders=[{timestamp:f.ts(5),items:[{productId:'pizza',qty:1,cost:9}],stockConsumption:{version:1,items:[{productId:'flour',qty:1}]}},{timestamp:f.ts(11),stockConsumption:{version:1,items:[{productId:'flour',qty:1}]}}];
 const before=JSON.stringify(f.state),report=f.c.warehouseReport('2026-09-01','2026-09-07',f.ts(14)),row=report.rows[0];near(row.incoming,4);near(row.outgoing,1);near(row.start,5);near(row.end,8);near(report.incomingValue,20);near(report.outgoingValue,2);near(report.recordedSalesCost,9);assert.equal(report.documents.length,1);assert.equal(JSON.stringify(f.state),before);assert.equal(f.writes.length,0);
});
test('warehouse return is counted by return date even for a sale before the period',()=>{
 const f=warehouseFixture();f.state.orders=[{timestamp:new Date(2026,7,20).getTime(),returnedAt:f.ts(4),stockConsumption:{version:1,items:[{productId:'flour',qty:2}]}}];
 const r=f.c.warehouseReport('2026-09-01','2026-09-07',f.ts(14));near(r.rows[0].returned,2);near(r.rows[0].outgoing,0);
});
test('warehouse legacy receipts are flagged and never reconstructed using current recipe',()=>{
 const f=warehouseFixture();f.state.orders=[{timestamp:f.ts(3),items:[{productId:'flour',qty:9}]}];const r=f.c.warehouseReport('2026-09-01','2026-09-07',f.ts(14));assert.equal(r.warnings.legacySales,1);near(r.rows[0].outgoing,0);assert.ok(f.c.warehouseNotes(r).join(' ').includes('не восстановлены'));
});
test('deleted receiving audit records do not become inventory arrivals',()=>{
 const f=warehouseFixture();f.state.receivings=[{id:'x',timestamp:f.ts(3),adminDeleted:true,items:[{productId:'flour',qty:100,totalCost:1000}]}];const r=f.c.warehouseReport('2026-09-01','2026-09-07',f.ts(14));near(r.incomingValue,0);assert.equal(r.documents.length,0);
});
test('removed product is retained in report without inventing current balance or cost',()=>{
 const f=warehouseFixture();f.state.orders=[{timestamp:f.ts(3),stockConsumption:{version:1,items:[{productId:'deleted',qty:2}]}}];const r=f.c.warehouseReport('2026-09-01','2026-09-07',f.ts(14));const row=r.rows.find(x=>x.id==='deleted');assert.equal(row.current,null);assert.equal(row.outgoingValue,null);assert.equal(r.warnings.unknownCosts,1);
});
test('warehouse units are grouped compatibly, never kg plus litres',()=>{
 const f=fixture();const text=f.c.warehouseQuantityTotals({rows:[{unit:'kg',incoming:1},{unit:'g',incoming:500},{unit:'l',incoming:2}]},'incoming');assert.match(text,/1,5 кг/);assert.match(text,/2 л/);
});
test('warehouse export includes limitations, period and receipt registry with no new storage writes',()=>{
 const f=warehouseFixture();const r=f.c.warehouseReport('2026-09-01','2026-09-07',f.ts(14)),all=f.c.warehouseExportPayload(r),docs=f.c.warehouseExportPayload(r,true);
 assert.equal(all.period,'2026-09-01 — 2026-09-07');assert.equal(docs.sections.length,1);assert.match(all.notes.join(' '),/Ручные изменения/);assert.equal(f.writes.length,0);
});
test('warehouse rejects invalid dates and export cannot bypass admin access',()=>{
 const f=fixture();assert.throws(()=>f.c.warehouseRange('2026-02-30','2026-03-01'));assert.throws(()=>f.c.warehouseRange('2026-09-07','2026-09-01'));let sent=false;f.c.currentShiftEmployeeIsAdmin=()=>false;f.c.webkit={messageHandlers:{printer:{postMessage:()=>{sent=true;}}}};f.c.exportWarehousePDF();assert.equal(sent,false);
});

test('warehouse selected export keeps only requested sections and numeric Excel cells',()=>{
 const f=warehouseFixture();f.state.receivings=[{id:'r',timestamp:f.ts(3),supplierName:'=SUM(1,2)',invoiceNumber:'001',items:[{productId:'flour',qty:1.25,totalCost:7.5,stockUnit:'kg'}]}];
 const before=JSON.stringify(f.state),r=f.c.warehouseReport('2026-09-01','2026-09-07',f.ts(14));
 for(let i=0;i<5;i++){const p=f.c.warehouseSelectedPayload(r,[i]);assert.equal(p.sections.length,1);assert.ok(p.notes.length>0);assert.ok(p.sections[0].excelRows);}
 const p=f.c.warehouseSelectedPayload(r,[2,4]);assert.equal(p.sections[0].excelRows[0][2],1.25);assert.equal(p.sections[1].excelRows[0][1],'001');assert.equal(p.sections[1].excelRows[0][4],7.5);assert.equal(JSON.stringify(f.state),before);assert.equal(f.writes.length,0);
 assert.throws(()=>f.c.warehouseSelectedPayload(r,[]),/Выберите/);
});
test('warehouse generation routes selected format and blocks invalid or unauthorized export',()=>{
 const f=warehouseFixture();let sent=[];const fields={'warehouse-from':{value:'2026-09-01'},'warehouse-to':{value:'2026-09-07'},'warehouse-report-format':{value:'xlsx'}};
 f.c.currentShiftEmployeeIsAdmin=()=>true;f.c.document.getElementById=id=>fields[id];f.c.document.querySelectorAll=()=>[{value:'3'}];f.c.webkit={messageHandlers:{printer:{postMessage:p=>sent.push(p)}}};f.c.renderWarehousePage=()=>{};f.c.closeModal=()=>{};
 f.c.generateWarehouseReport();assert.equal(sent[0].action,'shareWarehouseExcel');assert.equal(sent[0].report.sections.length,1);
 fields['warehouse-report-format'].value='pdf';f.c.generateWarehouseReport();assert.equal(sent[1].action,'shareWarehouseReport');
 fields['warehouse-report-format'].value='bad';f.c.generateWarehouseReport();assert.equal(sent.length,2);
 f.c.currentShiftEmployeeIsAdmin=()=>false;f.c.generateWarehouseReport();assert.equal(sent.length,2);assert.equal(f.writes.length,0);
});

test('simplified warehouse combines suppliers without duplicating movement or balance',()=>{
 const f=warehouseFixture();f.state.receivings=[
 {timestamp:f.ts(3),supplierName:'Б',items:[{productId:'flour',qty:2,totalCost:4}]},
 {timestamp:f.ts(4),supplierName:'А',items:[{productId:'flour',qty:3,totalCost:6}]},
 {timestamp:f.ts(5),supplierName:'А',items:[{productId:'flour',qty:1,totalCost:2}]},
 {timestamp:f.ts(10),supplierName:'Вне периода',items:[{productId:'flour',qty:4,totalCost:8}]},
 {timestamp:f.ts(5),supplierName:'Удалён',adminDeleted:true,items:[{productId:'flour',qty:5,totalCost:10}]}];
 f.state.orders=[{timestamp:f.ts(6),stockConsumption:{version:1,items:[{productId:'flour',qty:2}]}}];
 const before=JSON.stringify(f.state),r=f.c.warehouseReport('2026-09-01','2026-09-07',f.ts(14)),p=f.c.warehouseSelectedPayload(r,[0,1,2,3,4]);
 assert.equal(p.sections[0].title,'Упрощённый учёт');const rows=p.sections[0].excelRows;assert.equal(rows.length,1);assert.equal(rows[0][0],'А, Б');assert.equal(rows[0][3],6);assert.equal(rows[0][4],2);assert.equal(rows[0][5],6);
 assert.equal(JSON.stringify(f.state),before);assert.equal(f.writes.length,0);
});
test('simplified warehouse keeps old stock without attributing it to a current supplier',()=>{
 const f=warehouseFixture(),r=f.c.warehouseReport('2026-09-01','2026-09-07',f.ts(14)),s=f.c.warehouseSimpleSection(r);
 assert.equal(s.excelRows[0][0],'—');assert.equal(s.excelRows[0][3],0);assert.equal(s.excelRows[0][5],10);
 assert.equal(f.c.warehouseSelectedPayload(r,[0]).sections.length,1);
 f.state.products=[];assert.equal(f.c.warehouseSimpleSection(f.c.warehouseReport('2026-09-01','2026-09-07',f.ts(14))).rows.length,0);
});

test('CSV import parses BOM, quoted commas, escaped quotes, multiline fields and semicolons',()=>{
 const f=fixture();const r=f.c.parseProductCSV('\uFEFFНазвание,Категория,Описание\r\n"*Виски [Wild West 0,5]",Алкоголь,"текст\nстрока ""два"""\r\n');assert.equal(r.length,1);assert.equal(r[0].name,'*Виски [Wild West 0,5]');assert.equal(f.c.parseProductCSV('Название;Категория\nЧай;Напитки')[0].name,'Чай');
 assert.throws(()=>f.c.parseProductCSV('Название,Категория\n"Чай,Напитки'));assert.throws(()=>f.c.parseProductCSV('Название,Категория\nЧай'));assert.throws(()=>f.c.parseProductCSV('Цена\n20'));
});
test('import normalizes names, matches existing categories only and separates raw ingredients',()=>{
 const f=fixture();f.state.categoryOrder=['Пицца','Коктейли'];
 const p=f.c.planProductImport([{name:'#Айс [350]❄️',category:'Коктейли'},{name:'Фри',category:'Закуски'},{name:'Фри',category:'Сырье'},{name:'Мука',category:'Другое'}]);
 assert.equal(p.add.length,3);assert.equal(p.add[0].name,'Айс 350');assert.equal(p.add[0].category,'Коктейли');assert.equal(p.add[1].category,'');assert.equal(p.add[2].name,'Фри (сырьё)');assert.equal(p.skipped[0],'Мука');assert.equal(f.writes.length,0);
});
function importFixture(){const f=fixture();f.fields.app={inert:false};f.fields['product-import-confirm']={disabled:false};f.c._productImportEntries=[{name:'Новый товар',category:'Нет категории'}];f.c._productImportPreview=JSON.stringify(f.c.planProductImport(f.c._productImportEntries).add);return f;}
test('import adds only name/category defaults and persists before publishing state',async()=>{
 const f=importFixture(),old=JSON.stringify(f.state.products),orders=JSON.stringify(f.state.orders);await f.c.confirmProductImport();
 assert.equal(JSON.stringify(f.state.products.slice(0,-1)),old);assert.equal(JSON.stringify(f.state.orders),orders);
 const p=f.state.products.at(-1);assert.equal(p.name,'Новый товар');assert.equal(p.category,'');assert.equal(p.price,0);assert.equal(p.stock,0);assert.equal(p.availableOnline,false);assert.equal(p.stockUnit,undefined);assert.equal(p.components,undefined);assert.deepEqual(f.writes,['prilavok_products']);assert.equal(f.fields.app.inert,false);
 const plan=f.c.planProductImport([{name:'Новый товар',category:''}]);assert.equal(plan.add.length,0);
});
test('failed import storage write leaves existing products intact and permits retry',async()=>{
 const f=importFixture(),before=JSON.stringify(f.state.products);f.c.localStorage.setItem=()=>{throw Error('quota');};await f.c.confirmProductImport();assert.equal(JSON.stringify(f.state.products),before);assert.equal(f.c._productImportBusy,false);assert.equal(f.fields.app.inert,false);assert.match(f.messages.at(-1),/не сохранён/);assert.equal(f.fields['product-import-confirm'].disabled,false);
});
test('import rechecks changed products before saving and double click cannot duplicate writes',async()=>{
 const f=importFixture();f.state.products.push({id:'added',name:'Новый товар'});let preview=false;f.c.previewProductImport=()=>{preview=true;};await f.c.confirmProductImport();assert.ok(preview);assert.equal(f.writes.length,0);
 const g=importFixture();await Promise.all([g.c.confirmProductImport(),g.c.confirmProductImport()]);assert.equal(g.writes.length,1);assert.equal(g.state.products.filter(p=>p.name==='Новый товар').length,1);
});

test('CSV prices support decimals and old exports, reject invalid amounts',()=>{
 const f=fixture();const rows=f.c.parseProductCSV('Название,Цена [PROJECT]\nТовар,14.31\nДругой,изменяемая');assert.equal(rows[0].price,14.31);assert.equal(rows[1].price,null);
 assert.equal(f.c.importedProductPrice('3,50'),3.5);assert.equal(f.c.importedProductPrice('0.01'),0.01);assert.equal(f.c.importedProductPrice(''),null);
 for(const v of ['-1','NaN','Infinity','1e3','12abc','1.234'])assert.throws(()=>f.c.importedProductPrice(v));
});
test('CSV imported selling price persists without importing costs or overwriting existing products',async()=>{
 const f=importFixture();f.c._productImportEntries=[{name:'Новый товар',price:14.31,category:''}];f.c._productImportPreview=JSON.stringify(f.c.planProductImport(f.c._productImportEntries).add);
 await f.c.confirmProductImport();const p=f.state.products.at(-1);assert.equal(p.price,14.31);assert.equal(p.cost,0);assert.equal(p.stock,0);assert.equal(JSON.parse(f.data.get('prilavok_products')).at(-1).price,14.31);
 assert.equal(f.c.planProductImport([{name:'Новый товар',price:100}]).add.length,0);assert.equal(p.price,14.31);
});

test('product search matches names and categories with Unicode and case normalization',()=>{
 const f=fixture();assert.ok(f.c.productMatchesSearch({name:'Айс-латте',category:'Горячие напитки'},f.c.productSearchText('АЙС')));assert.ok(f.c.productMatchesSearch({name:'Вода',category:'Сырьё'},f.c.productSearchText('  сырье  ')));assert.equal(f.c.productMatchesSearch({name:'Вода',category:'Напитки',price:123,sku:'secret'},'secret'),false);
});
test('live product search updates rows, counts and empty state then restores all rows without rerender',()=>{
 const f=fixture();const rows=[{dataset:{productSearch:'маргарита пицца'},style:{}},{dataset:{productSearch:'чай горячие напитки'},style:{}}],badge={},clear={style:{}},table={style:{}},empty={style:{}};
 const card={querySelectorAll:selector=>{assert.equal(selector,'.products-table-row');return rows;},querySelector:selector=>selector.includes('badge')?badge:clear};
 f.fields['products-search']={value:'пицца',closest:()=>card,focus:()=>{}};f.fields['products-search-table']=table;f.fields['products-search-empty']=empty;f.c.render=()=>{throw Error('must preserve input focus');};
 f.c.filterProductsScreen();assert.equal(rows[0].style.display,'');assert.equal(rows[1].style.display,'none');assert.equal(badge.textContent,'1 / 4');
 f.fields['products-search'].value='ничего';f.c.filterProductsScreen();assert.equal(empty.style.display,'');assert.equal(table.style.display,'none');
 f.c.clearProductsSearch();assert.ok(rows.every(r=>r.style.display===''));assert.equal(empty.style.display,'none');assert.equal(table.style.display,'');assert.equal(clear.style.display,'none');
});
test('rendered filtered product screen retains hidden rows for subsequent broader searches',()=>{
 const f=fixture();f.state.productsSearch='мука';const html=f.c.renderProductsScreen();assert.equal((html.match(/data-product-search=/g)||[]).length,4);assert.match(html,/id="products-search-empty"/);assert.match(html,/Название или категория/);
});

test('product sorting uses numbers, toggles direction and never changes stored product order',()=>{
 const f=fixture();f.state.products=[{id:'a',name:'А',type:'simple',price:100,stock:3},{id:'b',name:'Б',type:'simple',price:9,stock:1},{id:'c',name:'В',type:'simple',price:20,stock:0,noStockTracking:true}];const before=JSON.stringify(f.state.products);f.state.productsSearch='категория';
 f.c.sortProductsBy('price');assert.deepEqual(plain(f.c.sortedProductRows().map(p=>p.id)),['b','c','a']);f.c.sortProductsBy('price');assert.deepEqual(plain(f.c.sortedProductRows().map(p=>p.id)),['a','c','b']);
 f.c.sortProductsBy('stock');assert.deepEqual(plain(f.c.sortedProductRows().map(p=>p.id)),['b','a','c']);f.c.sortProductsBy('stock');assert.deepEqual(plain(f.c.sortedProductRows().map(p=>p.id)),['a','b','c']);assert.equal(JSON.stringify(f.state.products),before);assert.equal(f.state.productsSearch,'категория');assert.equal(f.writes.length,0);
});
test('product sorting supports category, type and WEB and renders all header buttons',()=>{
 const f=fixture();f.state.products=[{id:'a',name:'А',type:'composite',category:'Я',availableOnline:true,components:[]},{id:'b',name:'Б',type:'simple',category:'Б',availableOnline:false,stock:0}];
 for(const key of ['category','type','web']){f.c.sortProductsBy(key);assert.deepEqual(plain(f.c.sortedProductRows().map(p=>p.id)),['b','a']);}
 const h=f.c.renderProductsScreen();assert.equal((h.match(/class="products-sort-header/g)||[]).length,7);assert.match(h,/sortProductsBy\('stock'\)/);
});

function adminDeletionFixture(){const f=fixture();f.state.employees=[{id:'admin',name:'Админ',role:'admin'},{id:'other',name:'Другой',role:'employee'}];f.state.shifts[0].employeeId='admin';return f;}
test('administrator product delete omits password but preserves recipe protection',()=>{
 const f=adminDeletionFixture();let modal='';f.c.showModal=h=>modal=h;f.c.requestDelete('product','flour');assert.ok(!modal.includes('id="delete-password"'));f.c.confirmDelete('product','flour');assert.ok(f.c.getProduct('flour'));assert.match(f.messages.at(-1),/составном/);
 f.state.products.push({id:'unused',name:'Не используется',type:'simple'});f.c.confirmDelete('product','unused');assert.equal(f.c.getProduct('unused'),undefined);
 f.c.requestDelete('category','Категория');assert.ok(modal.includes('id="delete-password"'));
});
test('non-administrator cannot bypass product password and rights are rechecked',()=>{
 const f=adminDeletionFixture();f.state.products.push({id:'unused',name:'Товар',type:'simple'});f.c.showModal=()=>{};f.c.requestDelete('product','unused');f.state.employees[0].role='employee';f.c.confirmDelete('product','unused');assert.ok(f.c.getProduct('unused'));assert.match(f.messages.at(-1),/пароль/);
});
test('employees including administrators cannot delete themselves, including direct confirmation',async()=>{
 const f=adminDeletionFixture(),before=JSON.stringify(f.state.employees);await f.c.confirmDeleteEmployee('admin');assert.equal(JSON.stringify(f.state.employees),before);assert.equal(f.writes.length,0);
 f.state.employees[0].role='employee';await f.c.confirmDeleteEmployee('other');assert.equal(f.state.employees.length,2);assert.equal(f.writes.length,0);
});
test('employee deletion uses POS confirmation and preserves shifts and receipts',async()=>{
 const f=adminDeletionFixture();let modal='';f.c.showModal=h=>modal=h;f.c.deleteEmployee('other');assert.match(modal,/confirmDeleteEmployee/);assert.equal(f.state.employees.length,2);
 f.fields['employee-delete-password']={value:html.match(/function confirmDelete[\s\S]*?pass!=='([^']+)'/)[1]};const shifts=JSON.stringify(f.state.shifts),orders=JSON.stringify(f.state.orders);await f.c.confirmDeleteEmployee('other');assert.equal(f.state.employees.length,1);assert.deepEqual(f.writes,['prilavok_employees']);assert.equal(JSON.stringify(f.state.shifts),shifts);assert.equal(JSON.stringify(f.state.orders),orders);
});
test('employee deletion failure leaves local state intact',async()=>{
 const f=adminDeletionFixture();f.fields['employee-delete-password']={value:html.match(/function confirmDelete[\s\S]*?pass!=='([^']+)'/)[1]};f.c.localStorage.setItem=()=>{throw Error('quota');};await f.c.confirmDeleteEmployee('other');assert.equal(f.state.employees.length,2);assert.match(f.messages.at(-1),/Не удалось/);
});

function navigationFixture(){const f=fixture();f.state.products=[{id:'a',name:'А',category:'Пицца',type:'simple',stock:10,price:5,sortOrder:0},{id:'b',name:'Б',category:'Пицца',type:'simple',stock:10,price:6,sortOrder:1},{id:'c',name:'В',category:'Пицца',type:'simple',stock:10,sortOrder:2}];f.fields['modal-root']={innerHTML:''};f.fields['pos-folder-grid']={dataset:{},addEventListener:()=>{}};f.c.closeModal=()=>{f.c._posFolderModal=null;f.fields['modal-root'].innerHTML='';};f.state.posPath='Пицца';f.state.posFolder='';f.state.editMode=true;f.fields['pos-folder-name']={value:'Популярное'};return f;}
test('navigation folders persist without changing products and restore after restart',async()=>{
 const f=navigationFixture(),before=JSON.stringify(f.state.products);await f.c.savePosFolder();const folder=f.state.posNavigation.categories[0].items.find(i=>i.type==='folder');assert.ok(folder);await f.c.movePosProduct('a',folder.id);assert.equal(JSON.stringify(f.state.products),before);assert.ok(f.writes.every(k=>k==='prilavok_posNavigation'));assert.equal(f.c.posVisibleCategoryItems().filter(i=>i.type==='product').length,2);
 f.c.openPosFolder(folder.id);assert.equal(f.c.posVisibleCategoryItems()[0].id,'a');f.c.closePosCategory();assert.equal(f.state.posPath,'Пицца');assert.equal(f.state.posFolder,'');
 const g=navigationFixture();g.data.set('prilavok_products',JSON.stringify(f.state.products));g.data.set('prilavok_posNavigation',f.data.get('prilavok_posNavigation'));await g.c.loadAll();assert.equal(g.c.posCategoryItems('Пицца').find(i=>i.id==='a').parentId,folder.id);
});
test('category tile ordering is scoped and folder deletion returns products to root',async()=>{
 const f=navigationFixture();await f.c.reorderPosCategoryTile('product','c',0);assert.deepEqual(plain(f.c.posVisibleCategoryItems().map(i=>i.id)),['c','a','b']);await f.c.savePosFolder();const folder=f.state.posNavigation.categories[0].items.find(i=>i.type==='folder');await f.c.movePosProduct('a',folder.id);await f.c.movePosProduct('b',folder.id);f.c.openPosFolder(folder.id);await f.c.reorderPosCategoryTile('product','b',0);assert.deepEqual(plain(f.c.posVisibleCategoryItems().map(i=>i.id)),['b','a']);await f.c.removePosFolder(folder.id);assert.equal(f.c.posCategoryItems('Пицца').length,3);assert.ok(f.c.posCategoryItems('Пицца').every(i=>i.parentId===''));assert.equal(f.state.products.length,3);
});
test('navigation handles old or invalid state, missing products and orphaned folders',()=>{
 const f=navigationFixture();assert.deepEqual(plain(f.c.normalizePosNavigation(null)),{version:1,categories:[]});f.state.posNavigation={version:1,categories:[{category:'Пицца',items:[{type:'product',id:'a',parentId:'gone'},{type:'product',id:'deleted',parentId:''},{type:'product',id:'a',parentId:''}]}]};const items=f.c.posCategoryItems('Пицца');assert.equal(items.length,3);assert.equal(items[0].parentId,'');assert.equal(new Set(items.map(i=>i.id)).size,3);
 f.state.products[0].category='Напитки';assert.ok(!f.c.posCategoryItems('Пицца').some(i=>i.id==='a'));assert.equal(f.c.posCategoryItems('Напитки')[0].parentId,'');
});
test('failed folder persistence leaves navigation and inventory unchanged',async()=>{
 const f=navigationFixture(),before=JSON.stringify(f.state);f.c.localStorage.setItem=()=>{throw Error('quota');};await f.c.savePosFolder();assert.equal(JSON.stringify(f.state),before);assert.match(f.messages.at(-1),/Не удалось сохранить/);
});
test('folder navigation is non-selling in edit mode and normal products still add to cart',async()=>{
 const f=navigationFixture();await f.c.savePosFolder();const id=f.state.posNavigation.categories[0].items.find(i=>i.type==='folder').id;await f.c.movePosProduct('a',id);f.state.editMode=false;
 const event=(type,id)=>({target:{closest:selector=>selector==='.layout-tile'?{dataset:{tileType:type,id}}:null}});
 f.c.handlePosGridClick(event('folder',id));assert.equal(f.state.posFolder,'');assert.equal(f.c._posFolderModal.id,id);assert.equal(f.state.cart.length,0);f.c.handlePosGridClick(event('product','a'));assert.equal(f.state.cart[0].productId,'a');
 f.state.editMode=true;let moved=false;f.c.openPosTileMove=()=>{moved=true;};f.c.handlePosGridClick(event('product','a'));assert.ok(moved);assert.equal(f.state.cart[0].qty,1);
});
test('category UI exposes layout controls and folder contents without root tile removal',async()=>{
 const f=navigationFixture();await f.c.savePosFolder();const html=f.c.renderPosScreen(f.c.currentShift());assert.match(html,/Создать папку/);assert.match(html,/data-tile-type="folder"/);assert.match(html,/category-edit-grid/);assert.ok(!html.includes('removeLayoutTile(undefined)'));
});

test('category drag drop delegates correct target and cancelled drag does not save',()=>{
 const f=navigationFixture();let call=null;f.c.reorderPosCategoryTile=(...args)=>{call=args;};f.c.gridMetrics=()=>({cols:4});const tile={dataset:{tileType:'product',id:'a'},releasePointerCapture:()=>{}},grid={querySelectorAll:()=>[]};
 const make=()=>({category:'Пицца',folder:'',tile,index:0,pointerId:1,dragging:true,target:{row:1,col:2},grid});f.c.dragTest=make();vm.runInContext('layoutDragState=dragTest',f.c);f.c.onLayoutPointerUp({pointerId:1,type:'pointerup',preventDefault:()=>{}});assert.deepEqual(call,['product','a',6]);
 call=null;f.c.dragTest=make();vm.runInContext('layoutDragState=dragTest',f.c);f.c.onLayoutPointerUp({pointerId:1,type:'pointercancel',preventDefault:()=>{}});assert.equal(call,null);assert.equal(f.writes.length,0);
});
test('backup export includes versioned navigation and legacy backups normalize to empty folders',async()=>{
 const f=navigationFixture();await f.c.savePosFolder();let saved;f.c.Blob=class{constructor(parts){saved=JSON.parse(parts[0]);}};f.c.URL={createObjectURL:()=>'',revokeObjectURL:()=>{}};f.c.document.createElement=()=>({click:()=>{}});f.c.exportBackup();assert.equal(saved.version,10);assert.equal(saved.posNavigation.version,1);assert.ok(saved.posNavigation.categories[0].items.some(i=>i.type==='folder'));assert.equal(f.c.normalizePosNavigation(undefined).categories.length,0);
});

test('folder modal leaves category visible and renders six products without folder icon or counter',async()=>{
 const f=navigationFixture();for(let n=3;n<6;n++)f.state.products.push({id:'p'+n,name:'Товар '+n,type:'simple',category:'Пицца',stock:3,price:1});await f.c.savePosFolder();const id=f.state.posNavigation.categories[0].items.find(i=>i.type==='folder').id;for(const p of f.state.products)await f.c.movePosProduct(p.id,id);
 f.state.editMode=false;const before=f.c.renderPosScreen(f.c.currentShift());const folderTile=before.slice(before.indexOf('data-tile-type="folder"'),before.indexOf('data-tile-type="folder"')+700);assert.ok(!folderTile.includes('<svg'));assert.ok(!folderTile.includes('Папка ·'));
 f.c.openPosFolder(id);assert.equal(f.state.posPath,'Пицца');assert.equal(f.state.posFolder,'');const html=f.fields['modal-root'].innerHTML;assert.match(html,/pos-folder-modal/);assert.equal((html.match(/data-tile-type="product"/g)||[]).length,6);assert.match(html,/Закрыть/);f.c.closeModal();assert.equal(f.c._posFolderModal,null);assert.equal(f.state.posPath,'Пицца');
});

test('employee deletion requires password for both administrator and ordinary operator',async()=>{
 for(const role of ['admin','employee']){const f=adminDeletionFixture();f.state.employees[0].role=role;await f.c.confirmDeleteEmployee('other');assert.equal(f.state.employees.length,2);f.fields['employee-delete-password']={value:'wrong'};await f.c.confirmDeleteEmployee('other');assert.equal(f.writes.length,0);f.fields['employee-delete-password'].value=html.match(/function confirmDelete[\s\S]*?pass!=='([^']+)'/)[1];await f.c.confirmDeleteEmployee('other');assert.equal(f.state.employees.length,1);}
});
test('administrator target is protected even with valid password; settings show aligned controls',async()=>{
 const f=adminDeletionFixture();f.state.employees[1].role='admin';f.fields['employee-delete-password']={value:html.match(/function confirmDelete[\s\S]*?pass!=='([^']+)'/)[1]};await f.c.confirmDeleteEmployee('other');assert.equal(f.state.employees.length,2);assert.equal(f.writes.length,0);const view=f.c.renderSettingsScreen();assert.match(view,/employee-settings-row/);assert.equal((view.match(/class="settings-quick-btn"/g)||[]).length,3);assert.equal((view.match(/Информация об администраторе/g)||[]).length,2);
});

test('employee list abbreviation preserves full names and handles missing patronymic',()=>{
 const f=fixture();assert.equal(f.c.employeeDisplayName('  Иванов   Иван Иванович  '),'Иванов И. И.');assert.equal(f.c.employeeDisplayName('Петров Пётр'),'Петров П.');assert.equal(f.c.employeeDisplayName('Анна'),'Анна');assert.equal(f.c.employeeDisplayName(''),'');
 f.state.employees=[{id:'one',name:'Иванов Иван Иванович',role:'employee'}];const html=f.c.renderSettingsScreen();assert.match(html,/Иванов И\. И\./);assert.equal(f.state.employees[0].name,'Иванов Иван Иванович');
});
test('folder products render same escaped sticker as main workspace',async()=>{
 const f=navigationFixture();f.state.products[0].tileSymbol='<&';await f.c.savePosFolder();const id=f.state.posNavigation.categories[0].items.find(i=>i.type==='folder').id;await f.c.movePosProduct('a',id);f.state.editMode=false;f.c.openPosFolder(id);
 const sticker=f.c.renderProductTileSymbol(f.state.products[0]);assert.equal(sticker,'<div class="tile-symbol">&lt;&amp;</div>');assert.ok(f.fields['modal-root'].innerHTML.includes(sticker));assert.equal(f.c.renderProductTileSymbol({}), '');
});

test('availability uses persisted products and nested recipes, sends no catalogue or prices',async()=>{
 const f=fixture();f.state.loaded=true;
 await f.c.saveKey('products',f.state.products);await f.c.saveKey('network',{backendUrl:'https://backend.test',deviceKey:'test'});
 f.c.getProduct('flour').stock=0; // unsaved edit must not be sent
 let body;f.c.fetch=async(url,options)=>{assert.match(url,/availability\/snapshot$/);body=JSON.parse(options.body);assert.ok(f.data.has('prilavok_webAvailabilityRevision'));return {ok:true};};
 assert.equal(await f.c.publishAvailability(),true);assert.equal(body.items.find(i=>i.externalId==='pizza').quantity,50);assert.deepEqual(Object.keys(body.items[0]).sort(),['externalId','quantity']);assert.equal(f.c.getProduct('flour').stock,0);
});
test('availability never sends on storage failure, while hidden or before load',async()=>{
 for(const mode of ['hidden','unloaded','storage']){
  const f=fixture();f.state.loaded=mode!=='unloaded';f.c.document.hidden=mode==='hidden';await f.c.saveKey('products',f.state.products);await f.c.saveKey('network',{backendUrl:'https://test',deviceKey:'test'});
  if(mode==='storage')f.c.localStorage.setItem=()=>{throw Error('full')};
  let calls=0;f.c.fetch=async()=>{calls++;return {ok:true}};assert.equal(await f.c.publishAvailability(),false);assert.equal(calls,0);
 }
});
test('availability timeout or network failure leaves POS state and products untouched',async()=>{
 const f=fixture();f.state.loaded=true;await f.c.saveKey('products',f.state.products);await f.c.saveKey('network',{backendUrl:'https://test',deviceKey:'test'});
 const before=JSON.stringify(f.state);f.c.fetch=async()=>{throw Error('offline')};assert.equal(await f.c.publishAvailability(),false);assert.equal(JSON.stringify(f.state),before);assert.equal(JSON.parse(f.data.get('prilavok_products'))[0].stock,10);
});
test('availability revision increases across restart and backwards clock; unchanged stock has heartbeat',async()=>{
 const f=fixture();f.state.loaded=true;await f.c.saveKey('products',f.state.products);await f.c.saveKey('network',{backendUrl:'https://test',deviceKey:'test'});await f.c.saveKey('webAvailabilityRevision',Date.now()+100000);
 const revisions=[];f.c.fetch=async(_,o)=>{revisions.push(JSON.parse(o.body).revision);return {ok:true}};await f.c.publishAvailability();await f.c.publishAvailability();assert.equal(revisions.length,2);assert.equal(revisions[1],revisions[0]+1);
});
test('availability distinguishes untracked, zero and broken recipes',()=>{
 const f=fixture();f.state.products.push({id:'untracked',type:'simple',noStockTracking:true},{id:'broken',type:'composite',components:[{productId:'missing',qty:1}]});f.c.getProduct('flour').stock=-1;
 const items=f.c.buildAvailabilityItems(f.state.products);assert.equal(items.find(i=>i.externalId==='untracked').quantity,null);assert.equal(items.find(i=>i.externalId==='flour').quantity,0);assert.equal(items.find(i=>i.externalId==='broken').quantity,0);
});
test('availability schedule waits ten minutes on launch/resume; no network event trigger',async()=>{
 const f=fixture();const jobs=[],listeners={};f.c.setTimeout=(cb,ms)=>{jobs.push({cb,ms});return jobs.length};f.c.clearTimeout=()=>{};f.c.document.addEventListener=(event,cb)=>{listeners[event]=cb};let sent=0;f.c.publishAvailability=async()=>{sent++};
 f.c.startAvailabilitySchedule();assert.equal(jobs[0].ms,600000);assert.equal(sent,0);assert.deepEqual(Object.keys(listeners),['visibilitychange']);
 f.c.document.hidden=true;listeners.visibilitychange();assert.equal(jobs.length,1);f.c.document.hidden=false;listeners.visibilitychange();assert.equal(jobs.length,2);assert.equal(sent,0);await jobs[1].cb();assert.equal(sent,1);assert.equal(jobs[2].ms,600000);
});
function webAcceptFixture(){const f=fixture();f.state.network={backendUrl:'https://test',deviceKey:'test'};f.state.webEvents=[{id:'web-1',external_id:'WEB-1',total:10,order_items:[{external_product_id:'pizza',product_name:'Пицца',quantity:1,price:10}]}];return f;}
test('WEB acceptance checks aggregate ingredient availability before any network request',async()=>{
 const f=webAcceptFixture();f.c.getProduct('flour').stock=.3;f.state.webEvents[0].order_items.push({external_product_id:'flour',product_name:'Мука',quantity:.2,price:2});await f.c.acceptWebOrder('web-1');assert.equal(f.state.parked.length,0);assert.match(f.messages.join(' '),/Недостаточно остатка/);
});
test('WEB acceptance rejects missing IDs instead of silently dropping lines or matching a renamed product',async()=>{
 const f=webAcceptFixture();f.state.webEvents[0].order_items[0].external_product_id='deleted';await f.c.acceptWebOrder('web-1');assert.equal(f.state.parked.length,0);assert.match(f.messages.join(' '),/не найден/);
});
test('WEB acceptance persists locally before network and retries without duplicating even after consumption',async()=>{
 const f=webAcceptFixture();let attempts=0;f.c.fetch=async()=>{attempts++;assert.equal(JSON.parse(f.data.get('prilavok_parked')).length,1);assert.equal(JSON.parse(f.data.get('prilavok_webOrderAcceptances'))['web-1'].stage,'local');if(attempts===1)throw Error('offline');return {ok:true,json:async()=>({ok:true})}};
 await f.c.acceptWebOrder('web-1');assert.equal(f.state.parked.length,1);f.state.parked=[];await f.c.saveKey('parked',[]);f.c.fetch=async()=>({ok:true,json:async()=>({ok:true})});await f.c.acceptWebOrder('web-1');assert.equal(f.state.parked.length,0);assert.equal(f.state.webEvents.length,0);assert.equal(JSON.parse(f.data.get('prilavok_webOrderAcceptances'))['web-1'].stage,'confirmed');
});
test('WEB local write failure never sends confirmation',async()=>{
 const f=webAcceptFixture();f.c.localStorage.setItem=()=>{throw Error('disk full')};let calls=0;f.c.fetch=async()=>{calls++};await f.c.acceptWebOrder('web-1');assert.equal(calls,0);assert.equal(f.state.parked.length,0);
});
test('prepared WEB acceptance recovers persisted parked row on restart without another copy',async()=>{
 const f=webAcceptFixture();const parked={id:'p',webOrderId:'web-1',items:[]};f.state.parked=[parked];await f.c.saveKey('webOrderAcceptances',{'web-1':{stage:'prepared',parked}});await f.c.recoverWebAcceptanceJournal();assert.equal(JSON.parse(f.data.get('prilavok_webOrderAcceptances'))['web-1'].stage,'local');assert.equal(f.state.parked.length,1);
});
