import Foundation
import CoreBluetooth
import Network
import UIKit

final class BluetoothPrinterManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var central: CBCentralManager!
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var selected: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var networkConnections: [UUID: NWConnection] = [:]
    var onEvent: (([String: Any]) -> Void)?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            onEvent?(statusEvent())
        } else {
            onEvent?(["type":"status", "status":"bluetooth_unavailable", "message":"Включите Bluetooth на iPad"])
        }
    }

    func scan() {
        guard central.state == .poweredOn else {
            onEvent?(["type":"status", "status":"bluetooth_unavailable", "message":"Bluetooth недоступен"])
            return
        }
        peripherals.removeAll()
        onEvent?(["type":"scanStarted"])
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
            self?.central.stopScan()
            self?.onEvent?(["type":"scanFinished"])
        }
    }

    func select(id: String) {
        guard let uuid = UUID(uuidString: id), let p = peripherals[uuid] else { return }
        selected = p
        writeCharacteristic = nil
        central.stopScan()
        p.delegate = self
        central.connect(p, options: nil)
        onEvent?(["type":"status", "status":"connecting", "name":p.name ?? "Printer"])
    }

    func disconnect() {
        if let p = selected { central.cancelPeripheralConnection(p) }
        selected = nil
        writeCharacteristic = nil
        onEvent?(statusEvent())
    }

    func print(order: [String: Any]) {
        if let notificationSound = order["__notificationSound"] as? String {
            NativeNotificationSound.play(named: notificationSound)
            onEvent?(["type":"notificationSoundPlayed", "sound":notificationSound])
            return
        }

        if let rawIp = order["__networkPrinterIp"] as? String {
            let ip = rawIp.trimmingCharacters(in: .whitespacesAndNewlines)
            let requestedPort = (order["__networkPrinterPort"] as? NSNumber)?.intValue ?? 9100
            let port = UInt16(clamping: requestedPort)
            let isTest = (order["__networkTest"] as? Bool) == true
            printNetwork(order: order, ip: ip, port: port == 0 ? 9100 : port, testOnly: isTest)
            return
        }

        guard let p = selected, let ch = writeCharacteristic else {
            onEvent?(["type":"printError", "message":"Сначала подключите Bluetooth-принтер"])
            return
        }
        let data = ReceiptEncoder.encode(order: order)
        let type: CBCharacteristicWriteType = ch.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
        p.writeValue(data, for: ch, type: type)
        onEvent?(["type":"printed", "message":"Чек отправлен на принтер"])
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
                            self.onEvent?(["type":"printed", "status":"network_connected", "ip":ip, "port":Int(port), "message":"Пробная печать отправлена"])
                        }
                        finish()
                    })
                    return
                }
                let data = ReceiptEncoder.encode(order: order)
                connection.send(content: data, completion: .contentProcessed { error in
                    if let error = error {
                        self.onEvent?(["type":"printError", "status":"network_error", "message":"Не удалось отправить чек: \(error.localizedDescription)"])
                    } else {
                        self.onEvent?(["type":"printed", "status":"network_connected", "ip":ip, "message":"Чек отправлен на принтер"])
                    }
                    finish()
                })
            case .failed:
                self.onEvent?(["type":"printError", "status":"network_error", "message":"Принтер недоступен. Проверьте IP-адрес и подключение к одной сети"])
                finish()
            case .cancelled:
                self.networkConnections.removeValue(forKey: id)
            default:
                break
            }
        }

        connection.start(queue: .main)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            guard let self = self, self.networkConnections[id] != nil, !completed else { return }
            self.onEvent?(["type":"printError", "status":"network_error", "message":"Принтер не отвечает. Проверьте IP-адрес и Wi‑Fi"])
            finish()
        }
    }

    private func isValidIPv4(_ value: String) -> Bool {
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard !part.isEmpty, part.count <= 3, let number = Int(part) else { return false }
            return number >= 0 && number <= 255
        }
    }

    func statusEvent() -> [String: Any] {
        if let p = selected, writeCharacteristic != nil {
            return ["type":"status", "status":"connected", "name":p.name ?? "Printer", "id":p.identifier.uuidString]
        }
        return ["type":"status", "status":"disconnected"]
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        peripherals[peripheral.identifier] = peripheral
        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? "Bluetooth printer"
        onEvent?(["type":"printer", "id":peripheral.identifier.uuidString, "name":name, "rssi":RSSI.intValue])
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        onEvent?(["type":"status", "status":"error", "message":"Не удалось подключиться к принтеру"])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        writeCharacteristic = nil
        onEvent?(statusEvent())
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services ?? [] { peripheral.discoverCharacteristics(nil, for: service) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let ch = service.characteristics?.first(where: { $0.properties.contains(.writeWithoutResponse) || $0.properties.contains(.write) }) {
            writeCharacteristic = ch
            onEvent?(statusEvent())
        }
    }
}

private enum ReceiptEncoder {
    static func encode(order: [String: Any]) -> Data {
        let config = order["__printerConfig"] as? [String: Any]
        let mode = (config?["printMode"] as? String) ?? "graphic"
        if mode == "graphic" {
            return encodeGraphic(order: order, config: config)
        }
        return encodeText(order: order)
    }

    private static func encodeGraphic(order: [String: Any], config: [String: Any]?) -> Data {
        let paperWidth = (config?["paperWidth"] as? NSNumber)?.intValue ?? 80
        let requestedWidth = config?["printWidth"] as? String
        let dpi = (config?["dpi"] as? NSNumber)?.intValue ?? 203
        let dotsPerMM = CGFloat(dpi) / 25.4
        let printableMM: CGFloat
        if let requestedWidth, let mm = Double(requestedWidth) {
            printableMM = CGFloat(mm)
        } else {
            printableMM = paperWidth >= 80 ? 72 : 48
        }
        var width = Int((printableMM * dotsPerMM).rounded(.down))
        width = max(128, min(width, 576))
        width -= width % 8

        func cfgNumber(_ key: String, _ fallback: CGFloat) -> CGFloat { (config?[key] as? NSNumber).map { CGFloat($0.doubleValue) } ?? fallback }
        func cfgBool(_ key: String, _ fallback: Bool = true) -> Bool { (config?[key] as? Bool) ?? fallback }
        func cfgText(_ key: String, _ fallback: String = "") -> String { (config?[key] as? String) ?? fallback }
        let margin = cfgNumber("contentPadding", 12)
        let contentWidth = CGFloat(width) - margin * 2
        let regular = UIFont.systemFont(ofSize: cfgNumber("bodySize", 24), weight: .regular)
        let medium = UIFont.systemFont(ofSize: cfgNumber("bodySize", 24), weight: .semibold)
        let bold = UIFont.systemFont(ofSize: cfgNumber("totalSize", 28), weight: .bold)
        let title = UIFont.systemFont(ofSize: cfgNumber("titleSize", 32), weight: .bold)
        let small = UIFont.systemFont(ofSize: cfgNumber("smallSize", 21), weight: .regular)
        let lineGap = cfgNumber("lineSpacing", 5)
        let sectionGap = cfgNumber("sectionSpacing", 8)
        let itemGap = cfgNumber("itemSpacing", 8)
        let showCurrency = cfgBool("showCurrency")
        let curr = showCurrency ? currency(order) : ""
        func money(_ value: Double) -> String { showCurrency ? String(format: "%.2f %@", value, curr) : String(format: "%.2f", value) }
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        let right = NSMutableParagraphStyle()
        right.alignment = .right

        var rows: [(String, UIFont, NSTextAlignment, CGFloat)] = []
        func add(_ text: String, _ font: UIFont = regular, _ align: NSTextAlignment = .left, _ gap: CGFloat = 5) {
            guard !text.isEmpty else { return }
            rows.append((text, font, align, gap))
        }
        func separator() { add(String(repeating: "—", count: 28), small, .center, 7) }

        let isKitchen = (order["__printDocumentType"] as? String) == "kitchen"
        if isKitchen {
            add((order["receiptDisplayNumber"] as? String) ?? "#—", title, .center, sectionGap)
            add((order["orderLabel"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? ((order["orderType"] as? String) ?? "Заказ"), title, .center, sectionGap)
            let dateText = DateFormatter.localizedString(from: Date(timeIntervalSince1970: (number(order["timestamp"]) / 1000)), dateStyle: .short, timeStyle: .short)
            add(dateText, small, .left, 2)
            add("\((order["employeeName"] as? String) ?? "Сотрудник"), \((order["registerName"] as? String) ?? "POS 1")", small, .left, sectionGap)
            if cfgBool("showSeparators") { separator() }
            add((order["orderType"] as? String) ?? "Заказ", bold, .center, sectionGap)
            if cfgBool("showSeparators") { separator() }
            if let items = order["items"] as? [[String: Any]] {
                for item in items {
                    let name = (item["name"] as? String) ?? ""
                    let qty = number(item["qty"], fallback: 1)
                    add("\(formatQty(qty)) × \(name)", bold, .left, itemGap)
                    if let comment = item["comment"] as? String, !comment.isEmpty { add(comment, small, .left, itemGap) }
                }
            }
            if cfgBool("showSeparators") { separator() }
        } else {
        add(cfgText("receiptTitle", "ПРИЛАВОК"), title, .center, sectionGap)
        add(cfgText("receiptSubtitle"), medium, .center, lineGap)
        add(cfgText("receiptHeaderComment"), small, .center, sectionGap)
        if cfgBool("showSeparators") { separator() }
        if cfgBool("showReceiptNumber") { add((order["receiptDisplayNumber"] as? String) ?? "#—", medium, .right, lineGap) }
        let metaDate = DateFormatter.localizedString(from: Date(timeIntervalSince1970: (number(order["timestamp"]) / 1000)), dateStyle: .short, timeStyle: .short)
        if cfgBool("showDate") { add(metaDate, small, .left, lineGap) }
        if cfgBool("showEmployee") { add("Сотрудник: " + ((order["employeeName"] as? String) ?? "Сотрудник"), small, .left, lineGap) }
        if cfgBool("showRegister") { add("Касса: " + ((order["registerName"] as? String) ?? "POS 1"), small, .left, sectionGap) }
        if cfgBool("showCustomer"), let customer = order["customer"] as? [String: Any] {
            let name = (customer["name"] as? String) ?? "", phone = (customer["phone"] as? String) ?? ""
            if !name.isEmpty { add("Клиент: " + name, small, .left, 2) }
            if !phone.isEmpty { add(phone, small, .left, sectionGap) }
        }
        let label = (order["orderLabel"] as? String) ?? ""
        if cfgBool("showOrderLabel") { add(label, medium) }
        if cfgBool("showOrderType"), let type = order["orderType"] as? String { add(type, medium) }
        if cfgBool("showSeparators") { separator() }

        if cfgBool("showItems"), let items = order["items"] as? [[String: Any]] {
            for item in items {
                let name = (item["name"] as? String) ?? ""
                let qty = number(item["qty"], fallback: 1)
                let price = number(item["price"])
                add("\(name) \(cfgText("itemQtySymbol", "×")) \(formatQty(qty))", medium, .left, 2)
                add(money(price * qty), regular, .right, itemGap)
                if cfgBool("showItemComments"), let comment = item["comment"] as? String, !comment.isEmpty {
                    add("Комментарий: \(comment)", small, .left, lineGap)
                }
            }
        }

        if cfgBool("showSeparators") { separator() }
        if cfgBool("showPayments") { add(cfgText("paymentsTitle", "ПЛАТЕЖИ"), medium, .left, lineGap) }
        if cfgBool("showPayments"), let payments = order["payments"] as? [[String: Any]], !payments.isEmpty {
            for (index, payment) in payments.enumerated() {
                let method = ((payment["method"] as? String) == "cash") ? "Наличные" : "Карта"
                add("\(index + 1). \(method)", regular, .left, 2)
                add(money(number(payment["amount"])), regular, .right, lineGap)
                if cfgBool("showCashDetails"), method == "Наличные", payment["cashGiven"] != nil {
                    add("Внесено: \(money(number(payment["cashGiven"])))", small)
                    add("Сдача: \(money(number(payment["change"])))", small)
                }
            }
        } else if cfgBool("showPayments") {
            add(((order["method"] as? String) == "cash") ? "НАЛИЧНЫЕ" : "КАРТА", regular)
        }

        if cfgBool("showSeparators") { separator() }
        add("\(cfgText("totalPrefix", "ИТОГО:")) \(money(number(order["total"])))", bold, .right, sectionGap)
        if cfgBool("showOrderComment"), let comment = order["comment"] as? String, !comment.isEmpty {
            add("Комментарий: \(comment)", small, .left, sectionGap)
        }
        if cfgBool("showThankYou") { add(cfgText("receiptFooter", "Спасибо!"), regular, .center, lineGap) }
        add(cfgText("receiptFooterComment"), small, .center, 18)
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

