import Foundation
import Network
import UIKit

final class BluetoothPrinterManager: NSObject {
    var onEvent: (([String: Any]) -> Void)?
    private var networkConnections: [UUID: NWConnection] = [:]

    func print(order: [String: Any]) {
        guard let rawIp = order["__networkPrinterIp"] as? String else {
            onEvent?(["type":"printError", "status":"network_error", "message":"Для печати не указан IP-адрес сетевого принтера"])
            return
        }
        let ip = rawIp.trimmingCharacters(in: .whitespacesAndNewlines)
        let requestedPort = (order["__networkPrinterPort"] as? NSNumber)?.intValue ?? 9100
        let port = UInt16(clamping: requestedPort)
        let isTest = (order["__networkTest"] as? Bool) == true
        printNetwork(order: order, ip: ip, port: port == 0 ? 9100 : port, testOnly: isTest)
    }

    private func printNetwork(order: [String: Any], ip: String, port: UInt16, testOnly: Bool) {
        guard isValidIPv4(ip), let nwPort = NWEndpoint.Port(rawValue: port) else {
            onEvent?(["type":"printError", "status":"network_error", "message":"Неверный IP-адрес принтера"])
            return
        }

        let id = UUID()
        let connection = NWConnection(host: NWEndpoint.Host(ip), port: nwPort, using: .tcp)
        networkConnections[id] = connection
        var completed = false

        func finish() {
            guard !completed else { return }
            completed = true
            connection.cancel()
            self.networkConnections.removeValue(forKey: id)
        }

        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self, !completed else { return }
            switch state {
            case .ready:
                if testOnly {
                    // A test must exercise the full printing path, not only the TCP handshake.
                    // Keep the payload ASCII-only so it prints independently of the printer code page.
                    var testData = Data([0x1B, 0x40]) // ESC @ — initialize
                    testData.append(Data("\nPRILAVOK POS\nTEST PRINT\nPrinter connected\n\n\n".utf8))
                    testData.append(contentsOf: [0x1D, 0x56, 0x42, 0x00]) // GS V B 0 — cut
                    connection.send(content: testData, completion: .contentProcessed { error in
                        if let error = error {
                            self.onEvent?(["type":"printError", "status":"network_error", "message":"Не удалось выполнить пробную печать: \(error.localizedDescription)"])
                        } else {
        // Fixed Prilavok payment receipt layout. This is intentionally not user-configurable.
        let receiptTitle = cfgText("receiptTitle", "ПРИЛАВОК")
        if !receiptTitle.isEmpty { add(receiptTitle, title, .center, sectionGap) }

        add("Сотрудник: " + ((order["employeeName"] as? String) ?? "Сотрудник"), small, .left, 2)
        add("Касса: " + ((order["registerName"] as? String) ?? "POS 1"), small, .left, sectionGap)

        if let customer = order["customer"] as? [String: Any] {
            let name = (customer["name"] as? String) ?? ""
            let phone = (customer["phone"] as? String) ?? ""
            if !name.isEmpty { add("Клиент: " + name, small, .left, 2) }
            if !phone.isEmpty { add(phone, small, .left, sectionGap) }
        }

        separator()
        add((order["orderType"] as? String) ?? "На месте", regular, .left, sectionGap)
        separator()

        if let items = order["items"] as? [[String: Any]] {
            for item in items {
                let name = (item["name"] as? String) ?? ""
                let qty = number(item["qty"], fallback: 1)
                let price = number(item["price"])
                let discountValue = number(item["discountValue"])
                let discountType = (item["discountType"] as? String) ?? ""
                let gross = price * qty
                let discountAmount = discountType == "percent" ? gross * discountValue / 100.0 : (discountType.isEmpty ? 0 : discountValue * qty)
                let lineTotal = max(0, gross - discountAmount)
                add(name + "                                      " + money(lineTotal), medium, .left, 1)
                add("\(formatQty(qty)) × " + money(price), regular, .left, 2)
                if discountAmount > 0 { add("Скидка: −" + money(discountAmount), small, .left, 2) }
                if let comment = item["comment"] as? String, !comment.isEmpty { add("Комментарий: " + comment, small, .left, 2) }
                add("", small, .left, itemGap)
            }
        }

        let deliveryFee = number(order["deliveryFee"])
        if deliveryFee > 0 {
            add("Доставка                                      " + money(deliveryFee), regular, .left, sectionGap)
        }

        separator()
        add("Итого                                      " + money(number(order["total"])), bold, .left, sectionGap)

        if let payments = order["payments"] as? [[String: Any]], !payments.isEmpty {
            for payment in payments {
                let cash = (payment["method"] as? String) == "cash"
                add((cash ? "Наличные" : "Карта") + "                                      " + money(number(payment["amount"])), regular, .left, 2)
                if cash, payment["cashGiven"] != nil {
                    add("Внесено                                      " + money(number(payment["cashGiven"])), regular, .left, 2)
                    add("Сдача                                      " + money(number(payment["change"])), regular, .left, sectionGap)
                }
            }
        } else {
            let cash = (order["method"] as? String) == "cash"
            add((cash ? "Наличные" : "Карта") + "                                      " + money(number(order["total"])), regular, .left, 2)
            if cash, order["cashGiven"] != nil {
                add("Внесено                                      " + money(number(order["cashGiven"])), regular, .left, 2)
                add("Сдача                                      " + money(number(order["change"])), regular, .left, sectionGap)
            }
        }

        separator()
        let footerDate = DateFormatter.localizedString(from: Date(timeIntervalSince1970: (number(order["timestamp"]) / 1000)), dateStyle: .short, timeStyle: .short)
        let footerNumber = (order["receiptDisplayNumber"] as? String) ?? "#—"
        add(footerDate + "                              " + footerNumber, small, .left, 10)
        }
        
        func attrs(_ font: UIFont, _ alignment: NSTextAlignment) -> [NSAttributedString.Key: Any] {
            let p = NSMutableParagraphStyle()
            p.alignment = alignment
            p.lineBreakMode = .byWordWrapping
            return [.font: font, .foregroundColor: UIColor.black, .paragraphStyle: p]
        }

        var measured: [(String, [NSAttributedString.Key: Any], CGFloat, CGFloat)] = []
        var height: CGFloat = 10
        for row in rows {
            let a = attrs(row.1, row.2)
            let box = (row.0 as NSString).boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: a, context: nil)
            let h = ceil(box.height) + 2
            measured.append((row.0, a, h, row.3))
            height += h + row.3
        }
        height += 12

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: CGFloat(width), height: ceil(height)), format: format)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: CGFloat(width), height: ceil(height)))
            var y: CGFloat = 10
            for row in measured {
                (row.0 as NSString).draw(with: CGRect(x: margin, y: y, width: contentWidth, height: row.2), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: row.1, context: nil)
                y += row.2 + row.3
            }
        }
        guard let cg = image.cgImage else { return encodeText(order: order) }
        return rasterData(cgImage: cg, width: width)
    }

    private static func rasterData(cgImage: CGImage, width: Int) -> Data {
        let height = cgImage.height
        let bytesPerRow = width
        var pixels = [UInt8](repeating: 255, count: width * height)
        guard let ctx = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
            return Data()
        }
        ctx.setFillColor(gray: 1, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        ctx.interpolationQuality = .none
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let rowBytes = width / 8
        var bitmap = Data(capacity: rowBytes * height)
        for y in 0..<height {
            for byteIndex in 0..<rowBytes {
                var byte: UInt8 = 0
                for bit in 0..<8 {
                    let x = byteIndex * 8 + bit
                    if pixels[y * bytesPerRow + x] < 180 {
                        byte |= UInt8(0x80 >> bit)
                    }
                }
                bitmap.append(byte)
            }
        }

        var d = Data([0x1B, 0x40])
        let xL = UInt8(rowBytes & 0xff), xH = UInt8((rowBytes >> 8) & 0xff)
        let yL = UInt8(height & 0xff), yH = UInt8((height >> 8) & 0xff)
        d.append(contentsOf: [0x1D, 0x76, 0x30, 0x00, xL, xH, yL, yH])
        d.append(bitmap)
        d.append(contentsOf: [0x0A, 0x0A, 0x0A, 0x1D, 0x56, 0x42, 0x00])
        return d
    }

    private static func encodeText(order: [String: Any]) -> Data {
        var d = Data([0x1B, 0x40])
        let width = 48
        let label = (order["orderLabel"] as? String) ?? ""
        let method = ((order["method"] as? String) == "cash") ? "НАЛИЧНЫЕ" : "КАРТА"
        let total = number(order["total"])
        let curr = currency(order)
        d.append(utf8("ПРИЛАВОК\n"))
        d.append(utf8(String(repeating: "-", count: width) + "\n"))
        if !label.isEmpty { d.append(utf8(label + "\n")) }
        if let type = order["orderType"] as? String { d.append(utf8(type + "\n")) }
        d.append(utf8(String(repeating: "-", count: width) + "\n"))
        if let items = order["items"] as? [[String: Any]] {
            for item in items {
                let name = (item["name"] as? String) ?? ""
                let qty = number(item["qty"], fallback: 1)
                let sum = number(item["price"]) * qty
                d.append(utf8("\(name) x\(formatQty(qty))\n"))
                d.append(utf8(String(format: "%32.2f %@\n", sum, curr)))
            }
        }
        d.append(utf8(String(repeating: "-", count: width) + "\nПЛАТЕЖИ\n"))
        d.append(utf8("\(method)\n"))
        d.append(Data([0x1B, 0x45, 0x01]))
        d.append(utf8(String(format: "ИТОГО: %.2f %@\n", total, curr)))
        d.append(Data([0x1B, 0x45, 0x00]))
        d.append(utf8("\nСпасибо!\n\n\n"))
        d.append(Data([0x1D, 0x56, 0x00]))
        return d
    }

    private static func number(_ value: Any?, fallback: Double = 0) -> Double {
        if let n = value as? NSNumber { return n.doubleValue }
        if let d = value as? Double { return d }
        if let i = value as? Int { return Double(i) }
        if let s = value as? String, let d = Double(s.replacingOccurrences(of: ",", with: ".")) { return d }
        return fallback
    }
    private static func currency(_ order: [String: Any]) -> String { (order["currency"] as? String) ?? "BYN" }
    private static func utf8(_ s: String) -> Data { Data(s.utf8) }
    private static func formatQty(_ q: Double) -> String { q.rounded() == q ? String(Int(q)) : String(format: "%.2f", q) }
}

