import UIKit
import WebKit
import UniformTypeIdentifiers
import PhotosUI
import Foundation

@main
final class PrilavokPOSApp: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = POSViewController()
        self.window = window
        window.makeKeyAndVisible()
        return true
    }
}

final class POSViewController: UIViewController, WKScriptMessageHandler, PHPickerViewControllerDelegate {
    private var webView: WKWebView!
    private let bluetooth = BluetoothPrinterManager()

    override func loadView() {
        let contentController = WKUserContentController()
        contentController.add(self, name: "printer")
        contentController.add(self, name: "telegram")
        contentController.add(self, name: "photoPicker")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        configuration.websiteDataStore = .default()

        let web = WKWebView(frame: .zero, configuration: configuration)
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.scrollView.bounces = false
        web.scrollView.alwaysBounceVertical = false
        web.scrollView.alwaysBounceHorizontal = false
        web.backgroundColor = .white
        web.isOpaque = true
        webView = web

        let container = UIView()
        container.backgroundColor = .systemBackground
        container.addSubview(web)
        web.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            web.leadingAnchor.constraint(equalTo: container.safeAreaLayoutGuide.leadingAnchor),
            web.trailingAnchor.constraint(equalTo: container.safeAreaLayoutGuide.trailingAnchor),
            web.topAnchor.constraint(equalTo: container.safeAreaLayoutGuide.topAnchor),
            web.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bluetooth.onEvent = { [weak self] event in
            self?.sendPrinterEvent(event)
        }

        guard let url = Bundle.main.url(forResource: "pos", withExtension: "html") else {
            let message = "Файл pos.html не найден в приложении."
            webView.loadHTMLString("<html><body style='font-family:-apple-system;text-align:center;padding:40px'><h2>Ошибка</h2><p>\(message)</p></body></html>", baseURL: nil)
            return
        }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "photoPicker" {
            presentPhotoPicker()
            return
        }

        guard (message.name == "printer" || message.name == "telegram"),
              let body = message.body as? [String: Any],
              let action = body["action"] as? String else { return }

        switch action {
        case "test":
            telegramTest(body: body)
        case "send":
            telegramSend(body: body)
        case "sendShiftCloseReport":
            telegramSendShiftCloseReport(body: body)
        case "scan":
            bluetooth.scan()
        case "disconnect":
            bluetooth.disconnect()
        case "select":
            if let id = body["id"] as? String { bluetooth.select(id: id) }
        case "print":
            if let order = body["order"] as? [String: Any] { bluetooth.print(order: order) }
        case "status":
            sendPrinterEvent(bluetooth.statusEvent())
        case "sharePurchaseOrder":
            if let order = body["order"] as? [String: Any] {
                sharePurchaseOrder(order: order)
            }
        case "printShiftReport":
            if let report = body["report"] as? [String: Any] {
                printShiftReport(report: report)
            }
        default:
            break
        }
    }


    private func presentPhotoPicker() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider else { return }
        let typeIdentifier = UTType.image.identifier
        guard provider.hasItemConformingToTypeIdentifier(typeIdentifier) else { return }
        provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] data, _ in
            guard let self = self, let data = data, let image = UIImage(data: data) else { return }
            let prepared = self.prepareProductImage(image)
            guard let base64 = prepared.jpegData(compressionQuality: 0.82)?.base64EncodedString() else { return }
            let js = "window.handleNativeProductImage && window.handleNativeProductImage('data:image/jpeg;base64,\(base64)');"
            DispatchQueue.main.async {
                self.webView.evaluateJavaScript(js, completionHandler: nil)
            }
        }
    }

    private func prepareProductImage(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1200
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let size = CGSize(width: max(1, image.size.width * scale), height: max(1, image.size.height * scale))
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private func telegramTest(body: [String: Any]) {
        let token = body["botToken"] as? String ?? ""
        let chatId = body["chatId"] as? String ?? ""
        let threadId = body["threadId"] as? String ?? ""
        guard !token.isEmpty, !chatId.isEmpty else {
            sendTelegramResult(ok: false, message: "Укажите токен бота и ID рабочей группы.")
            return
        }
        let text = "🟢 <b>Telegram подключён</b>\nПрилавок POS успешно связался с рабочей группой."
        telegramRequest(token: token, chatId: chatId, threadId: threadId, text: text) { [weak self] ok, message in
            self?.sendTelegramResult(ok: ok, message: message)
        }
    }

    private func telegramSend(body: [String: Any]) {
        let token = body["botToken"] as? String ?? ""
        let chatId = body["chatId"] as? String ?? ""
        let threadId = body["threadId"] as? String ?? ""
        let text = body["text"] as? String ?? ""
        guard !token.isEmpty, !chatId.isEmpty, !text.isEmpty else { return }
        telegramRequest(token: token, chatId: chatId, threadId: threadId, text: text, completion: nil)
    }

    private func telegramSendShiftCloseReport(body: [String: Any]) {
        let token = body["botToken"] as? String ?? ""
        let chatId = body["chatId"] as? String ?? ""
        let threadId = body["threadId"] as? String ?? ""
        let report = body["report"] as? [String: Any] ?? [:]
        guard !token.isEmpty, !chatId.isEmpty, !report.isEmpty else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, let imageData = self.makeShiftReceiptImage(report: report) else {
                return
            }
            let closed = ((report["closedAt"] as? NSNumber)?.doubleValue ?? 0) / 1000
            let employee = report["employeeName"] as? String ?? "Сотрудник не указан"
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ru_RU")
            formatter.dateFormat = "dd.MM.yyyy HH:mm"
            let closeDate = formatter.string(from: Date(timeIntervalSince1970: closed > 0 ? closed : Date().timeIntervalSince1970))
            let safeEmployee = employee.replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            let caption = "🔴 <b>Смена закрыта</b>\n👤 Сотрудник: \(safeEmployee)\n🕐 Время: \(closeDate)"
            self.telegramPhotoRequest(token: token, chatId: chatId, threadId: threadId, imageData: imageData, caption: caption) { [weak self] ok, message in
                guard let self = self else { return }
                let payload: [String: Any] = ["ok": ok, "message": message]
                guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
                      let json = String(data: data, encoding: .utf8) else { return }
                let js = "window.onTelegramShiftClosedResult && window.onTelegramShiftClosedResult(\(json));"
                DispatchQueue.main.async {
                    self.webView.evaluateJavaScript(js, completionHandler: nil)
                }
            }
        }
    }

    private func makeShiftReceiptImage(report: [String: Any]) -> Data? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "dd.MM.yyyy HH:mm"

        let opened = ((report["openedAt"] as? NSNumber)?.doubleValue ?? 0) / 1000
        let closed = ((report["closedAt"] as? NSNumber)?.doubleValue ?? 0) / 1000
        let establishmentName = report["establishmentName"] as? String ?? ""
        let employee = report["employeeName"] as? String ?? "Сотрудник не указан"
        let currency = report["currency"] as? String ?? "Br"
        let orders = report["orders"] as? [[String: Any]] ?? []
        let movements = report["cashMovements"] as? [[String: Any]] ?? []

        let money: (Double) -> String = { value in String(format: "%.2f %@", value, currency) }
        let cash = (report["cash"] as? NSNumber)?.doubleValue ?? 0
        let card = (report["card"] as? NSNumber)?.doubleValue ?? 0
        let total = (report["total"] as? NSNumber)?.doubleValue ?? 0
        let openingCash = (report["openingCash"] as? NSNumber)?.doubleValue ?? 0
        let expected = (report["expectedCash"] as? NSNumber)?.doubleValue ?? 0
        let counted = (report["countedCash"] as? NSNumber)?.doubleValue ?? 0
        let difference = (report["difference"] as? NSNumber)?.doubleValue ?? 0
        let deposits = (report["deposits"] as? NSNumber)?.doubleValue ?? 0
        let withdrawals = (report["withdrawals"] as? NSNumber)?.doubleValue ?? 0

        let width: CGFloat = 720
        let side: CGFloat = 42
        let contentWidth = width - side * 2
        let headerHeight: CGFloat = 150
        let summaryRows = 10
        let movementHeight = movements.isEmpty ? 0 : 62 + CGFloat(movements.count) * 46
        let height = max(980, headerHeight + 30 + CGFloat(summaryRows) * 48 + movementHeight + 250)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))

        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            UIColor.white.setFill()
            cg.fill(CGRect(x: 0, y: 0, width: width, height: height))

            let ink = UIColor.black
            let gray = UIColor(white: 0.25, alpha: 1)
            let mono = UIFont.monospacedSystemFont(ofSize: 19, weight: .regular)
            let monoBold = UIFont.monospacedSystemFont(ofSize: 21, weight: .bold)
            let small = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
            let smallBold = UIFont.monospacedSystemFont(ofSize: 17, weight: .bold)

            func draw(_ text: String, x: CGFloat, y: CGFloat, font: UIFont = mono, color: UIColor = ink) {
                (text as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: [.font: font, .foregroundColor: color])
            }
            func drawCentered(_ text: String, y: CGFloat, font: UIFont, color: UIColor = ink) {
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let size = (text as NSString).size(withAttributes: attrs)
                (text as NSString).draw(at: CGPoint(x: (width - size.width) / 2, y: y), withAttributes: attrs)
            }
            func drawRight(_ text: String, y: CGFloat, font: UIFont = mono, color: UIColor = ink) {
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let size = (text as NSString).size(withAttributes: attrs)
                (text as NSString).draw(at: CGPoint(x: width - side - size.width, y: y), withAttributes: attrs)
            }
            func separator(_ y: CGFloat) {
                draw(String(repeating: "-", count: 66), x: side, y: y, font: small, color: gray)
            }
            func row(_ label: String, _ value: String, y: CGFloat, bold: Bool = false) {
                let f = bold ? smallBold : small
                draw(label, x: side, y: y, font: f)
                drawRight(value, y: y, font: f)
            }

            let establishmentTitle = establishmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "ПРИЛАВОК" : establishmentName
            drawCentered(establishmentTitle, y: 30, font: UIFont.monospacedSystemFont(ofSize: 28, weight: .bold))
            drawCentered("ОТЧЁТ О КАССОВОЙ СМЕНЕ", y: 72, font: UIFont.monospacedSystemFont(ofSize: 18, weight: .bold))
            drawCentered("СМЕНА ЗАКРЫТА", y: 102, font: smallBold)
            drawRight("№ \(report["id"] as? String ?? "")", y: 132, font: small)
            separator(160)

            var y: CGFloat = 188
            draw("СОТРУДНИК", x: side, y: y, font: smallBold)
            y += 28
            draw(employee, x: side, y: y, font: monoBold)
            y += 30
            row("Открытие смены", formatter.string(from: Date(timeIntervalSince1970: opened)), y: y)
            y += 24
            row("Закрытие смены", closed > 0 ? formatter.string(from: Date(timeIntervalSince1970: closed)) : "—", y: y)
            y += 30
            separator(y)
            y += 28

            drawCentered("ПРОДАЖИ", y: y, font: smallBold)
            y += 34
            row("Количество чеков", "\(orders.count)", y: y)
            y += 28
            row("Выручка", money(total), y: y, bold: true)
            y += 28
            row("Наличные", money(cash), y: y)
            y += 28
            row("Карта", money(card), y: y)
            y += 28
            row("Наличные на начало смены", money(openingCash), y: y)
            y += 28
            row("Внесено наличных", money(deposits), y: y)
            y += 28
            row("Изъято наличных", money(withdrawals), y: y)
            y += 34
            separator(y)
            y += 28

            drawCentered("ИТОГ", y: y, font: smallBold)
            y += 34
            row("Ожидается в кассе", money(expected), y: y)
            y += 28
            row("Фактически в кассе", money(counted), y: y, bold: true)
            y += 28
            row("Расхождение", money(difference), y: y, bold: abs(difference) > 0.009)
            y += 36

            if !movements.isEmpty {
                separator(y)
                y += 28
                drawCentered("ДВИЖЕНИЕ НАЛИЧНЫХ", y: y, font: smallBold)
                y += 34
                for movement in movements {
                    let ts = ((movement["timestamp"] as? NSNumber)?.doubleValue ?? 0) / 1000
                    let type = (movement["type"] as? String) == "deposit" ? "Внесение" : "Изъятие"
                    let amount = (movement["amount"] as? NSNumber)?.doubleValue ?? 0
                    let note = movement["note"] as? String ?? ""
                    let label = formatter.string(from: Date(timeIntervalSince1970: ts)) + " · " + type + (note.isEmpty ? "" : " · " + note)
                    draw(label, x: side, y: y, font: small)
                    drawRight(((type == "Внесение") ? "+" : "−") + money(amount), y: y, font: small)
                    y += 46
                }
            }

            separator(y)
            y += 34
            drawCentered("СПАСИБО ЗА РАБОТУ", y: y, font: smallBold)
            y += 34
            drawCentered(formatter.string(from: Date(timeIntervalSince1970: closed > 0 ? closed : Date().timeIntervalSince1970)), y: y, font: small)
        }

        return image.pngData()
    }

    private func telegramPhotoRequest(token: String, chatId: String, threadId: String, imageData: Data, caption: String? = nil, completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: "https://api.telegram.org/bot\(token)/sendPhoto") else {
            completion(false, "Некорректный Telegram Bot Token.")
            return
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        func append(_ string: String) {
            body.append(string.data(using: .utf8)!)
        }
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"chat_id\"\r\n\r\n")
        append("\(chatId)\r\n")
        if let thread = Int(threadId), thread > 0 {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"message_thread_id\"\r\n\r\n")
            append("\(thread)\r\n")
        }
        if let caption = caption, !caption.isEmpty {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"caption\"\r\n\r\n")
            append("\(caption)\r\n")
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"parse_mode\"\r\n\r\n")
            append("HTML\r\n")
        }
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"photo\"; filename=\"shift-report.png\"\r\n")
        append("Content-Type: image/png\r\n\r\n")
        body.append(imageData)
        append("\r\n--\(boundary)--\r\n")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                DispatchQueue.main.async { completion(false, "Ошибка сети: \(error.localizedDescription)") }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion(false, "Telegram не вернул ответ.") }
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let ok = json?["ok"] as? Bool ?? false
                let description = json?["description"] as? String
                DispatchQueue.main.async {
                    completion(ok, ok ? "Отчёт о закрытии смены отправлен в Telegram одним сообщением." : "Telegram: \(description ?? "Неизвестная ошибка Telegram")")
                }
            } catch {
                DispatchQueue.main.async { completion(false, "Не удалось прочитать ответ Telegram.") }
            }
        }.resume()
    }

    private func telegramRequest(token: String, chatId: String, threadId: String, text: String, completion: ((Bool, String) -> Void)?) {
        guard let url = URL(string: "https://api.telegram.org/bot\(token)/sendMessage") else {
            completion?(false, "Некорректный Telegram Bot Token.")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var payload: [String: Any] = ["chat_id": chatId, "text": text, "parse_mode": "HTML"]
        if let thread = Int(threadId), thread > 0 { payload["message_thread_id"] = thread }
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            completion?(false, "Не удалось подготовить запрос Telegram.")
            return
        }
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            let finish: (Bool, String) -> Void = { ok, message in
                DispatchQueue.main.async { completion?(ok, message) }
            }
            if let error = error {
                finish(false, "Ошибка сети: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                finish(false, "Telegram не вернул ответ.")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let ok = json?["ok"] as? Bool ?? false
                if ok {
                    finish(true, "Telegram подключён. Тестовое сообщение отправлено.")
                } else {
                    let description = ((json?["description"] as? String) ?? "Неизвестная ошибка Telegram")
                    finish(false, "Telegram: \(description)")
                }
            } catch {
                finish(false, "Не удалось прочитать ответ Telegram.")
            }
            _ = self
        }
        task.resume()
        DispatchQueue.global().asyncAfter(deadline: .now() + 15) {
            if task.state == .running {
                task.cancel()
                DispatchQueue.main.async { completion?(false, "Превышено время ожидания ответа Telegram (15 сек). Проверите интернет и данные бота.") }
            }
        }
    }

    private func sendTelegramResult(ok: Bool, message: String) {
        let payload: [String: Any] = ["ok": ok, "message": message]
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let json = String(data: data, encoding: .utf8) else { return }
        let js = "window.onTelegramResult && window.onTelegramResult(\(json));"
        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    private func sharePurchaseOrder(order: [String: Any]) {
        let supplier = order["supplierName"] as? String ?? "Поставщик"
        let timestamp = (order["timestamp"] as? NSNumber)?.doubleValue ?? Date().timeIntervalSince1970 * 1000
        let date = Date(timeIntervalSince1970: timestamp / 1000)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "dd.MM.yyyy HH:mm"

        let company = order["company"] as? [String: Any] ?? [:]
        let legalName = company["legalName"] as? String ?? ""
        let address = company["address"] as? String ?? ""
        let deliveryAddress = company["deliveryAddress"] as? String ?? ""

        var items: [(String, Int)] = []
        if let rawItems = order["items"] as? [[String: Any]] {
            for item in rawItems {
                let name = item["productName"] as? String ?? "Товар"
                let qty = (item["qty"] as? NSNumber)?.intValue ?? 0
                items.append((name, qty))
            }
        }

        let fileName = "Заказ-\(safeFileName(supplier))-\(formatter.string(from: date).replacingOccurrences(of: ":", with: "-" )).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try createPurchaseOrderPDF(
                supplier: supplier,
                date: date,
                legalName: legalName,
                address: address,
                deliveryAddress: deliveryAddress,
                items: items,
                to: url
            )
            let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let popover = activity.popoverPresentationController {
                popover.sourceView = webView
                popover.sourceRect = CGRect(x: webView.bounds.midX, y: webView.bounds.midY, width: 1, height: 1)
                popover.permittedArrowDirections = []
            }
            present(activity, animated: true)
        } catch {
            let alert = UIAlertController(title: "Не удалось подготовить PDF", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    private func printShiftReport(report: [String: Any]) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        let opened = ((report["openedAt"] as? NSNumber)?.doubleValue ?? 0) / 1000
        let closed = ((report["closedAt"] as? NSNumber)?.doubleValue ?? 0) / 1000
        let establishmentName = report["establishmentName"] as? String ?? ""
        let employee = report["employeeName"] as? String ?? "Сотрудник не указан"
        let phone = report["employeePhone"] as? String ?? ""
        let currency = report["currency"] as? String ?? "Br"
        let money: (Double) -> String = { value in String(format: "%.2f %@", value, currency) }
        let orders = report["orders"] as? [[String: Any]] ?? []

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat = 36
        let contentWidth = pageRect.width - margin * 2
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Смена-\(formatter.string(from: Date(timeIntervalSince1970: opened)).replacingOccurrences(of: ":", with: "-")).pdf")

        let titleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        let headFont = UIFont.systemFont(ofSize: 12, weight: .bold)
        let bodyFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let smallFont = UIFont.systemFont(ofSize: 9, weight: .regular)
        let ink = UIColor(red: 0.07, green: 0.09, blue: 0.13, alpha: 1)
        let muted = UIColor(red: 0.38, green: 0.42, blue: 0.48, alpha: 1)
        let light = UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1)
        let white = UIColor.white

        func drawText(_ text: String, at point: CGPoint, font: UIFont, color: UIColor = ink) {
            (text as NSString).draw(at: point, withAttributes: [.font: font, .foregroundColor: color])
        }
        func drawRight(_ text: String, y: CGFloat, font: UIFont, color: UIColor = ink) {
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
            let size = (text as NSString).size(withAttributes: attrs)
            (text as NSString).draw(at: CGPoint(x: pageRect.width - margin - size.width, y: y), withAttributes: attrs)
        }
        func rounded(_ rect: CGRect, fill: UIColor, radius: CGFloat = 14) {
            fill.setFill(); UIBezierPath(roundedRect: rect, cornerRadius: radius).fill()
        }

        try? renderer.writePDF(to: url) { ctx in
            var y: CGFloat = margin
            var page = 1
            func header(continuation: Bool = false) {
                rounded(CGRect(x: margin, y: margin, width: contentWidth, height: continuation ? 56 : 92), fill: ink, radius: 18)
                let establishmentTitle = establishmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "ПРИЛАВОК" : establishmentName
                drawText(establishmentTitle, at: CGPoint(x: margin + 20, y: margin + 17), font: UIFont.systemFont(ofSize: continuation ? 15 : 17, weight: .bold), color: white)
                drawText(continuation ? "ОТЧЁТ ПО СМЕНЕ · ПРОДОЛЖЕНИЕ" : "ОТЧЁТ ПО КАССОВОЙ СМЕНЕ", at: CGPoint(x: margin + 20, y: margin + (continuation ? 36 : 48)), font: UIFont.systemFont(ofSize: 9, weight: .medium), color: UIColor(white: 0.82, alpha: 1))
                if !continuation {
                    drawRight("№ \(report["id"] as? String ?? "")", y: margin + 22, font: smallFont, color: UIColor(white: 0.82, alpha: 1))
                    drawRight(formatter.string(from: Date(timeIntervalSince1970: opened)), y: margin + 38, font: smallFont, color: UIColor(white: 0.82, alpha: 1))
                }
                y = margin + (continuation ? 72 : 110)
            }
            func newPage() {
                ctx.beginPage(); page += 1; header(continuation: true)
            }
            header()

            rounded(CGRect(x: margin, y: y, width: contentWidth, height: 86), fill: light)
            drawText("СОТРУДНИК", at: CGPoint(x: margin + 16, y: y + 14), font: smallFont, color: muted)
            drawText(employee, at: CGPoint(x: margin + 16, y: y + 31), font: headFont)
            if !phone.isEmpty { drawText(phone, at: CGPoint(x: margin + 16, y: y + 49), font: smallFont, color: muted) }
            drawRight("Открытие: \(formatter.string(from: Date(timeIntervalSince1970: opened)))", y: y + 14, font: smallFont, color: muted)
            drawRight("Закрытие: \(closed > 0 ? formatter.string(from: Date(timeIntervalSince1970: closed)) : "—")", y: y + 32, font: smallFont, color: muted)
            y += 102

            let cash = (report["cash"] as? NSNumber)?.doubleValue ?? 0
            let card = (report["card"] as? NSNumber)?.doubleValue ?? 0
            let total = (report["total"] as? NSNumber)?.doubleValue ?? 0
            let openingCash = (report["openingCash"] as? NSNumber)?.doubleValue ?? 0
            let expected = (report["expectedCash"] as? NSNumber)?.doubleValue ?? 0
            let counted = (report["countedCash"] as? NSNumber)?.doubleValue ?? 0
            let difference = (report["difference"] as? NSNumber)?.doubleValue ?? 0
            let deposits = (report["deposits"] as? NSNumber)?.doubleValue ?? 0
            let withdrawals = (report["withdrawals"] as? NSNumber)?.doubleValue ?? 0
            let stats = [("ЗАКАЗОВ", "\(orders.count)"), ("ВЫРУЧКА", money(total)), ("НАЛИЧНЫЕ", money(cash)), ("КАРТА", money(card)), ("НАЛИЧНЫЕ НА НАЧАЛО СМЕНЫ", money(openingCash)), ("ВНЕСЕНО", money(deposits)), ("ИЗЪЯТО", money(withdrawals)), ("ОЖИДАЕТСЯ", money(expected)), ("ФАКТ", money(counted)), ("РАСХОЖДЕНИЕ", money(difference))]
            let boxW = (contentWidth - 18) / 2
            for (i, stat) in stats.enumerated() {
                let col = i % 2, row = i / 2
                let rect = CGRect(x: margin + CGFloat(col) * (boxW + 18), y: y + CGFloat(row) * 58, width: boxW, height: 48)
                rounded(rect, fill: UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1), radius: 10)
                drawText(stat.0, at: CGPoint(x: rect.minX + 10, y: rect.minY + 8), font: UIFont.systemFont(ofSize: 7.5, weight: .medium), color: muted)
                drawText(stat.1, at: CGPoint(x: rect.minX + 10, y: rect.minY + 23), font: UIFont.systemFont(ofSize: 11, weight: .bold))
            }
            y += 5 * 58 + 18
            let movements = report["cashMovements"] as? [[String: Any]] ?? []
            if !movements.isEmpty {
                drawText("ДВИЖЕНИЕ НАЛИЧНЫХ", at: CGPoint(x: margin, y: y), font: headFont)
                y += 24
                rounded(CGRect(x: margin, y: y, width: contentWidth, height: 26), fill: ink, radius: 8)
                drawText("ВРЕМЯ / ОПЕРАЦИЯ", at: CGPoint(x: margin + 10, y: y + 7), font: smallFont, color: white)
                drawRight("СУММА", y: y + 7, font: smallFont, color: white)
                y += 34
                for movement in movements {
                    if y > pageRect.height - 70 { drawRight("Стр. \(page)", y: pageRect.height - 28, font: smallFont, color: muted); newPage() }
                    let ts = ((movement["timestamp"] as? NSNumber)?.doubleValue ?? 0) / 1000
                    let type = (movement["type"] as? String) == "deposit" ? "Внесение наличных" : "Изъятие наличных"
                    let amount = (movement["amount"] as? NSNumber)?.doubleValue ?? 0
                    let note = movement["note"] as? String ?? ""
                    let sign = type.hasPrefix("Внесение") ? "+" : "−"
                    let label = formatter.string(from: Date(timeIntervalSince1970: ts)) + " · " + type + (note.isEmpty ? "" : " · " + note)
                    rounded(CGRect(x: margin, y: y, width: contentWidth, height: 28), fill: white, radius: 5)
                    drawText(label, at: CGPoint(x: margin + 10, y: y + 7), font: smallFont)
                    drawRight(sign + money(amount), y: y + 7, font: smallFont)
                    y += 30
                }
                y += 10
            }
            drawRight("Стр. \(page)", y: pageRect.height - 28, font: smallFont, color: muted)
        }

        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = "Отчёт по смене — \(employee)"
        let controller = UIPrintInteractionController.shared
        controller.printInfo = printInfo
        controller.printingItem = url
        controller.present(animated: true, completionHandler: nil)
    }

    private func safeFileName(_ value: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\:*?\"<>|\n")
        let cleaned = value.components(separatedBy: invalid).joined(separator: "-").trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "поставщик" : cleaned
    }

    private func createPurchaseOrderPDF(
        supplier: String,
        date: Date,
        legalName: String,
        address: String,
        deliveryAddress: String,
        items: [(String, Int)],
        to url: URL
    ) throws {
        // Fixed document colors — do NOT use UIColor.label/secondaryLabel here.
        // They are dynamic and become white in Dark Mode, which made the previous PDF unreadable.
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat = 36
        let contentWidth = pageRect.width - margin * 2
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let ink = UIColor(red: 0.07, green: 0.09, blue: 0.13, alpha: 1)
        let muted = UIColor(red: 0.38, green: 0.42, blue: 0.48, alpha: 1)
        let dark = UIColor(red: 0.07, green: 0.10, blue: 0.16, alpha: 1)
        let accent = UIColor(red: 0.13, green: 0.40, blue: 0.95, alpha: 1)
        let paper = UIColor.white
        let soft = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1)
        let line = UIColor(red: 0.88, green: 0.90, blue: 0.93, alpha: 1)
        let rowAlt = UIColor(red: 0.985, green: 0.987, blue: 0.99, alpha: 1)

        let titleFont = UIFont.boldSystemFont(ofSize: 25)
        let sectionFont = UIFont.boldSystemFont(ofSize: 11)
        let bodyFont = UIFont.systemFont(ofSize: 11.5)
        let boldFont = UIFont.boldSystemFont(ofSize: 11.5)
        let smallFont = UIFont.systemFont(ofSize: 8.5)
        let smallBold = UIFont.boldSystemFont(ofSize: 8.5)

        let data = renderer.pdfData { context in
            var y: CGFloat = margin
            var pageNumber = 0

            func drawText(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat, font: UIFont, color: UIColor = ink, alignment: NSTextAlignment = .left) -> CGFloat {
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = alignment
                paragraph.lineBreakMode = .byWordWrapping
                paragraph.lineSpacing = 1.5
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraph
                ]
                let rect = NSString(string: text).boundingRect(
                    with: CGSize(width: width, height: 2000),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes,
                    context: nil
                )
                NSString(string: text).draw(
                    in: CGRect(x: x, y: y, width: width, height: rect.height + 2),
                    withAttributes: attributes
                )
                return ceil(rect.height)
            }

            func fillRounded(_ rect: CGRect, radius: CGFloat, color: UIColor) {
                let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
                color.setFill()
                path.fill()
            }

            func strokeRounded(_ rect: CGRect, radius: CGFloat, color: UIColor, width: CGFloat = 0.7) {
                let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
                color.setStroke()
                path.lineWidth = width
                path.stroke()
            }

            func drawRule(at y: CGFloat, x: CGFloat = margin, width: CGFloat = contentWidth) {
                line.setFill()
                UIBezierPath(rect: CGRect(x: x, y: y, width: width, height: 0.7)).fill()
            }

            func drawPageFooter() {
                drawRule(at: pageRect.height - 43)
                drawText("PRILAVOK POS", x: margin, y: pageRect.height - 32, width: 160, font: smallBold, color: muted)
                drawText("Заказ поставщику", x: pageRect.width - margin - 150, y: pageRect.height - 32, width: 150, font: smallFont, color: muted, alignment: .right)
                drawText("\(pageNumber)", x: pageRect.width - margin - 20, y: pageRect.height - 32, width: 20, font: smallBold, color: ink, alignment: .right)
            }

            func beginPage(isContinuation: Bool = false) {
                context.beginPage()
                pageNumber += 1
                y = margin
                if isContinuation {
                    fillRounded(CGRect(x: margin, y: y, width: contentWidth, height: 42), radius: 12, color: dark)
                    drawText("ПРИЛАВОК", x: margin + 14, y: y + 9, width: 100, font: smallBold, color: .white)
                    drawText("ЗАКАЗ ПОСТАВЩИКУ", x: margin + 14, y: y + 21, width: 250, font: UIFont.boldSystemFont(ofSize: 12), color: .white)
                    drawText("Продолжение", x: pageRect.width - margin - 110, y: y + 14, width: 96, font: smallFont, color: UIColor(white: 1, alpha: 0.75), alignment: .right)
                    y += 58
                }
            }

            beginPage()

            // MARK: Header
            let headerH: CGFloat = 118
            fillRounded(CGRect(x: margin, y: y, width: contentWidth, height: headerH), radius: 22, color: dark)
            drawText("ПРИЛАВОК", x: margin + 22, y: y + 17, width: 150, font: smallBold, color: UIColor(white: 1, alpha: 0.72))
            drawText("ЗАКАЗ ПОСТАВЩИКУ", x: margin + 22, y: y + 36, width: 335, font: titleFont, color: .white)
            drawText(formatterString(date), x: margin + 23, y: y + 78, width: 210, font: bodyFont, color: UIColor(white: 1, alpha: 0.78))

            fillRounded(CGRect(x: pageRect.width - margin - 118, y: y + 20, width: 100, height: 68), radius: 14, color: UIColor(white: 1, alpha: 0.10))
            drawText("ЗАКАЗ", x: pageRect.width - margin - 105, y: y + 31, width: 74, font: smallBold, color: UIColor(white: 1, alpha: 0.65), alignment: .center)
            drawText("#\(String(Int(date.timeIntervalSince1970)).suffix(6))", x: pageRect.width - margin - 105, y: y + 49, width: 74, font: UIFont.boldSystemFont(ofSize: 16), color: .white, alignment: .center)
            y += headerH + 18

            // MARK: Parties
            let gap: CGFloat = 12
            let half = (contentWidth - gap) / 2
            let cardH: CGFloat = 132
            let leftX = margin
            let rightX = margin + half + gap

            fillRounded(CGRect(x: leftX, y: y, width: half, height: cardH), radius: 18, color: soft)
            strokeRounded(CGRect(x: leftX, y: y, width: half, height: cardH), radius: 18, color: line)
            fillRounded(CGRect(x: rightX, y: y, width: half, height: cardH), radius: 18, color: soft)
            strokeRounded(CGRect(x: rightX, y: y, width: half, height: cardH), radius: 18, color: line)

            fillRounded(CGRect(x: leftX + 14, y: y + 14, width: 34, height: 24), radius: 8, color: dark)
            drawText("01", x: leftX + 14, y: y + 20, width: 34, font: smallBold, color: .white, alignment: .center)
            drawText("ЗАКАЗЧИК", x: leftX + 56, y: y + 20, width: half - 70, font: sectionFont, color: ink)

            fillRounded(CGRect(x: rightX + 14, y: y + 14, width: 34, height: 24), radius: 8, color: accent)
            drawText("02", x: rightX + 14, y: y + 20, width: 34, font: smallBold, color: .white, alignment: .center)
            drawText("ПОСТАВЩИК", x: rightX + 56, y: y + 20, width: half - 70, font: sectionFont, color: ink)

            var ly = y + 52
            if !legalName.isEmpty {
                drawText("Юридическое лицо", x: leftX + 16, y: ly, width: half - 32, font: smallFont, color: muted)
                ly += 14
                let h = drawText(legalName, x: leftX + 16, y: ly, width: half - 32, font: boldFont)
                ly += h + 8
            }
            if !deliveryAddress.isEmpty {
                drawText("Адрес доставки", x: leftX + 16, y: ly, width: half - 32, font: smallFont, color: muted)
                ly += 14
                drawText(deliveryAddress, x: leftX + 16, y: ly, width: half - 32, font: bodyFont)
            }
            if legalName.isEmpty && deliveryAddress.isEmpty {
                drawText("Данные не указаны", x: leftX + 16, y: ly, width: half - 32, font: bodyFont, color: muted)
            }

            var ry = y + 52
            if !supplier.isEmpty {
                drawText("Название поставщика", x: rightX + 16, y: ry, width: half - 32, font: smallFont, color: muted)
                ry += 14
                drawText(supplier, x: rightX + 16, y: ry, width: half - 32, font: boldFont)
            } else {
                drawText("Поставщик не указан", x: rightX + 16, y: ry, width: half - 32, font: bodyFont, color: muted)
            }
            y += cardH + 22

            // MARK: Items
            drawText("СОСТАВ ЗАКАЗА", x: margin, y: y, width: 220, font: sectionFont, color: ink)
            drawText("\(items.count) поз.  ·  \(items.reduce(0) { $0 + $1.1 }) шт.", x: pageRect.width - margin - 180, y: y, width: 180, font: smallBold, color: muted, alignment: .right)
            y += 16

            let tableHeaderH: CGFloat = 34
            let tableStartY = y
            let tableRadius: CGFloat = 18
            let tablePaddingBottom: CGFloat = 8
            fillRounded(CGRect(x: margin, y: tableStartY, width: contentWidth, height: 34), radius: tableRadius, color: dark)
            drawText("№", x: margin + 12, y: y + 10, width: 25, font: smallBold, color: UIColor(white: 1, alpha: 0.70))
            drawText("ТОВАР", x: margin + 42, y: y + 10, width: contentWidth - 120, font: smallBold, color: UIColor(white: 1, alpha: 0.70))
            drawText("КОЛ-ВО", x: pageRect.width - margin - 75, y: y + 10, width: 62, font: smallBold, color: UIColor(white: 1, alpha: 0.70), alignment: .right)
            y += tableHeaderH

            var tableBottomY = y
            for (index, item) in items.enumerated() {
                let name = item.0
                let qty = item.1
                let textHeight = NSString(string: name).boundingRect(
                    with: CGSize(width: contentWidth - 125, height: 1000),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [.font: bodyFont],
                    context: nil
                ).height
                let rowHeight = max(CGFloat(39), ceil(textHeight) + 18)

                if y + rowHeight > pageRect.height - 65 {
                    drawPageFooter()
                    beginPage(isContinuation: true)
                    fillRounded(CGRect(x: margin, y: y, width: contentWidth, height: tableHeaderH), radius: tableRadius, color: dark)
                    drawText("№", x: margin + 12, y: y + 10, width: 25, font: smallBold, color: UIColor(white: 1, alpha: 0.70))
                    drawText("ТОВАР", x: margin + 42, y: y + 10, width: contentWidth - 120, font: smallBold, color: UIColor(white: 1, alpha: 0.70))
                    drawText("КОЛ-ВО", x: pageRect.width - margin - 75, y: y + 10, width: 62, font: smallBold, color: UIColor(white: 1, alpha: 0.70), alignment: .right)
                    y += tableHeaderH
                    tableBottomY = y
                }

                if index % 2 == 0 {
                    fillRounded(CGRect(x: margin + 1, y: y, width: contentWidth - 2, height: rowHeight), radius: 0, color: rowAlt)
                }
                drawText("\(index + 1)", x: margin + 12, y: y + 11, width: 25, font: smallFont, color: muted)
                drawText(name, x: margin + 42, y: y + 10, width: contentWidth - 125, font: bodyFont, color: ink)
                drawText("\(qty) шт.", x: pageRect.width - margin - 88, y: y + 10, width: 76, font: boldFont, color: ink, alignment: .right)
                drawRule(at: y + rowHeight - 0.5, x: margin + 42, width: contentWidth - 42)
                y += rowHeight
                tableBottomY = y
            }

            // Draw a single rounded container around the complete order composition.
            let tableHeight = max(tableHeaderH + tablePaddingBottom, tableBottomY - tableStartY + tablePaddingBottom)
            strokeRounded(CGRect(x: margin, y: tableStartY, width: contentWidth, height: tableHeight), radius: tableRadius, color: line, width: 0.9)
            y = tableStartY + tableHeight

            // MARK: Summary
            if y + 92 > pageRect.height - 65 {
                drawPageFooter()
                beginPage(isContinuation: true)
            } else {
                y += 18
            }

            fillRounded(CGRect(x: margin, y: y, width: contentWidth, height: 72), radius: 18, color: soft)
            strokeRounded(CGRect(x: margin, y: y, width: contentWidth, height: 72), radius: 18, color: line)
            drawText("ИТОГО ПО ЗАКАЗУ", x: margin + 18, y: y + 14, width: 180, font: smallBold, color: muted)
            drawText("\(items.count)", x: margin + 18, y: y + 32, width: 100, font: UIFont.boldSystemFont(ofSize: 20), color: ink)
            drawText("позиций", x: margin + 18, y: y + 55, width: 100, font: smallFont, color: muted)
            drawText("\(items.reduce(0) { $0 + $1.1 }) шт.", x: pageRect.width - margin - 180, y: y + 25, width: 160, font: UIFont.boldSystemFont(ofSize: 20), color: dark, alignment: .right)
            y += 92

            fillRounded(CGRect(x: margin, y: y, width: contentWidth, height: 58), radius: 16, color: dark)
            drawText("ПРОСЬБА ПОДТВЕРДИТЬ НАЛИЧИЕ И СРОКИ ПОСТАВКИ", x: margin + 16, y: y + 13, width: contentWidth - 32, font: smallBold, color: .white)
            drawText("Документ сформирован автоматически", x: margin + 16, y: y + 32, width: contentWidth - 32, font: smallFont, color: UIColor(white: 1, alpha: 0.70))

            drawPageFooter()
        }
        try data.write(to: url, options: .atomic)
    }

    private func formatterString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }

    private func sendPrinterEvent(_ event: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: event),
              let json = String(data: data, encoding: .utf8) else { return }
        let js = "window.__nativePrinterEvent && window.__nativePrinterEvent(\(json));"
        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript(js)
        }
    }

    deinit {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "printer")
    }
}
