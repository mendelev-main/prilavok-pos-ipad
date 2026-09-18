import Foundation
import CoreBluetooth
import Network

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
        var d = Data([0x1B, 0x40]) // initialize
        let width = 48
        let label = (order["orderLabel"] as? String) ?? ""
        let method = ((order["method"] as? String) == "cash") ? "НАЛИЧНЫЕ" : "КАРТА"
        let total = (order["total"] as? NSNumber)?.doubleValue ?? 0
        let currency = (order["currency"] as? String) ?? "BYN"

        d.append(utf8("ПРИЛАВОК\n"))
        d.append(utf8(String(repeating: "-", count: width) + "\n"))
        if !label.isEmpty { d.append(utf8(label + "\n")) }
        if let type = order["orderType"] as? String { d.append(utf8(type + "\n")) }
        d.append(utf8(String(repeating: "-", count: width) + "\n"))

        if let items = order["items"] as? [[String: Any]] {
            for item in items {
                let name = (item["name"] as? String) ?? ""
                let qty = (item["qty"] as? NSNumber)?.doubleValue ?? 1
                let price = (item["price"] as? NSNumber)?.doubleValue ?? 0
                let sum = price * qty
                d.append(utf8("\(name) x\(formatQty(qty))\n"))
                d.append(utf8(String(format: "%32.2f %@\n", sum, currency)))
            }
        }
        if let payments = order["payments"] as? [[String: Any]], !payments.isEmpty {
            d.append(utf8(String(repeating: "-", count: width) + "\n"))
            d.append(utf8("ПЛАТЕЖИ\n"))
            for (index, payment) in payments.enumerated() {
                let paymentMethod = ((payment["method"] as? String) == "cash") ? "Наличные" : "Карта"
                let amount = (payment["amount"] as? NSNumber)?.doubleValue ?? 0
                d.append(utf8(String(format: "%d. %@\n", index + 1, paymentMethod)))
                d.append(utf8(String(format: "%32.2f %@\n", amount, currency)))
                if paymentMethod == "Наличные", let given = payment["cashGiven"] as? NSNumber {
                    let change = (payment["change"] as? NSNumber)?.doubleValue ?? 0
                    d.append(utf8(String(format: "   Внесено: %.2f %@\n", given.doubleValue, currency)))
                    d.append(utf8(String(format: "   Сдача: %.2f %@\n", change, currency)))
                }
            }
        } else {
            d.append(utf8(String(repeating: "-", count: width) + "\n"))
            d.append(utf8("ПЛАТЕЖИ\n"))
            d.append(utf8("\(method)\n"))
        }
        d.append(Data([0x1B, 0x45, 0x01]))
        d.append(utf8(String(format: "ИТОГО: %.2f %@\n", total, currency)))
        d.append(Data([0x1B, 0x45, 0x00]))
        d.append(utf8("\nСпасибо!\n\n\n"))
        d.append(Data([0x1D, 0x56, 0x00])) // cut
        return d
    }

    private static func utf8(_ s: String) -> Data { Data(s.utf8) }
    private static func formatQty(_ q: Double) -> String { q.rounded() == q ? String(Int(q)) : String(format: "%.2f", q) }
}
