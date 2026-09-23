import Foundation
import Security
import CommonCrypto
#if canImport(UIKit)
import UIKit
#endif

struct AccessHTTPError: LocalizedError { let status:Int;let text:String;var errorDescription:String?{text} }

enum AccessError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let text)=self { return text };return nil }
}
struct AccessPIN: Codable {
    let salt: Data
    let hash: Data
    static func derive(_ pin: String, salt: Data) throws -> Data {
        let password=Array(pin.utf8);var output=[UInt8](repeating:0,count:32)
        let result=password.withUnsafeBytes { p in salt.withUnsafeBytes { s in
            CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2),p.bindMemory(to:Int8.self).baseAddress,password.count,s.bindMemory(to:UInt8.self).baseAddress,salt.count,CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),600_000,&output,output.count)
        }}
        guard result==kCCSuccess else { throw AccessError.message("Не удалось защитить пароль") };return Data(output)
    }
    init(_ pin:String) throws {
        guard (6...128).contains(pin.count),!pin.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { throw AccessError.message("Пароль должен содержать от 6 до 128 символов") }
        var bytes=[UInt8](repeating:0,count:16);guard SecRandomCopyBytes(kSecRandomDefault,bytes.count,&bytes)==errSecSuccess else { throw AccessError.message("Недоступен генератор случайных чисел") }
        salt=Data(bytes);hash=try Self.derive(pin,salt:salt)
    }
    func matches(_ pin:String) throws -> Bool {
        let candidate=try Self.derive(pin,salt:salt)
        guard candidate.count==hash.count else { return false }
        return zip(candidate,hash).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
    }
}
struct AccessRole: Codable { var id:String;var name:String;var permissions:[String] }
struct AccessAccount: Codable { var id:String;var name:String;var roleId:String;var pin:AccessPIN }
struct AccessOwner: Codable { var employeeId:String;var name:String;var installationId:String;var telegramId:String;var telegramName:String;var epoch:Int }
struct AccessPending: Codable { var id:String;var secret:String;var token:String;var installationId:String;var employeeId:String;var name:String;var kind:String }
struct AccessAttempt: Codable { var failures:Int=0;var blockedUntil:Double=0 }
struct AccessAudit: Codable { var at:Double;var actor:String;var action:String;var target:String }
struct AccessDocument: Codable {
    var version=1
    var installationId=UUID().uuidString
    var deviceKey=""
    var owner:AccessOwner?
    var accounts:[AccessAccount]=[]
    var roles:[AccessRole]=AccessCore.defaultRoles
    var attempts:[String:AccessAttempt]=[:]
    var pending:AccessPending?
    var appliedSession=""
    var audit:[AccessAudit]=[]
}
protocol AccessVault { func read() throws -> Data?;func write(_ data:Data) throws }
struct KeychainAccessVault: AccessVault {
    private var query:[String:Any] { [kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:"mpos.owner-access.v1",kSecAttrAccount as String:"state"] }
    func read() throws -> Data? {
        var q=query;q[kSecReturnData as String]=true;q[kSecMatchLimit as String]=kSecMatchLimitOne
        var result:CFTypeRef?;let status=SecItemCopyMatching(q as CFDictionary,&result)
        if status==errSecItemNotFound{return nil}
        guard status==errSecSuccess,let data=result as? Data else {throw AccessError.message("Keychain недоступен. Разблокируйте iPad и повторите вход")};return data
    }
    func write(_ data:Data) throws {
        let attributes:[String:Any]=[kSecValueData as String:data,kSecAttrAccessible as String:kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
        var status=SecItemUpdate(query as CFDictionary,attributes as CFDictionary)
        if status==errSecItemNotFound {status=SecItemAdd(query.merging(attributes){_,new in new} as CFDictionary,nil)}
        guard status==errSecSuccess else {throw AccessError.message("Не удалось сохранить доступ в Keychain. Действие не завершено")}
    }
}
final class AccessCore {
    static let permissions=["pos","receipts.view","receipts.print","receipts.return","products.view","products.edit","products.delete","stock.view","stock.edit","shifts.view","shifts.manage","cash.manage","analytics.view","analytics.export","settings.view","settings.edit","network.manage","bookings","backup.export"]
    static let defaultRoles=[AccessRole(id:"admin",name:"Администратор",permissions:permissions),AccessRole(id:"employee",name:"Кассир",permissions:["pos","receipts.view","receipts.print","shifts.view","shifts.manage","settings.view"])]
    static let legacyPermissions:Set<String>=["pos","receipts.view","receipts.print","products.view","stock.view","shifts.view","shifts.manage","settings.view","analytics.view","bookings","backup.export"]
    let vault:AccessVault
    private(set) var document:AccessDocument
    private(set) var actor:String?
    private var expires:Double=0
    init(vault:AccessVault) throws {self.vault=vault;if let data=try vault.read(){document=try JSONDecoder().decode(AccessDocument.self,from:data);guard document.version==1 else {throw AccessError.message("Неизвестная версия доступа")}}else{document=AccessDocument()}}
    func update(_ action:String,target:String="",_ mutation:(inout AccessDocument)throws->Void) throws {
        var next=document;try mutation(&next)
        next.audit.append(AccessAudit(at:Date().timeIntervalSince1970,actor:actor ?? "",action:action,target:target))
        try vault.write(JSONEncoder().encode(next));document=next
    }
    func logout(){actor=nil;expires=0}
    func activeAccount()->AccessAccount? {guard expires>Date().timeIntervalSince1970 else{logout();return nil};return document.accounts.first{$0.id==actor}}
    func allows(_ permission:String)->Bool {
        if document.owner==nil{return Self.legacyPermissions.contains(permission)}
        guard let a=activeAccount() else{return false}
        if a.id==document.owner?.employeeId{return true}
        return document.roles.first{$0.id==a.roleId}?.permissions.contains(permission)==true
    }
    func login(id:String,pin:String) throws {
        logout()
        let now=Date().timeIntervalSince1970;let attempt=document.attempts[id] ?? AccessAttempt()
        guard attempt.blockedUntil<=now else {throw AccessError.message("Слишком много попыток. Повторите через \(Int(ceil(attempt.blockedUntil-now))) сек.")}
        guard let account=document.accounts.first(where:{$0.id==id}) else{throw AccessError.message("Сотруднику ещё не назначен пароль")}
        guard try account.pin.matches(pin) else {
            try update("pin-failed",target:id){d in var a=d.attempts[id] ?? AccessAttempt();a.failures+=1;if a.failures>=5{a.blockedUntil=now+min(900,60*pow(2,Double(min(4,a.failures-5))))};d.attempts[id]=a}
            throw AccessError.message("Неверный пароль")
        }
        try update("login",target:id){$0.attempts[id]=AccessAttempt()};actor=id;expires=now+15*60
    }
    func requireOwner() throws {guard let a=activeAccount(),a.id==document.owner?.employeeId else{throw AccessError.message("Доступно только владельцу")}}
    func saveRole(id:String,name:String,permissions:[String]) throws {
        try requireOwner();guard id.range(of:"^[A-Za-z0-9_-]{1,100}$",options:.regularExpression) != nil,id != "owner",!name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,Set(permissions).isSubset(of:Set(Self.permissions)) else {throw AccessError.message("Некорректная роль")}
        try update("role-updated",target:id){d in d.roles.removeAll{$0.id==id};d.roles.append(AccessRole(id:id,name:String(name.prefix(80)),permissions:Array(Set(permissions)).sorted()))}
    }
    func saveAccount(id:String,name:String,roleId:String,pin:String) throws {
        try requireOwner();guard id.range(of:"^[A-Za-z0-9_-]{1,100}$",options:.regularExpression) != nil,id != document.owner?.employeeId,document.roles.contains(where:{$0.id==roleId}),!name.isEmpty else {throw AccessError.message("Нельзя изменить владельца или назначить неизвестную роль")}
        let verifier=try AccessPIN(pin)
        try update("account-updated",target:id){d in d.accounts.removeAll{$0.id==id};d.accounts.append(AccessAccount(id:id,name:String(name.prefix(120)),roleId:roleId,pin:verifier));d.attempts[id]=AccessAttempt()}
    }
    func createOwner(id:String,name:String,telegramId:String,pin:String) throws {
        guard document.owner==nil else {throw AccessError.message("Владелец уже создан. Повторное создание запрещено")}
        guard id.range(of:"^[A-Za-z0-9_-]{1,100}$",options:.regularExpression) != nil,!name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,
              telegramId.isEmpty || telegramId.range(of:"^[0-9]{1,20}$",options:.regularExpression) != nil else {throw AccessError.message("Проверьте имя и Telegram ID владельца")}
        let verifier=try AccessPIN(pin)
        try update("owner-created",target:id){d in
            d.owner=AccessOwner(employeeId:id,name:String(name.prefix(120)),installationId:d.installationId,telegramId:telegramId,telegramName:"",epoch:1)
            d.accounts.removeAll{$0.id==id};d.accounts.append(AccessAccount(id:id,name:String(name.prefix(120)),roleId:"owner",pin:verifier))
            d.pending=nil;d.deviceKey="";d.appliedSession="";d.attempts[id]=AccessAttempt()
        }
        actor=id;expires=Date().timeIntervalSince1970+15*60
    }
    func publicState()->[String:Any] {
        let active=activeAccount()
        return ["expiresAt":expires*1000,"configured":document.owner != nil,"ownerId":document.owner?.employeeId ?? "","telegramId":document.owner?.telegramId ?? "","actorId":active?.id ?? "","actorName":active?.name ?? "","isOwner":active != nil && active?.id==document.owner?.employeeId,"permissions":Self.permissions.filter{allows($0)},"accounts":document.accounts.map{["id":$0.id,"name":$0.name,"roleId":$0.roleId]},"roles":document.roles.map{["id":$0.id,"name":$0.name,"permissions":$0.permissions] as [String:Any]},"pending":document.pending != nil]
    }
}

#if canImport(UIKit)
final class OwnerAccessController {
    weak var presenter:UIViewController?
    private let queue=DispatchQueue(label:"mpos.owner-access")
    private var core:AccessCore?
    private var loadError:Error?
    private var busy=false
    init(presenter:UIViewController){self.presenter=presenter;do{core=try AccessCore(vault:KeychainAccessVault())}catch{loadError=error}}
    func lock(){queue.async{self.core?.logout()}}
    private func prompt(_ title:String,repeatPIN:Bool=false,completion:@escaping(String?)->Void){
        DispatchQueue.main.async{
            guard let presenter=self.presenter,presenter.presentedViewController==nil else{completion(nil);return}
            let alert=UIAlertController(title:title,message:repeatPIN ? "Пароль: 6–128 символов — буквы, цифры и символы. Восстановления нет.":"Введите пароль сотрудника",preferredStyle:.alert)
            alert.addTextField{$0.isSecureTextEntry=true;$0.keyboardType = .default;$0.autocapitalizationType = .none;$0.autocorrectionType = .no;$0.spellCheckingType = .no;$0.placeholder="Пароль";$0.textContentType = repeatPIN ? .newPassword : .password}
            if repeatPIN{alert.addTextField{$0.isSecureTextEntry=true;$0.keyboardType = .default;$0.autocapitalizationType = .none;$0.autocorrectionType = .no;$0.spellCheckingType = .no;$0.placeholder="Повторите пароль"}}
            alert.addAction(UIAlertAction(title:"Отмена",style:.cancel){_ in completion(nil)})
            alert.addAction(UIAlertAction(title:"Продолжить",style:.default){_ in let value=alert.textFields?[0].text ?? "";if repeatPIN && value != alert.textFields?[1].text{completion("")}else{completion(value)}})
            presenter.present(alert,animated:true)
        }
    }
    private func login(_ requested:String?,completion:@escaping(Error?)->Void){
        guard let core=core else{completion(loadError);return}
        func select(_ account:AccessAccount){self.prompt("Вход: \(account.name)"){pin in self.queue.async{guard let pin=pin else{completion(AccessError.message("Вход отменён"));return};do{try core.login(id:account.id,pin:pin);completion(nil)}catch{completion(error)}}}}
        if let requested=requested,let account=core.document.accounts.first(where:{$0.id==requested}){select(account);return}
        if requested != nil{completion(AccessError.message("Владелец должен назначить сотруднику роль и пароль"));return}
        DispatchQueue.main.async{
            guard let presenter=self.presenter,presenter.presentedViewController==nil else{completion(AccessError.message("Закройте открытый диалог"));return}
            let alert=UIAlertController(title:"Выберите сотрудника",message:nil,preferredStyle:.actionSheet)
            for account in core.document.accounts{alert.addAction(UIAlertAction(title:account.name,style:.default){_ in presenter.dismiss(animated:true){select(account)}})}
            alert.addAction(UIAlertAction(title:"Отмена",style:.cancel){_ in completion(AccessError.message("Вход отменён"))})
            alert.popoverPresentationController?.sourceView=presenter.view;alert.popoverPresentationController?.sourceRect=CGRect(x:presenter.view.bounds.midX,y:presenter.view.bounds.midY,width:1,height:1)
            presenter.present(alert,animated:true)
        }
    }
    func handle(_ body:[String:Any],completion:@escaping(Result<[String:Any],Error>)->Void){
        queue.async{
            guard !self.busy else{completion(.failure(AccessError.message("Дождитесь завершения проверки")));return};self.busy=true
            let finish:(Result<[String:Any],Error>)->Void={result in self.queue.async{self.busy=false;DispatchQueue.main.async{completion(result)}}}
            if self.core==nil {do{self.core=try AccessCore(vault:KeychainAccessVault());self.loadError=nil}catch{self.loadError=error}}
            guard let core=self.core else{finish(.failure(self.loadError ?? AccessError.message("Keychain недоступен")));return}
            let action=body["action"] as? String ?? ""
            func done(){finish(.success(core.publicState()))}
            do{
                switch action {
                case "status":done()
                case "logout":core.logout();done()
                case "authorize", "login":
                    let permission=body["permission"] as? String ?? "settings.view"
                    let requested=body["employeeId"] as? String
                    func check(_ error:Error?){if let error=error{finish(.failure(error))}else if action=="login" || core.allows(permission){done()}else{finish(.failure(AccessError.message("У вашей роли нет права на это действие")))}}
                    if core.document.owner==nil{check(nil)}else if core.activeAccount()==nil || (requested != nil && core.actor != requested){self.login(requested,completion:check)}else{check(nil)}
                case "saveRole":try core.saveRole(id:body["id"] as? String ?? UUID().uuidString,name:body["name"] as? String ?? "",permissions:body["permissions"] as? [String] ?? []);done()
                case "deleteRole":
                    try core.requireOwner();let id=body["id"] as? String ?? "";guard !["owner","admin","employee"].contains(id),!core.document.accounts.contains(where:{$0.roleId==id}) else{throw AccessError.message("Роль используется или является системной")};try core.update("role-deleted",target:id){$0.roles.removeAll{$0.id==id}};done()
                case "saveAccount":
                    try core.requireOwner();let id=body["id"] as? String ?? "",name=body["name"] as? String ?? "",role=body["roleId"] as? String ?? "employee"
                    guard !id.isEmpty,!name.isEmpty else{throw AccessError.message("Укажите сотрудника")}
                    self.prompt("Пароль: \(name)",repeatPIN:true){pin in self.queue.async{do{guard let pin=pin else{throw AccessError.message("Настройка пароля отменена")};try core.saveAccount(id:id,name:name,roleId:role,pin:pin);done()}catch{finish(.failure(error))}}}
                case "deleteAccount":
                    try core.requireOwner();let id=body["id"] as? String ?? "";guard id != core.document.owner?.employeeId,id != core.actor else{throw AccessError.message("Нельзя удалить владельца или текущего пользователя")};try core.update("account-deleted",target:id){$0.accounts.removeAll{$0.id==id};$0.attempts.removeValue(forKey:id)};done()
                case "createOwner":
                    guard core.document.owner==nil else {throw AccessError.message("Владелец уже создан")}
                    let id=body["employeeId"] as? String ?? "",name=body["name"] as? String ?? "",telegramId=body["telegramId"] as? String ?? ""
                    self.prompt("Создать владельца. Восстановления пароля нет",repeatPIN:true){pin in self.queue.async{do{guard let pin=pin else{throw AccessError.message("Создание владельца отменено")};try core.createOwner(id:id,name:name,telegramId:telegramId,pin:pin);done()}catch{finish(.failure(error))}}}
                default:throw AccessError.message("Неизвестная команда доступа")
                }
            }catch{finish(.failure(error))}
        }
    }
}
#endif
