const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const vm=require('node:vm');

const root=path.resolve(__dirname,'..');
const script=fs.readFileSync(path.join(root,'PrilavokPOS/notification-native.js'),'utf8');
const swift=fs.readFileSync(path.join(root,'PrilavokPOS/PrilavokPOSApp.swift'),'utf8');
const entitlements=fs.readFileSync(path.join(root,'PrilavokPOS/PrilavokPOS.entitlements'),'utf8');
const project=fs.readFileSync(path.join(root,'PrilavokPOS.xcodeproj/project.pbxproj'),'utf8');

test('notification bridge registers persisted network identity with native APNs bridge',()=>{
  const posts=[];
  const c={state:{loaded:true},networkConfigFromState:()=>({backendUrl:'https://backend.test/',deviceKey:'device-key'}),document:{readyState:'complete',body:{},querySelectorAll:()=>[],getElementById:()=>null,addEventListener:()=>{}},MutationObserver:class{observe(){}},setTimeout:fn=>{fn();return 1},localStorage:{getItem:key=>key==='posNotificationSettings'?JSON.stringify({soundEnabled:true,sound:'ding'}):null},webkit:{messageHandlers:{pushNotifications:{postMessage:value=>posts.push(value)},printer:{postMessage:()=>{}}}}};
  c.window=c;vm.createContext(c);vm.runInContext(script,c);
  assert.deepEqual(JSON.parse(JSON.stringify(posts[0])),{action:'configure',backendUrl:'https://backend.test/',deviceKey:'device-key',soundEnabled:true});
  c.onNativePushRegistration({ok:true,configured:true,status:'active'});
  assert.match(script,/count>lastEventCount&&!remotePushRegistered/);
});

test('native app requests APNs permission, registers token and handles foreground order without duplicate system sound',()=>{
  assert.match(swift,/requestAuthorization\(options: \[\.alert, \.sound\]\)/);
  assert.match(swift,/getNotificationSettings/);
  assert.match(swift,/case \.denied:/);
  assert.match(swift,/registerForRemoteNotifications\(\)/);
  assert.match(swift,/didRegisterForRemoteNotificationsWithDeviceToken/);
  assert.match(swift,/\/api\/devices\/push-token/);
  assert.match(swift,/foregroundRemoteOrder/);
  assert.match(swift,/completionHandler\(\[\.banner, \.list\]\)/);
  assert.match(entitlements,/aps-environment/);
  assert.match(project,/CODE_SIGN_ENTITLEMENTS = PrilavokPOS\/PrilavokPOS\.entitlements/);
  assert.match(project,/APS_ENVIRONMENT = development/);
  assert.match(project,/APS_ENVIRONMENT = production/);
});
