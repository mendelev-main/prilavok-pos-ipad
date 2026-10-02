/* ---- Event-driven web availability ---- */
let availabilityController=null,availabilityPending=false,availabilityRunPromise=null;

function buildAvailabilityItems(products){
  const byId=new Map(products.map(p=>[p.id,p]));
  return products.map(p=>{
    const qty=availableStock(p,id=>byId.get(id));
    return {externalId:String(p.id),quantity:qty===Infinity?null:(Number.isFinite(qty)?Math.max(0,qty):0)};
  }).sort((a,b)=>a.externalId.localeCompare(b.externalId));
}

async function sendAvailabilitySnapshot(){
  if(document.hidden||window._availabilityAppActive===false||!state.loaded||storageBroken)return false;
  let timeout;
  try{
    let failed=false;const onError=()=>{failed=true;};const storage=window.PrilavokCore.Storage;
    // Always derive from completed local writes, never from an unsaved editor or live state.
    const [products,network,previous]=await Promise.all([storage.get('products',null,onError),storage.get('network',null,onError),storage.get('webAvailabilityRevision',0,onError)]);
    if(failed||!Array.isArray(products)||!network?.backendUrl||!network.deviceKey)return false;
    if(!Number.isSafeInteger(previous)||previous<0)return false;
    const items=buildAvailabilityItems(products),revision=Math.max(Date.now(),previous+1);
    if(!Number.isSafeInteger(revision))return false;
    await storage.set('webAvailabilityRevision',revision);
    if(document.hidden||window._availabilityAppActive===false)return false;
    availabilityController=new AbortController();timeout=setTimeout(()=>availabilityController?.abort(),30000);
    const response=await fetch(network.backendUrl.replace(/\/+$/,'')+'/api/availability/snapshot',{method:'POST',headers:{'Content-Type':'application/json','X-Device-Key':network.deviceKey},body:JSON.stringify({version:1,revision,sampledAt:new Date().toISOString(),items}),cache:'no-store',signal:availabilityController.signal});
    return response.ok;
  }catch(_error){return false}
  finally{clearTimeout(timeout);availabilityController=null}
}

function publishAvailability(){
  availabilityPending=true;
  if(availabilityRunPromise)return availabilityRunPromise;
  availabilityRunPromise=(async()=>{
    let sent=false;
    while(availabilityPending){
      availabilityPending=false;
      const ok=await sendAvailabilitySnapshot();
      sent=ok||sent;
      // A failed attempt is retried only when another stock mutation arrived while it ran.
      if(!ok&&!availabilityPending)break;
    }
    return sent;
  })().finally(()=>{availabilityRunPromise=null});
  return availabilityRunPromise;
}

function onAvailabilityAppState(active){
  window._availabilityAppActive=active;
  if(!active)availabilityController?.abort();
}
