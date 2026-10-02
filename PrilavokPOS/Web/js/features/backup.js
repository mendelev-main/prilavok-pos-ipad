function exportBackup(){
  const data={version:12,exportedAt:Date.now(),printerSettings:window.__printerSettingsSnapshot?.()||{printers:storageSnapshot(state.printers||[]),posNotifications:storageSnapshot(state.posNotifications||{soundEnabled:true,sound:'default'})},posNavigation:state.posNavigation,company:state.company,deliveryRates:state.deliveryRates,products:state.products,employees:state.employees,shifts:state.shifts,orders:state.orders,parked:state.parked,receivings:state.receivings,suppliers:state.suppliers,purchaseOrders:state.purchaseOrders,discounts:state.discounts,hallTables:state.hallTables,bookings:state.bookings,inventoryConfig:state.inventoryConfig,inventoryHistory:state.inventoryHistory,inventoryDraft:state.inventoryDraft,currentOrderSession:currentOrderSessionSnapshot(),layout:categoryLayoutSnapshot()};
  const blob=new Blob([JSON.stringify(data,null,2)],{type:'application/json'});
  const a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download='prilavok-backup-'+new Date().toISOString().slice(0,10)+'.json';a.click();
  setTimeout(()=>URL.revokeObjectURL(a.href),1000);
  flash('Резервная копия сохранена');
}
function backupArray(data,key,required=false){
  if(Array.isArray(data?.[key]))return storageSnapshot(data[key]);
  const present=Object.prototype.hasOwnProperty.call(data||{},key);
  if(required&&!present)throw new Error('В резервной копии отсутствует раздел «'+key+'»');
  if(present)throw new Error('Некорректный раздел «'+key+'»');
  return [];
}
function validateBackupData(data){
  if(!data||typeof data!=='object'||Array.isArray(data))throw new Error('Некорректный файл резервной копии');
  const version=data.version==null?1:Number(data.version);if(!Number.isInteger(version)||version<1||version>12)throw new Error('Версия резервной копии не поддерживается');
  const products=backupArray(data,'products',true),employees=backupArray(data,'employees',true),shifts=backupArray(data,'shifts',true),orders=backupArray(data,'orders',true);
  for(const [name,rows] of [['products',products],['employees',employees],['shifts',shifts],['orders',orders]]){
    const ids=new Set();for(const row of rows){if(!row||typeof row!=='object'||!String(row.id||''))throw new Error('Некорректный раздел «'+name+'»');if(ids.has(String(row.id)))throw new Error('Повторяющийся ID в разделе «'+name+'»');ids.add(String(row.id))}
  }
  const layout=data.layout&&typeof data.layout==='object'?storageSnapshot(data.layout):{};
  const categoryOrder=Array.isArray(layout.categoryOrder)?layout.categoryOrder:[];
  const categoryOnline=layout.categoryOnline&&typeof layout.categoryOnline==='object'?layout.categoryOnline:{};
  categoryOrder.forEach(category=>{if(typeof categoryOnline[category]!=='boolean')categoryOnline[category]=true});
  const categoryOnlineOrder=layout.categoryOnlineOrder&&typeof layout.categoryOnlineOrder==='object'?layout.categoryOnlineOrder:Object.assign({},categoryOnline);
  const categoryOnlineMenu=layout.categoryOnlineMenu&&typeof layout.categoryOnlineMenu==='object'?layout.categoryOnlineMenu:Object.assign({},categoryOnline);
  categoryOrder.forEach(category=>{if(typeof categoryOnlineOrder[category]!=='boolean')categoryOnlineOrder[category]=categoryOnline[category]!==false;if(typeof categoryOnlineMenu[category]!=='boolean')categoryOnlineMenu[category]=categoryOnline[category]!==false});
  let printerSettings=null;if(version>=12){const value=data.printerSettings;if(!value||!Array.isArray(value.printers)||!value.posNotifications||typeof value.posNotifications!=='object'||Array.isArray(value.posNotifications))throw new Error('Некорректный раздел «printerSettings»');printerSettings=storageSnapshot(value)}
  return {products,employees,shifts,orders,parked:backupArray(data,'parked'),receivings:backupArray(data,'receivings'),suppliers:backupArray(data,'suppliers'),purchaseOrders:backupArray(data,'purchaseOrders'),discounts:backupArray(data,'discounts'),hallTables:backupArray(data,'hallTables'),bookings:backupArray(data,'bookings'),inventoryHistory:backupArray(data,'inventoryHistory'),inventoryConfig:data.inventoryConfig&&typeof data.inventoryConfig==='object'?storageSnapshot(data.inventoryConfig):{enabled:false,frequency:'monthly',productIds:[],lastCompletedAt:null},inventoryDraft:data.inventoryDraft&&typeof data.inventoryDraft==='object'?storageSnapshot(data.inventoryDraft):null,currentOrderSession:data.currentOrderSession&&typeof data.currentOrderSession==='object'?storageSnapshot(data.currentOrderSession):emptyCurrentOrderSession(),company:Object.assign({establishmentName:'',legalName:'',address:'',deliveryAddress:''},data.company||{}),deliveryRates:backupArray(data,'deliveryRates'),posNavigation:normalizePosNavigation(data.posNavigation),printerSettings,layout:{categoryOrder,categoryColors:layout.categoryColors&&typeof layout.categoryColors==='object'?layout.categoryColors:{},categorySymbols:layout.categorySymbols&&typeof layout.categorySymbols==='object'?layout.categorySymbols:{},categoryOnline:categoryOnlineOrder,categoryOnlineOrder,categoryOnlineMenu,tiles:Array.isArray(layout.tiles)?layout.tiles:products.map(product=>({type:'product',id:product.id}))}};
}
async function applyBackupData(data){
  const next=validateBackupData(data);
  if(next.printerSettings&&typeof window.__restorePrinterSettings!=='function')throw new Error('Модуль настроек принтеров недоступен');
  const {printerSettings,...storageData}=next;
  await commitCriticalStorage('backup-import',storageData);
  if(next.printerSettings)window.__restorePrinterSettings(next.printerSettings);
  state.products=next.products;state.employees=next.employees;state.shifts=next.shifts;state.orders=next.orders;state.parked=next.parked;state.receivings=next.receivings;state.suppliers=next.suppliers;state.purchaseOrders=next.purchaseOrders;state.discounts=next.discounts;state.hallTables=next.hallTables;state.bookings=next.bookings;state.inventoryConfig=next.inventoryConfig;state.inventoryHistory=next.inventoryHistory;state.inventoryDraft=next.inventoryDraft;state.company=next.company;state.deliveryRates=next.deliveryRates;state.posNavigation=next.posNavigation;state.posFolder='';state.posPath=null;state.categoryOrder=next.layout.categoryOrder;state.categoryColors=next.layout.categoryColors;state.categorySymbols=next.layout.categorySymbols;state.categoryOnlineOrder=next.layout.categoryOnlineOrder;state.categoryOnlineMenu=next.layout.categoryOnlineMenu;state.categoryOnline=state.categoryOnlineOrder;state.layoutTiles=next.layout.tiles;
  const session=next.currentOrderSession;state.cart=Array.isArray(session.items)?session.items:[];state.orderLabel=session.orderLabel||'';state.orderType=session.orderType||'На месте';state.customer=Object.assign({name:'',phone:'',address:''},session.customer||{});state.deliveryFee=Number(session.deliveryFee||0);state.deliveryTariffSelected=session.deliveryTariffSelected===true;state.orderComment=session.orderComment||'';state.currentOrderSource=session.source||'';state.currentWebOrderId=session.webOrderId||'';state.currentWebOrderStatus=session.webOrderStatus||'';window.__currentOrderKitchenPrinted=!!session.kitchenPrinted;window.__currentOrderPrintedItems=Array.isArray(session.printedItems)?session.printedItems:[];state.loyaltyPrograms=Array.isArray(session.loyaltyPrograms)?storageSnapshot(session.loyaltyPrograms):[];state.loyaltyRedemptions=session.loyaltyRedemptions&&typeof session.loyaltyRedemptions==='object'?storageSnapshot(session.loyaltyRedemptions):{};state.loyaltyCustomerId=String(session.loyaltyCustomerId||'');state.loyaltyLoadingCustomerId='';state.loyaltyLoadError='';
  const restoredPaymentDraft=validateSplitPaymentDraft(session.paymentDraft,cartTotal());state._splitPayments=restoredPaymentDraft?.parts||[];state._splitCount=state._splitPayments.length;state._splitPaymentTotalCents=restoredPaymentDraft?.totalCents??null;
  render();flash('Данные восстановлены');if(hasPaidSplitPayment())setTimeout(()=>openPaymentModal(),0);
}
function importBackup(){
  const input=document.createElement('input');input.type='file';input.accept='.json,application/json';
  input.onchange=()=>{const file=input.files?.[0];if(!file)return;const reader=new FileReader();reader.onload=async()=>{try{await applyBackupData(JSON.parse(reader.result))}catch(e){flash('Резервная копия не восстановлена: '+(e?.message||'неизвестная ошибка'))}};reader.readAsText(file)};input.click();
}
