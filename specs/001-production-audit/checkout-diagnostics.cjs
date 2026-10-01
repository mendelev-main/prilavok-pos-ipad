// Usage: node checkout-diagnostics.cjs /absolute/path/to/backend
// No DB/network: calls real checkout service with synthetic in-memory query doubles.
const path=require('node:path'),{pathToFileURL}=require('node:url');
(async()=>{
 if(!process.argv[2])throw Error('Pass backend checkout directory');
 const {createCheckoutService}=await import(pathToFileURL(path.join(process.argv[2],'checkout-service.js')));
 const results=[];
 for(const fail of ['customer','order','items','session']){
  let consumed=false,orderCreated=false,itemsCreated=false,sessionCompleted=false;
  const phone='+375290000000';
  const session={id:'session',status:'PENDING',phone,order_payload:{customerName:'Synthetic',orderType:'Самовывоз',items:[{product_name:'Synthetic',quantity:1,price:1}],total:1,fee:0},expires_at:new Date(Date.now()+60000).toISOString()};
  const result=(error,data)=>({error:error?new Error('Injected '+fail):null,data});
  const q=res=>({select(){return this},eq(){return this},single:async()=>res,maybeSingle:async()=>res});
  const supabase={from(table){
   if(table==='checkout_sessions')return {select:()=>q(result(false,session)),update:()=>({eq:async()=>{sessionCompleted=fail!=='session';return result(fail==='session');}})};
   if(table==='customers')return {select:()=>q(result(fail==='customer',{id:'customer',name:'Synthetic',normalized_phone:phone})),update:()=>q(result(false,{id:'customer'}))};
   if(table==='orders')return {insert:()=>{orderCreated=fail!=='order';return q(result(fail==='order',{id:'order'}));}};
   if(table==='order_items')return {insert:async()=>{itemsCreated=fail!=='items';return result(fail==='items');}};
   throw Error('Unexpected table '+table);
  }};
  const phoneVerification={get:async()=>({status:consumed?'CONSUMED':'VERIFIED',phone}),consume:async()=>{consumed=true;return true;}};
  const service=createCheckoutService({supabase,normalizePhone:x=>x,validateOrderContact:()=>'',phoneVerification});
  let error;try{await service.finalizeByVerificationToken('synthetic');}catch(e){error=e.message;}
  const retry=await service.finalizeByVerificationToken('synthetic');
  results.push({fail,consumed,orderCreated,itemsCreated,sessionCompleted,error,retry,defect:consumed&&!sessionCompleted&&retry?.ok===false});
 }
 console.log(JSON.stringify(results,null,2));process.exitCode=results.some(x=>x.defect)?2:0;
})().catch(e=>{console.error(e);process.exitCode=1;});
