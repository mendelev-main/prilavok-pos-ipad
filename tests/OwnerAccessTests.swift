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
  let empty=MemoryVault();empty.fail=true;let failed=try AccessCore(vault:empty)
  rejected{try failed.createOwner(id:ownerId,name:"Owner",telegramId:"123",pin:pin)}
  check(failed.document.owner==nil && !failed.allows("owner.manage"),"Failed write cannot create owner")
  try core.createOwner(id:ownerId,name:"Owner",telegramId:"123",pin:pin)
  check(core.allows("owner.manage") && core.allows("backup.import"),"Owner has all rights")
  check(!String(data:vault.data!,encoding:.utf8)!.contains(pin),"PIN never stored in plaintext")
  rejected{try core.createOwner(id:"second",name:"Second",telegramId:"456",pin:pin)}
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
  rejected{try reload.createOwner(id:ownerId,name:"Replacement",telegramId:"456",pin:"975310")}
  try reload.login(id:ownerId,pin:pin)
  check(reload.allows("owner.manage"),"Original owner PIN survives restart")
  check(reload.document.owner?.telegramId=="123","Owner identity cannot be replaced")
  print("OwnerAccess local creation, durability, roles, throttle and immutable owner checks passed")
 }
}
