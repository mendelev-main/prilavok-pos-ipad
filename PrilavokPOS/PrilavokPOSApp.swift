import UIKit
import WebKit
import UniformTypeIdentifiers
import PhotosUI
import Foundation

final class ProductImageStore: NSObject, WKURLSchemeHandler {
    private let directory: URL
    override init() {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        directory = root.appendingPathComponent("MPosProductImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    func save(_ data: Data) -> String? { let id=UUID().uuidString.lowercased();do{try data.write(to:url(id),options:.atomic);return id}catch{return nil} }
    func read(_ id:String)->Data? { guard valid(id) else{return nil};return try? Data(contentsOf:url(id)) }
    func remove(_ id:String){guard valid(id) else{return};try? FileManager.default.removeItem(at:url(id))}
    private func valid(_ id:String)->Bool { UUID(uuidString:id) != nil }
    private func url(_ id:String)->URL { directory.appendingPathComponent(id).appendingPathExtension("jpg") }
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) { guard let id=urlSchemeTask.request.url?.host,let data=read(id) else{urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist));return};urlSchemeTask.didReceive(URLResponse(url:urlSchemeTask.request.url!,mimeType:"image/jpeg",expectedContentLength:data.count,textEncodingName:nil));urlSchemeTask.didReceive(data);urlSchemeTask.didFinish() }
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}

final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?
    init(_ delegate: WKScriptMessageHandler) { self.delegate=delegate }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) { delegate?.userContentController(userContentController,didReceive:message) }
}

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
    private let networkPrinter = NetworkPrinterManager()
    private let productImages = ProductImageStore()

    override func loadView() {
        let contentController = WKUserContentController()
        contentController.add(WeakScriptMessageHandler(self), name: "printer")
        contentController.add(WeakScriptMessageHandler(self), name: "telegram")
        contentController.add(WeakScriptMessageHandler(self), name: "photoPicker")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        configuration.websiteDataStore = .default()
        configuration.setURLSchemeHandler(productImages, forURLScheme: "mpos-image")

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
        NotificationCenter.default.addObserver(self, selector: #selector(pauseAvailability), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resumeAvailability), name: UIApplication.didBecomeActiveNotification, object: nil)
        networkPrinter.onEvent = { [weak self] event in
            self?.sendPrinterEvent(event)
        }

        guard let url = Bundle.main.url(forResource: "pos", withExtension: "html") else {
            let message = "Файл pos.html не найден в приложении."
            webView.loadHTMLString("<html><body style='font-family:-apple-system;text-align:center;padding:40px'><h2>Ошибка</h2><p>\(message)</p></body></html>", baseURL: nil)
            return
        }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }

    @objc private func pauseAvailability() {
        webView.evaluateJavaScript("window._availabilityAppActive=false;window.onAvailabilityAppState&&window.onAvailabilityAppState(false);", completionHandler: nil)
    }

    @objc private func resumeAvailability() {
        webView.evaluateJavaScript("window._availabilityAppActive=true;window.onAvailabilityAppState&&window.onAvailabilityAppState(true);", completionHandler: nil)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "photoPicker" {
            if let body=message.body as? [String:Any],let action=body["action"] as? String,action != "pick" {
                let id=body["id"] as? String ?? ""
                if action=="remove" { productImages.remove(id) }
                if action=="read",let requestId=body["requestId"] as? String,let data=productImages.read(id) { sendProductImageRead(requestId:requestId,data:data) }
                return
            }
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
        case "sendMonthlyWarehouseReport":
            telegramSendMonthlyWarehouseReport(body: body)
        case "print":
            if let order = body["order"] as? [String: Any] { networkPrinter.print(order: order) }
        case "status":
            sendPrinterEvent(["type":"status", "status":"network_ready", "message":"Сетевая печать готова"])
        case "shareWarehouseExcel":
            if let report = body["report"] as? [String: Any] { shareWarehouseExcel(report: report) }
        case "shareWarehouseReport":
            if let report = body["report"] as? [String: Any] {
                shareWarehouseReport(report: report)
            }
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
            guard let prepared = self.prepareProductImage(image),let localId=self.productImages.save(prepared) else { return }
            let base64 = prepared.base64EncodedString()
            let js = "window.handleNativeProductImage && window.handleNativeProductImage('data:image/jpeg;base64,\(base64)','\(localId)');"
            DispatchQueue.main.async {
                self.webView.evaluateJavaScript(js, completionHandler: nil)
            }
        }
    }

    private func sendProductImageRead(requestId:String,data:Data){
        let base64=data.base64EncodedString(),js="window.handleNativeProductImageRead && window.handleNativeProductImageRead('\(requestId)','data:image/jpeg;base64,\(base64)');"
        DispatchQueue.main.async { [weak self] in self?.webView.evaluateJavaScript(js) }
    }

    private func prepareProductImage(_ image: UIImage) -> Data? {
        // Limit actual pixels and encoded bytes, including headroom for Base64/JSON.
        var maxDimension: CGFloat = 1200
        let longest = max(image.size.width, image.size.height)
        guard longest > 0 else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        for _ in 0..<8 {
            let scale = min(1, maxDimension / longest)
            let size = CGSize(width: max(1, floor(image.size.width * scale)), height: max(1, floor(image.size.height * scale)))
            let prepared = UIGraphicsImageRenderer(size: size, format: format).image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: size))
                image.draw(in: CGRect(origin: .zero, size: size))
            }
            for quality in [0.82, 0.7, 0.55] {
                if let data = prepared.jpegData(compressionQuality: CGFloat(quality)), data.count <= 600_000 {
                    return data
                }
            }
            maxDimension *= 0.75
        }
        return nil
    }

    private func telegramTest(body: [String: Any]) {
        let token = body["botToken"] as? String ?? ""
        let chatId = body["chatId"] as? String ?? ""
        let threadId = body["threadId"] as? String ?? ""
        guard !token.isEmpty, !chatId.isEmpty else {
            sendTelegramResult(ok: false, message: "Укажите токен бота и ID рабочей группы.")
            return
        }
        let text = "🟢 <b>Telegram подключён</b>\nM POS успешно связался с рабочей группой."
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

    private func telegramSendMonthlyWarehouseReport(body: [String: Any]) {
        let token = body["botToken"] as? String ?? ""
        let chatId = body["chatId"] as? String ?? ""
        let threadId = body["threadId"] as? String ?? ""
        let periodKey = body["periodKey"] as? String ?? ""
        let report = body["report"] as? [String: Any] ?? [:]
        guard !token.isEmpty, !chatId.isEmpty, !periodKey.isEmpty, !report.isEmpty else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let pdf = WarehouseReportPDF.makeWarehouseReportPDF(report: report)
            self.telegramDocumentRequest(token: token, chatId: chatId, threadId: threadId, data: pdf, filename: "Склад-\(periodKey).pdf", caption: "📊 <b>Ежемесячный складской отчёт</b>\nПериод: \(report["period"] as? String ?? periodKey)") { [weak self] ok, message in
                guard let self = self else { return }
                let payload: [String: Any] = ["ok": ok, "message": message, "periodKey": periodKey]
                guard let data = try? JSONSerialization.data(withJSONObject: payload),
                      let json = String(data: data, encoding: .utf8) else { return }
                DispatchQueue.main.async {
                    self.webView.evaluateJavaScript("window.onTelegramMonthlyWarehouseResult && window.onTelegramMonthlyWarehouseResult(\(json));", completionHandler: nil)
                }
            }
        }
    }

    private func telegramDocumentRequest(token: String, chatId: String, threadId: String, data: Data, filename: String, caption: String?, completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: "https://api.telegram.org/bot\(token)/sendDocument") else { completion(false, "Некорректный Telegram Bot Token."); return }
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        func append(_ value: String) { body.append(value.data(using: .utf8)!) }
        append("--\(boundary)\r\nContent-Disposition: form-data; name=\"chat_id\"\r\n\r\n\(chatId)\r\n")
        if let thread = Int(threadId), thread > 0 { append("--\(boundary)\r\nContent-Disposition: form-data; name=\"message_thread_id\"\r\n\r\n\(thread)\r\n") }
        if let caption = caption, !caption.isEmpty {
            append("--\(boundary)\r\nContent-Disposition: form-data; name=\"caption\"\r\n\r\n\(caption)\r\n")
            append("--\(boundary)\r\nContent-Disposition: form-data; name=\"parse_mode\"\r\n\r\nHTML\r\n")
        }
        append("--\(boundary)\r\nContent-Disposition: form-data; name=\"document\"; filename=\"\(filename)\"\r\nContent-Type: application/pdf\r\n\r\n")
        body.append(data); append("\r\n--\(boundary)--\r\n")
        var request = URLRequest(url: url); request.httpMethod = "POST"; request.timeoutInterval = 30
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type"); request.httpBody = body
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { DispatchQueue.main.async { completion(false, "Ошибка сети: \(error.localizedDescription)") }; return }
            guard let data = data else { DispatchQueue.main.async { completion(false, "Telegram не вернул ответ.") }; return }
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let ok = json?["ok"] as? Bool ?? false
            let description = json?["description"] as? String
            DispatchQueue.main.async { completion(ok, ok ? "Ежемесячный складской отчёт отправлен в Telegram." : "Telegram: \(description ?? "Неизвестная ошибка Telegram")") }
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

    // Local inventory report; shared only after the user chooses a destination.
    private func shareWarehouseReport(report: [String: Any]) {
        let data = WarehouseReportPDF.makeWarehouseReportPDF(report: report)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Склад-\(UUID().uuidString).pdf")
        do {
            try data.write(to: url, options: .atomic)
            let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let popover = activity.popoverPresentationController {
                popover.sourceView = webView
                popover.sourceRect = CGRect(x: webView.bounds.midX, y: webView.bounds.midY, width: 1, height: 1)
                popover.permittedArrowDirections = []
            }
            present(activity, animated: true)
        } catch {
            let alert = UIAlertController(title: "Не удалось создать PDF", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default)); present(alert, animated: true)
        }
    }

    private func shareWarehouseExcel(report: [String: Any]) {
        let data = WarehouseWorkbook.data(report)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Склад-\(UUID().uuidString).xlsx")
        do {
            try data.write(to: url, options: .atomic)
            let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let popover = activity.popoverPresentationController {
                popover.sourceView = webView
                popover.sourceRect = CGRect(x: webView.bounds.midX, y: webView.bounds.midY, width: 1, height: 1)
                popover.permittedArrowDirections = []
            }
            present(activity, animated: true)
        } catch {
            let alert = UIAlertController(title: "Не удалось создать Excel", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default)); present(alert, animated: true)
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

        var items: [(String, String)] = []
        if let rawItems = order["items"] as? [[String: Any]] {
            for item in rawItems {
                let name = item["productName"] as? String ?? "Товар"
                let qty = item["quantityText"] as? String ?? "\((item["qty"] as? NSNumber)?.stringValue ?? "0") шт."
                items.append((name, qty))
            }
        }

        let fileName = "Заказ-\(safeFileName(supplier))-\(formatter.string(from: date).replacingOccurrences(of: ":", with: "-" )).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try PurchaseOrderPDF.createPurchaseOrderPDF(
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
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "telegram")
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "photoPicker")
    }
}
