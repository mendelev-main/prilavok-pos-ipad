// Prilavok POS v130.17
// Offline-first storage adapter.
//
// Contract:
// - local POS data is authoritative;
// - reads/writes stay local and must not depend on network access;
// - storage keys and serialized payloads stay compatible with the existing pos.html implementation;
// - this adapter never starts synchronization;
// - synchronization is a separate, manual-only concern.

(function (global) {
  'use strict';

  const root = global.PrilavokCore = global.PrilavokCore || {};
  const LS_PREFIX = 'prilavok_';

  // Match pos.html: select the provider once, including its legacy null behavior.
  const usesCloudStorage = typeof global.storage !== 'undefined';

  function hasCloudStorage() {
    return usesCloudStorage;
  }

  async function get(key, fallback, onError) {
    try {
      if (hasCloudStorage()) {
        const result = await global.storage.get(key, false);
        return result ? JSON.parse(result.value) : fallback;
      }

      const raw = global.localStorage.getItem(LS_PREFIX + key);
      return raw !== null ? JSON.parse(raw) : fallback;
    } catch (error) {
      // Let the POS facade preserve its existing storage warning.
      if (onError) onError(error);
      else console.error('[PrilavokStorage] read failed', key, error);
      return fallback;
    }
  }

  const JOURNAL_KEY='operationJournalV1';
  let blocked=false,busy=false;
  const pendingWrites=new Set();
  function rawWrite(key,value){
    return hasCloudStorage()?global.storage.set(key,value,false):global.localStorage.setItem(LS_PREFIX+key,value);
  }
  function rawRead(key){
    return hasCloudStorage()?Promise.resolve(global.storage.get(key,false)).then(r=>r?r.value:null):global.localStorage.getItem(LS_PREFIX+key);
  }
  function set(key,value){
    if(blocked||busy)return Promise.reject(new Error('Сначала восстановите незавершённую операцию'));
    try{
      const result=rawWrite(key,JSON.stringify(value));
      if(result&&typeof result.then==='function'){
        const task=Promise.resolve(result);pendingWrites.add(task);task.then(()=>pendingWrites.delete(task),()=>{pendingWrites.delete(task);blocked=true;});return task;
      }
      return Promise.resolve();
    }catch(error){blocked=true;return Promise.reject(error);}
  }
  function decodeJournal(raw){
    if(raw===null)return null;
    const entry=JSON.parse(raw);if(entry===null)return null;
    if(entry.version!==1||typeof entry.id!=='string'||!Array.isArray(entry.entries)||!entry.entries.length)throw new Error('Повреждён журнал операции');
    const seen=new Set();
    for(const [key,value] of entry.entries){
      if(typeof key!=='string'||!/^[a-zA-Z][a-zA-Z0-9]*$/.test(key)||key===JOURNAL_KEY||seen.has(key)||typeof value!=='string')throw new Error('Повреждён журнал операции');
      JSON.parse(value);seen.add(key);
    }
    return entry;
  }
  function transaction(kind,changes){
    if(blocked||busy)throw new Error('Сначала восстановите незавершённую операцию');
    const entries=Object.entries(changes).map(([key,value])=>[key,JSON.stringify(value)]);
    const raw=JSON.stringify({version:1,id:global.crypto?.randomUUID?.()||String(Date.now())+'-'+Math.random(),kind,entries});
    decodeJournal(raw);busy=true;
    if(hasCloudStorage())return (async()=>{
      try{
        await Promise.all([...pendingWrites]);if(blocked)throw new Error('Предыдущая запись не завершена');
        if(decodeJournal(await rawRead(JOURNAL_KEY)))throw new Error('Есть незавершённая операция');
        await rawWrite(JOURNAL_KEY,raw);
        for(const [key,value] of entries)await rawWrite(key,value);
        await rawWrite(JOURNAL_KEY,'null');
      }catch(error){blocked=true;throw error;}finally{busy=false;}
    })();
    try{
      if(decodeJournal(rawRead(JOURNAL_KEY)))throw new Error('Есть незавершённая операция');
      rawWrite(JOURNAL_KEY,raw);
      for(const [key,value] of entries)rawWrite(key,value);
      rawWrite(JOURNAL_KEY,'null');
    }catch(error){blocked=true;throw error;}finally{busy=false;}
  }
  async function recoverTransaction(){
    if(busy)throw new Error('Операция ещё выполняется');
    busy=true;
    try{
      await Promise.all([...pendingWrites]);
      const entry=decodeJournal(await rawRead(JOURNAL_KEY));
      if(entry){
        for(const [key,value] of entry.entries)await rawWrite(key,value);
        await rawWrite(JOURNAL_KEY,'null');
      }
      blocked=false;return entry?{id:entry.id,kind:entry.kind}:null;
    }catch(error){blocked=true;throw error;}finally{busy=false;}
  }

  function remove(key) {
    if (hasCloudStorage()) {
      throw new Error('Cloud storage removal is not supported by the v130.16 adapter');
    }

    if(blocked||busy)throw new Error('Сначала восстановите незавершённую операцию');
    global.localStorage.removeItem(LS_PREFIX + key);
  }

  function describe() {
    return Object.freeze({
      mode: hasCloudStorage() ? 'window.storage' : 'localStorage',
      prefix: LS_PREFIX,
      sourceOfTruth: 'local-pos',
      networkRequired: false,
      startsSynchronization: false
    });
  }

  root.Storage = Object.freeze({
    get,
    set,
    transaction,
    recoverTransaction,
    isBlocked:()=>blocked||busy,
    remove,
    describe
  });
})(window);
