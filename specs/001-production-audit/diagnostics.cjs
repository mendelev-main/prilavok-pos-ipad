// Diagnostic reproductions of known defects, NOT passing acceptance tests.
// Synthetic state only; no network or real device storage. Exit 2 means defects reproduced.
const fs=require('node:fs'),path=require('node:path'),Module=require('node:module');
const root=path.resolve(__dirname,'../..');
const fixtureFile=path.join(root,'tests/product-stock.test.cjs');
const source=fs.readFileSync(fixtureFile,'utf8');
const prefix=source.slice(0,source.indexOf("test('all inline JavaScript"));
if(!prefix.includes('function fixture()'))throw Error('Fixture structure changed; update diagnostic harness');
const mod=new Module(fixtureFile,module);mod.filename=fixtureFile;mod.paths=module.paths;
mod._compile(prefix+'\nmodule.exports=fixture;',fixtureFile);
const fixture=mod.exports;
(async()=>{
 const results=[];
 {
  const f=fixture();let receiptShown=false;
  f.c.showPaymentReceipt=()=>{receiptShown=true;};
  const realSet=f.c.localStorage.setItem;
  f.c.localStorage.setItem=(key,value)=>{if(key==='prilavok_orders')throw Error('Injected quota failure');realSet(key,value);};
  f.sale();await Promise.resolve();await Promise.resolve();
  results.push({id:'F01',defect:receiptShown&&!f.data.has('prilavok_orders')&&f.state.cart.length===0,observed:{receiptShown,receiptStored:f.data.has('prilavok_orders'),cartItems:f.state.cart.length,stockStored:f.data.has('prilavok_products')}});
 }
 {
  const f=fixture();f.cart();f.state.customer={id:'synthetic-customer'};
  f.c.loyaltyApi=()=>new Promise(()=>{});f.c.finalizePayment([{method:'cash',amount:10}]);
  const order=JSON.parse(f.data.get('prilavok_orders'))[0];let retried=0;
  f.state.orders=[order];f.c.publishPaidOrderLoyalty=()=>{retried++;};f.c.retryPendingLoyalty();
  results.push({id:'F02',defect:!order.loyaltySync&&retried===0,observed:{persistedSync:order.loyaltySync||null,retried}});
 }
 {
  const f=fixture();f.cart();f.state.loyaltyPrograms=[{id:'gift',loyalty_reward_products:[{product_id:'pizza'}]}];f.state.loyaltyRedemptions={gift:1};
  const rendered=f.c.renderCartPanel(f.state.shifts[0]);const displayed=rendered.match(/<span class="label">Итого<\/span><span class="value">([^<]+)/)?.[1];
  results.push({id:'F03',defect:f.c.cartTotal()===0&&displayed.startsWith('10,'),observed:{payable:f.c.cartTotal(),displayed}});
 }
 {
  const f=fixture();f.cart();f.state.cart.push({productId:'water',name:'Вода',price:5,qty:1});
  f.state.loyaltyPrograms=['a','b'].map(id=>({id,loyalty_reward_products:[{product_id:'pizza'}]}));f.state.loyaltyRedemptions={a:1,b:1};
  results.push({id:'F04',defect:f.c.loyaltyRewardDiscount()===20,observed:{subtotal:f.c.cartSubtotal(),discount:f.c.loyaltyRewardDiscount(),payable:f.c.cartTotal()}});
 }
 for(const failedKey of ['products','orders','shifts']){
  const f=fixture();f.sale();await Promise.resolve();await Promise.resolve();
  const order=f.state.orders[0];
  const realSet=f.c.localStorage.setItem;
  f.c.localStorage.setItem=(k,v)=>{if(k==='prilavok_'+failedKey)throw Error('Injected quota');realSet(k,v);};
  f.c.processFullReturn(order.id);await Promise.resolve();await Promise.resolve();
  const persistedOrder=JSON.parse(f.data.get('prilavok_orders'))[0];
  const persistedProducts=JSON.parse(f.data.get('prilavok_products'));
  results.push({id:'F01-return-'+failedKey,defect:!!order.returnedAt,observed:{localReturned:!!order.returnedAt,persistedReturned:!!persistedOrder.returnedAt,persistedFlour:persistedProducts.find(x=>x.id==='flour').stock,persistedCashMovements:JSON.parse(f.data.get('prilavok_shifts'))[0].cashMovements?.length||0}});
 }
 for(const failedKey of ['products','purchaseOrders','receivings']){
  const f=fixture();f.state.suppliers=[];f.state.receivings=[];
  f.state.purchaseOrders=[{id:'purchase',items:[{productId:'flour',qty:3}],status:'pending'}];
  for(const key of ['products','purchaseOrders','receivings'])f.data.set('prilavok_'+key,JSON.stringify(f.state[key]));
  const realSet=f.c.localStorage.setItem;
  f.c.localStorage.setItem=(k,v)=>{if(k==='prilavok_'+failedKey)throw Error('Injected quota');realSet(k,v);};
  f.c._receivingPending={orderId:'purchase',draft:{invoiceNumber:'SYNTHETIC',invoiceDate:'2026-10-01',supplierId:'',lines:[{productId:'flour',qtyInput:'3',unit:'',totalInput:'60'}]}};
  f.c.applyReceivingDocument();await Promise.resolve();await Promise.resolve();
  results.push({id:'F01-receiving-'+failedKey,defect:f.messages.some(x=>x.includes('Приёмка подтверждена')),observed:{success:f.messages.some(x=>x.includes('Приёмка подтверждена')),storedDocuments:JSON.parse(f.data.get('prilavok_receivings')).length,storedStatus:JSON.parse(f.data.get('prilavok_purchaseOrders'))[0].status,storedStock:JSON.parse(f.data.get('prilavok_products'))[0].stock}});
 }
 {
  const f=fixture();f.sale();await Promise.resolve();let input;
  f.c.document.createElement=()=>input={files:[{}],click(){this.onchange();}};
  f.c.FileReader=class{readAsText(){this.result=JSON.stringify({products:[]});this.onload();}};
  f.c.importBackup();await Promise.resolve();await Promise.resolve();
  results.push({id:'F08',defect:f.state.orders.length===0&&f.messages.includes('Данные восстановлены'),observed:{ordersAfter:f.state.orders.length,success:f.messages.includes('Данные восстановлены')}});
 }
 console.log(JSON.stringify(results,null,2));process.exitCode=results.some(x=>x.defect)?2:0;
})().catch(e=>{console.error(e);process.exitCode=1;});
