import Foundation
import Network
import UIKit

final class BluetoothPrinterManager: NSObject {
    var onEvent: (([String: Any]) -> Void)?
    private var networkConnections: [UUID: NWConnection] = [:]

    func print(order: [String: Any]) {
        guard let raw = order["__networkPrinterIp"] as? String else { event("printError","network_error","Не указан IP-адрес сетевого принтера"); return }
        let ip=raw.trimmingCharacters(in:.whitespacesAndNewlines)
        let portValue=(order["__networkPrinterPort"] as? NSNumber)?.intValue ?? 9100
        guard validIPv4(ip), let port=NWEndpoint.Port(rawValue: UInt16(clamping:portValue)) else { event("printError","network_error","Неверный IP-адрес принтера"); return }
        let test=(order["__networkTest"] as? Bool)==true
        let id=UUID(), connection=NWConnection(host:NWEndpoint.Host(ip),port:port,using:.tcp)
        networkConnections[id]=connection
        var finished=false
        func finish(){ guard !finished else{return}; finished=true; connection.cancel(); self.networkConnections.removeValue(forKey:id) }
        connection.stateUpdateHandler={ [weak self] state in
            guard let self=self,!finished else{return}
            switch state {
            case .ready:
                let data=test ? Self.testData() : ReceiptEncoder.encode(order:order)
                connection.send(content:data,completion:.contentProcessed{ error in
                    if let error=error { self.event("printError","network_error","Ошибка печати: \(error.localizedDescription)") }
                    else { self.event("printed","network_printed",test ? "Пробная печать отправлена" : "Чек отправлен на принтер") }
                    finish()
                })
            case .failed(let error): self.event("printError","network_error","Не удалось подключиться к принтеру: \(error.localizedDescription)"); finish()
            case .cancelled: finish()
            default: break
            }
        }
        connection.start(queue:.global(qos:.userInitiated))
    }
    private func event(_ type:String,_ status:String,_ message:String){ onEvent?(["type":type,"status":status,"message":message]) }
    private func validIPv4(_ ip:String)->Bool { let p=ip.split(separator:"."); return p.count==4 && p.allSatisfy{ Int($0).map{(0...255).contains($0)} ?? false } }
    private static func testData()->Data { var d=Data([0x1B,0x40]); d.append(Data("\nPRILAVOK POS\nTEST PRINT\nLAN TCP 9100 OK\n\n\n".utf8)); d.append(contentsOf:[0x1D,0x56,0x42,0x00]); return d }
}

private enum ReceiptEncoder {
    static func encode(order:[String:Any])->Data { encodeGraphic(order:order) }

    private static func encodeGraphic(order:[String:Any])->Data {
        let cfg=(order["__printerConfig"] as? [String:Any]) ?? [:]
        let paper=(cfg["paperWidth"] as? NSNumber)?.intValue ?? 80
        let width=paper<=58 ? 384 : 576
        let margin:CGFloat=paper<=58 ? 14 : 24
        let contentWidth=CGFloat(width)-margin*2
        let small=UIFont.systemFont(ofSize:paper<=58 ? 18:20)
        let regular=UIFont.systemFont(ofSize:paper<=58 ? 21:23)
        let medium=UIFont.systemFont(ofSize:paper<=58 ? 22:24,weight:.semibold)
        let bold=UIFont.systemFont(ofSize:paper<=58 ? 29:32,weight:.bold)
        let title=UIFont.systemFont(ofSize:paper<=58 ? 30:33,weight:.bold)

        enum Kind { case text, pair, separator }
        struct Row { let kind:Kind; let left:String; let right:String; let font:UIFont; let align:NSTextAlignment; let gap:CGFloat }
        var rows:[Row]=[]
        func add(_ text:String,_ font:UIFont=regular,_ align:NSTextAlignment = .left,_ gap:CGFloat=4){rows.append(Row(kind:.text,left:text,right:"",font:font,align:align,gap:gap))}
        func pair(_ left:String,_ right:String,_ font:UIFont=regular,_ gap:CGFloat=4){rows.append(Row(kind:.pair,left:left,right:right,font:font,align:.left,gap:gap))}
        func separator(_ gap:CGFloat=8){rows.append(Row(kind:.separator,left:"",right:"",font:small,align:.left,gap:gap))}
        func money(_ v:Double)->String{String(format:"%.2f BYN",v)}
        let kitchen=(order["__printDocumentType"] as? String)=="kitchen"

        if kitchen {
            add((order["receiptDisplayNumber"] as? String) ?? "#—",title,.center,3)
            add(dateText(order),small,.center,8)
            separator(7)
            add((order["orderType"] as? String) ?? "Заказ",medium,.center,8)
            separator(8)
            if let items=order["items"] as? [[String:Any]] {
                for item in items {
                    let q=number(item["qty"],1), name=(item["name"] as? String) ?? ""
                    add("\(qty(q)) × \(name)",bold,.left,4)
                    if let comment=item["comment"] as? String,!comment.isEmpty {add("↳ "+comment,regular,.left,9)}
                }
            }
        } else {
            add("ПРИЛАВОК",title,.center,14)
            add("Сотрудник: "+((order["employeeName"] as? String) ?? "Сотрудник"),small,.left,2)
            add("Касса: "+((order["registerName"] as? String) ?? "POS 1"),small,.left,11)
            if let customer=order["customer"] as? [String:Any] {
                let name=(customer["name"] as? String) ?? "",phone=(customer["phone"] as? String) ?? ""
                if !name.isEmpty {add("Клиент: "+name,regular,.left,2)}
                if !phone.isEmpty {add(phone,regular,.left,10)}
            }
            separator(8)
            add((order["orderType"] as? String) ?? "На месте",regular,.left,9)
            separator(10)
            if let items=order["items"] as? [[String:Any]] {
                for item in items {
                    let name=(item["name"] as? String) ?? "",q=number(item["qty"],1),price=number(item["price"])
                    let gross=q*price,dv=number(item["discountValue"]),dt=(item["discountType"] as? String) ?? ""
                    let disc=dt=="percent" ? gross*dv/100 : (dt.isEmpty ? 0 : dv*q)
                    pair(name,money(max(0,gross-disc)),medium,2)
                    add("\(qty(q)) × "+money(price),regular,.left,3)
                    if disc>0 {add("Скидка: −"+money(disc),small,.left,2)}
                    if cfg["printPaymentComments"] as? Bool != false, let comment=item["comment"] as? String,!comment.isEmpty {add("Комментарий: "+comment,small,.left,3)}
                    add("",small,.left,8)
                }
            }
            let delivery=number(order["deliveryFee"])
            if delivery>0 {pair("Доставка",money(delivery),regular,10)}
            separator(10)
            pair("Итого",money(number(order["total"])),bold,12)
            let cash=(order["method"] as? String)=="cash"
            pair(cash ? "Наличные":"Карта",money(number(order["total"])),regular,3)
            if cash {
                let given=number(order["cashGiven"])
                if given>0 {pair("Внесено",money(given),regular,3);pair("Сдача",money(number(order["change"])),medium,10)}
            }
            separator(9)
            pair(dateText(order),(order["receiptDisplayNumber"] as? String) ?? "#—",small,8)
        }

        func attrs(_ font:UIFont,_ alignment:NSTextAlignment)->[NSAttributedString.Key:Any]{let p=NSMutableParagraphStyle();p.alignment=alignment;p.lineBreakMode = .byWordWrapping;return [.font:font,.foregroundColor:UIColor.black,.paragraphStyle:p]}
        struct Measured {let row:Row;let leftAttrs:[NSAttributedString.Key:Any];let rightAttrs:[NSAttributedString.Key:Any];let height:CGFloat}
        var measured:[Measured]=[],height:CGFloat=kitchen ? 4 : 12
        for row in rows {
            if row.kind == .separator {measured.append(Measured(row:row,leftAttrs:[:],rightAttrs:[:],height:1));height += 1+row.gap;continue}
            let la=attrs(row.font,row.align),ra=attrs(row.font,.right)
            let available=row.kind == .pair ? contentWidth*0.67 : contentWidth
            let lb=(row.left as NSString).boundingRect(with:CGSize(width:available,height:.greatestFiniteMagnitude),options:[.usesLineFragmentOrigin,.usesFontLeading],attributes:la,context:nil)
            let rb=(row.right as NSString).boundingRect(with:CGSize(width:contentWidth*0.31,height:.greatestFiniteMagnitude),options:[.usesLineFragmentOrigin,.usesFontLeading],attributes:ra,context:nil)
            let h=max(ceil(lb.height),ceil(rb.height))+2
            measured.append(Measured(row:row,leftAttrs:la,rightAttrs:ra,height:h));height += h+row.gap
        }
        height += 14
        let format=UIGraphicsImageRendererFormat();format.scale=1;format.opaque=true
        let image=UIGraphicsImageRenderer(size:CGSize(width:CGFloat(width),height:ceil(height)),format:format).image {ctx in
            UIColor.white.setFill();ctx.fill(CGRect(x:0,y:0,width:CGFloat(width),height:ceil(height)))
            var y:CGFloat=kitchen ? 4 : 12
            for m in measured {
                if m.row.kind == .separator {
                    let c=ctx.cgContext;c.setStrokeColor(UIColor.black.cgColor);c.setLineWidth(1);c.setLineDash(phase:0,lengths:[3,3]);c.move(to:CGPoint(x:margin,y:y));c.addLine(to:CGPoint(x:CGFloat(width)-margin,y:y));c.strokePath()
                } else if m.row.kind == .pair {
                    (m.row.left as NSString).draw(with:CGRect(x:margin,y:y,width:contentWidth*0.66,height:m.height),options:[.usesLineFragmentOrigin,.usesFontLeading],attributes:m.leftAttrs,context:nil)
                    (m.row.right as NSString).draw(with:CGRect(x:margin+contentWidth*0.68,y:y,width:contentWidth*0.32,height:m.height),options:[.usesLineFragmentOrigin,.usesFontLeading],attributes:m.rightAttrs,context:nil)
                } else {
                    (m.row.left as NSString).draw(with:CGRect(x:margin,y:y,width:contentWidth,height:m.height),options:[.usesLineFragmentOrigin,.usesFontLeading],attributes:m.leftAttrs,context:nil)
                }
                y += m.height+m.row.gap
            }
        }
        guard let cg=image.cgImage else{return Data()}
        return raster(cg,width)
    }

    private static func raster(_ image:CGImage,_ width:Int)->Data {
        let height=image.height, bytesPerRow=width;var pixels=[UInt8](repeating:255,count:width*height)
        guard let ctx=CGContext(data:&pixels,width:width,height:height,bitsPerComponent:8,bytesPerRow:bytesPerRow,space:CGColorSpaceCreateDeviceGray(),bitmapInfo:CGImageAlphaInfo.none.rawValue) else{return Data()}
        ctx.setFillColor(gray:1,alpha:1);ctx.fill(CGRect(x:0,y:0,width:width,height:height));ctx.interpolationQuality = .none;ctx.draw(image,in:CGRect(x:0,y:0,width:width,height:height))
        let rowBytes=width/8;var bitmap=Data(capacity:rowBytes*height)
        for y in 0..<height { for bi in 0..<rowBytes { var byte:UInt8=0;for bit in 0..<8 { let x=bi*8+bit;if pixels[y*bytesPerRow+x]<180 { byte |= UInt8(0x80>>bit) } };bitmap.append(byte) } }
        var d=Data([0x1B,0x40]);d.append(contentsOf:[0x1D,0x76,0x30,0x00,UInt8(rowBytes&255),UInt8((rowBytes>>8)&255),UInt8(height&255),UInt8((height>>8)&255)]);d.append(bitmap);d.append(contentsOf:[0x0A,0x0A,0x0A,0x1D,0x56,0x42,0x00]);return d
    }
    private static func number(_ v:Any?,_ fallback:Double=0)->Double { if let n=v as? NSNumber{return n.doubleValue};if let d=v as? Double{return d};if let i=v as? Int{return Double(i)};if let s=v as? String,let d=Double(s.replacingOccurrences(of:",",with:".")){return d};return fallback }
    private static func qty(_ q:Double)->String { q.rounded()==q ? String(Int(q)) : String(format:"%.2f",q) }
    private static func dateText(_ order:[String:Any])->String { let ms=number(order["timestamp"]);return DateFormatter.localizedString(from:Date(timeIntervalSince1970:ms/1000),dateStyle:.short,timeStyle:.short) }
}
