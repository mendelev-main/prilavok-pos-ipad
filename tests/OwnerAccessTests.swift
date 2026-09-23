import Foundation
final class MemoryVault: AccessVault {
 var data:Data?;var fail=false
 func read()throws->Data?{data}
 func write(_ data:Data)throws{if fail{throw AccessError.message("storage failure")};self.data=data}
}
@main struct OwnerAccessTests {
 static func main()throws{
  let vault=MemoryVault(),core=try AccessCore(vault:vault)
  func check(_ condition:Bool,_ message:String){precondition(condition,message)}
  func rejected(_ action:()throws->Void){do{try action();fatalError("Expected rejection")}catch{}}
  let pin="246810",ownerId="owner-person"
  check(!core.allows("owner.manage"),"No implicit owner")
  let pending=AccessPending(id:"bind",secret:"secret",token:"token",installationId:core.document.installationId,employeeId:ownerId,name:"Owner",kind:"bind")
  try core.update("test"){$0.pending=pending}
  let owner=AccessOwner(employeeId:ownerId,name:"Owner",installationId:core.document.installationId,telegramId:"123",telegramName:"Owner TG",epoch:1)
  try core.installOwner(owner,pin:pin,session:"bind")
  check(core.allows("owner.manage") && core.allows("backup.import"),"Owner has all rights")
  check(!String(data:vault.data!,encoding:.utf8)!.contains(pin),"PIN never stored in plaintext")
  rejected{try core.installOwner(owner,pin:pin,session:"bind")}
  try core.saveRole(id:"reader",name:"Reader",permissions:["receipts.view"])
  try core.saveAccount(id:"reader-person",name:"Reader",roleId:"reader",pin:"135790")
  rejected{try core.saveAccount(id:ownerId,name:"Demote",roleId:"reader",pin:pin)}
  rejected{try core.saveRole(id:"owner",name:"Fake owner",permissions:[])}
  rejected{try core.saveRole(id:"fake",name:"Privilege escalation",permissions:["owner.manage"])}
  core.logout();try core.login(id:"reader-person",pin:"135790")
  check(core.allows("receipts.view") && !core.allows("receipts.return"),"Restricted role")
  rejected{try core.saveRole(id:"reader",name:"Escalate",permissions:AccessCore.permissions)}
  core.logout();let reload=try AccessCore(vault:vault)
  check(!reload.allows("receipts.view"),"Session does not survive restart")
  try reload.login(id:ownerId,pin:pin)
  let before=vault.data;vault.fail=true
  rejected{try reload.saveRole(id:"reader",name:"Corrupt",permissions:AccessCore.permissions)}
  check(vault.data==before && reload.document.roles.first{$0.id=="reader"}!.permissions==["receipts.view"],"Persist before publish")
  vault.fail=false
  for _ in 0..<5{rejected{try reload.login(id:"reader-person",pin:"000000")}}
  let blocked=try AccessCore(vault:vault);rejected{try blocked.login(id:"reader-person",pin:"135790")}
  check(blocked.document.attempts["reader-person"]!.failures==5,"Persistent throttle")
  var recovery=pending;recovery.id="recovery";recovery.kind="recover"
  try reload.update("test"){$0.pending=recovery}
  var recovered=owner;recovered.epoch=2
  try reload.installOwner(recovered,pin:"975310",session:"recovery")
  reload.logout();rejected{try reload.login(id:ownerId,pin:pin)};try reload.login(id:ownerId,pin:"975310")
  check(reload.allows("owner.manage"),"Recovery retains owner")
  print("OwnerAccess native core: 19 security assertions passed")
 }
}
