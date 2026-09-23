import UIKit
import WebKit
import UniformTypeIdentifiers
import PhotosUI
import Foundation

// Local, dependency-free OOXML export. ZIP uses stored entries (no compression).
enum WarehouseWorkbook {
    static func xml(_ value: String) -> String {
        let clean = String(String.UnicodeScalarView(value.unicodeScalars.filter { $0.value == 9 || $0.value == 10 || $0.value == 13 || ($0.value >= 32 && $0.value != 0xFFFE && $0.value != 0xFFFF) }))
        return clean.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
    }
    static func archive(_ files: [(String, String)]) -> Data {
        var output = Data(), directory = Data()
        func word(_ value: UInt32, _ bytes: Int, _ data: inout Data) {
            for shift in 0..<bytes { data.append(UInt8(truncatingIfNeeded: value >> (shift * 8))) }
        }
        for (name, text) in files {
            let filename = Data(name.utf8), content = Data(text.utf8), offset = UInt32(output.count)
            var crc: UInt32 = 0xFFFFFFFF
            for byte in content { crc ^= UInt32(byte); for _ in 0..<8 { crc = (crc >> 1) ^ ((crc & 1) != 0 ? 0xEDB88320 : 0) } }
            crc ^= 0xFFFFFFFF
            word(0x04034B50,4,&output)
            for value: UInt32 in [20,0,0,0,33] { word(value,2,&output) }
            for value in [crc,UInt32(content.count),UInt32(content.count)] { word(value,4,&output) }
            word(UInt32(filename.count),2,&output);word(0,2,&output);output.append(filename);output.append(content)
            word(0x02014B50,4,&directory)
            for value: UInt32 in [20,20,0,0,0,33] { word(value,2,&directory) }
            for value in [crc,UInt32(content.count),UInt32(content.count)] { word(value,4,&directory) }
            for value in [UInt32(filename.count),0,0,0,0] { word(value,2,&directory) }
            word(0,4,&directory);word(offset,4,&directory);directory.append(filename)
        }
        let offset = UInt32(output.count);output.append(directory)
        word(0x06054B50,4,&output);word(0,2,&output);word(0,2,&output)
        word(UInt32(files.count),2,&output);word(UInt32(files.count),2,&output)
        word(UInt32(directory.count),4,&output);word(offset,4,&output);word(0,2,&output)
        return output
    }
    static func data(_ report: [String: Any]) -> Data {
        let ns = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
        let rel = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
        let package = "http://schemas.openxmlformats.org/package/2006/relationships"
        let company = (report["company"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let heading = company.isEmpty ? "Название заведения не указано" : company
        var sections = report["sections"] as? [[String: Any]] ?? []
        sections.append(["title":"Пояснения", "headers":["Как читать отчёт"], "excelRows":(report["notes"] as? [String] ?? []).map { [$0] }])
        var files: [(String,String)] = [], sheets = "", links = "", overrides = ""
        func col(_ index: Int) -> String { var n=index+1,result="";while n>0 {n-=1;result=String(UnicodeScalar(65+n%26)!)+result;n/=26};return result }
        for (index, section) in sections.enumerated() {
            let id=index+1, name=String((section["title"] as? String ?? "Раздел \(id)").prefix(31))
            sheets += "<sheet name=\"\(xml(name))\" sheetId=\"\(id)\" r:id=\"rId\(id)\"/>"
            links += "<Relationship Id=\"rId\(id)\" Type=\"\(rel)/worksheet\" Target=\"worksheets/sheet\(id).xml\"/>"
            overrides += "<Override PartName=\"/xl/worksheets/sheet\(id).xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>"
            let headers=section["excelHeaders"] as? [String] ?? section["headers"] as? [String] ?? []
            let rows=section["excelRows"] as? [[Any]] ?? section["rows"] as? [[Any]] ?? []
            var body=""
            func row(_ values: [Any], number: Int, style: Int) -> String {
                let cells=values.enumerated().map { (i,value) -> String in
                    let reference="\(col(i))\(number)"
                    if let number=value as? NSNumber, number.doubleValue.isFinite {
                        return "<c r=\"\(reference)\" s=\"\(style == 3 ? 4 : 2)\"><v>\(number.stringValue)</v></c>"
                    }
                    let text=value is NSNull ? "—" : String(describing:value)
                    return "<c r=\"\(reference)\" s=\"\(style)\" t=\"inlineStr\"><is><t xml:space=\"preserve\">\(xml(text))</t></is></c>"
                }.joined()
                let longest=values.map { String(describing:$0).count }.max() ?? 0
                let height=min(300,max(style == 1 ? 38 : 34,((longest / 35)+1)*16))
                return "<row r=\"\(number)\" ht=\"\(height)\" customHeight=\"1\">\(cells)</row>"
            }
            body += row([heading],number:1,style:0)
            body += row([name + " · " + (report["period"] as? String ?? "")],number:2,style:0)
            body += row(["Сформировано: \(report["generatedAt"] as? String ?? "")"],number:3,style:0)
            body += row(headers,number:5,style:1)
            for (i,values) in rows.enumerated() {body += row(values,number:i+6,style:i % 2 == 0 ? 3 : 0)}
            let end=col(max(0,headers.count-1))
            let columns=headers.indices.map { "<col min=\"\($0+1)\" max=\"\($0+1)\" width=\"\(headers.count == 1 ? 115 : ($0 == 0 ? 42 : 23))\" customWidth=\"1\"/>" }.joined()
            let merges=headers.count>1 ? "<mergeCells count=\"3\"><mergeCell ref=\"A1:\(end)1\"/><mergeCell ref=\"A2:\(end)2\"/><mergeCell ref=\"A3:\(end)3\"/></mergeCells>" : ""
            let filter=rows.isEmpty ? "" : "<autoFilter ref=\"A5:\(end)\(rows.count+5)\"/>"
            overrides += "<Override PartName=\"/xl/drawings/drawing\(id).xml\" ContentType=\"application/vnd.openxmlformats-officedocument.drawing+xml\"/>"
            let bannerLines = [heading, name + " · " + (report["period"] as? String ?? ""), "Сформировано: " + (report["generatedAt"] as? String ?? "")]
            let bannerText = bannerLines.enumerated().map { i, text in
                "<a:p><a:r><a:rPr lang=\"ru-RU\" sz=\"\(i == 0 ? 1800 : 1100)\" b=\"\(i == 0 ? 1 : 0)\"><a:solidFill><a:srgbClr val=\"FFFFFF\"/></a:solidFill></a:rPr><a:t>\(xml(text))</a:t></a:r></a:p>"
            }.joined()
            files.append(("xl/drawings/drawing\(id).xml", """
            <xdr:wsDr xmlns:xdr="http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"><xdr:twoCellAnchor editAs="twoCell"><xdr:from><xdr:col>0</xdr:col><xdr:colOff>19050</xdr:colOff><xdr:row>0</xdr:row><xdr:rowOff>19050</xdr:rowOff></xdr:from><xdr:to><xdr:col>\(headers.count)</xdr:col><xdr:colOff>0</xdr:colOff><xdr:row>3</xdr:row><xdr:rowOff>0</xdr:rowOff></xdr:to><xdr:sp><xdr:nvSpPr><xdr:cNvPr id="1" name="Название заведения"/><xdr:cNvSpPr/></xdr:nvSpPr><xdr:spPr><a:prstGeom prst="roundRect"><a:avLst><a:gd name="adj" fmla="val 12000"/></a:avLst></a:prstGeom><a:solidFill><a:srgbClr val="000000"/></a:solidFill><a:ln><a:noFill/></a:ln></xdr:spPr><xdr:txBody><a:bodyPr wrap="square" lIns="190500" tIns="95000" rIns="190500" bIns="95000" anchor="ctr"><a:normAutofit/></a:bodyPr><a:lstStyle/>\(bannerText)</xdr:txBody></xdr:sp><xdr:clientData/></xdr:twoCellAnchor><xdr:twoCellAnchor editAs="twoCell"><xdr:from><xdr:col>0</xdr:col><xdr:colOff>0</xdr:colOff><xdr:row>4</xdr:row><xdr:rowOff>0</xdr:rowOff></xdr:from><xdr:to><xdr:col>\(headers.count)</xdr:col><xdr:colOff>0</xdr:colOff><xdr:row>\(rows.count + 5)</xdr:row><xdr:rowOff>0</xdr:rowOff></xdr:to><xdr:sp><xdr:nvSpPr><xdr:cNvPr id="2" name="Контур раздела"/><xdr:cNvSpPr/></xdr:nvSpPr><xdr:spPr><a:prstGeom prst="roundRect"><a:avLst><a:gd name="adj" fmla="val 1500"/></a:avLst></a:prstGeom><a:noFill/><a:ln w="12700"><a:solidFill><a:srgbClr val="000000"/></a:solidFill></a:ln></xdr:spPr></xdr:sp><xdr:clientData/></xdr:twoCellAnchor></xdr:wsDr>
            """))
            files.append(("xl/worksheets/_rels/sheet\(id).xml.rels", "<Relationships xmlns=\"\(package)\"><Relationship Id=\"banner\" Type=\"\(rel)/drawing\" Target=\"../drawings/drawing\(id).xml\"/></Relationships>"))
            files.append(("xl/worksheets/sheet\(id).xml", "<?xml version=\"1.0\" encoding=\"UTF-8\"?><worksheet xmlns=\"\(ns)\" xmlns:r=\"\(rel)\"><sheetViews><sheetView showGridLines=\"0\" workbookViewId=\"0\"><pane ySplit=\"5\" topLeftCell=\"A6\" activePane=\"bottomLeft\" state=\"frozen\"/></sheetView></sheetViews><cols>\(columns)</cols><sheetData>\(body)</sheetData>\(filter)\(merges)<drawing r:id=\"banner\"/></worksheet>"))
        }
        files.append(("xl/workbook.xml","<workbook xmlns=\"\(ns)\" xmlns:r=\"\(rel)\"><sheets>\(sheets)</sheets></workbook>"))
        files.append(("xl/_rels/workbook.xml.rels","<Relationships xmlns=\"\(package)\">\(links)<Relationship Id=\"styles\" Type=\"\(rel)/styles\" Target=\"styles.xml\"/></Relationships>"))
        files.append(("_rels/.rels","<Relationships xmlns=\"\(package)\"><Relationship Id=\"office\" Type=\"\(rel)/officeDocument\" Target=\"xl/workbook.xml\"/></Relationships>"))
        files.append(("[Content_Types].xml","<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\"><Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/><Default Extension=\"xml\" ContentType=\"application/xml\"/><Override PartName=\"/xl/workbook.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\"/><Override PartName=\"/xl/styles.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml\"/>\(overrides)</Types>"))
        files.append(("xl/styles.xml","""
        <styleSheet xmlns="\(ns)"><numFmts count="1"><numFmt numFmtId="164" formatCode="#,##0.######"/></numFmts><fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><color rgb="FFFFFFFF"/><sz val="12"/><name val="Calibri"/></font></fonts><fills count="4"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF000000"/><bgColor indexed="64"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FFF5F5F5"/><bgColor indexed="64"/></patternFill></fill></fills><borders count="1"><border/></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="5"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf><xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf><xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyAlignment="1"><alignment vertical="center"/></xf><xf numFmtId="0" fontId="0" fillId="3" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="center" wrapText="1" indent="1"/></xf><xf numFmtId="164" fontId="0" fillId="3" borderId="0" xfId="0" applyNumberFormat="1" applyAlignment="1"><alignment vertical="center" indent="1"/></xf></cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>
        """))
        return archive(files)
    }
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
    private let networkPrinter = BluetoothPrinterManager()
    private lazy var ownerAccess = OwnerAccessController(presenter:self)

    override func loadView() {
        let contentController = WKUserContentController()
        contentController.add(self, name: "printer")
        contentController.add(self, name: "telegram")
        contentController.add(self, name: "photoPicker")
        contentController.add(self, name: "ownerAccess")

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
        ownerAccess.lock()
        webView.evaluateJavaScript("window.POSAccess&&window.POSAccess.didLock();",completionHandler:nil)
        webView.evaluateJavaScript("window._availabilityAppActive=false;window.onAvailabilityAppState&&window.onAvailabilityAppState(false);", completionHandler: nil)
    }

    @objc private func resumeAvailability() {
        webView.evaluateJavaScript("window._availabilityAppActive=true;window.onAvailabilityAppState&&window.onAvailabilityAppState(true);", completionHandler: nil)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "ownerAccess" {
            guard message.frameInfo.isMainFrame, message.frameInfo.request.url?.isFileURL==true,
                  let body=message.body as? [String:Any],let id=body["requestId"] as? String else{return}
            ownerAccess.handle(body){[weak self] result in
                var response:[String:Any]=["requestId":id]
                switch result {case .success(let data):response["data"]=data;case .failure(let error):response["error"]=error.localizedDescription}
                guard let data=try? JSONSerialization.data(withJSONObject:response),let json=String(data:data,encoding:.utf8) else{return}
                self?.webView.evaluateJavaScript("window.POSAccess&&window.POSAccess.reply(\(json));",completionHandler:nil)
            };return
        }
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
            guard let prepared = self.prepareProductImage(image) else { return }
            let base64 = prepared.base64EncodedString()
            let js = "window.handleNativeProductImage && window.handleNativeProductImage('data:image/jpeg;base64,\(base64)');"
            DispatchQueue.main.async {
                self.webView.evaluateJavaScript(js, completionHandler: nil)
            }
        }
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
        let deviceKey = body["deviceKey"] as? String ?? ""
        guard !deviceKey.isEmpty else {
            sendTelegramResult(ok: false, message: "Настройте ключ устройства и получателя отчётов на backend.")
            return
        }
        let text = "🟢 <b>Telegram подключён</b>\nM POS успешно связался с рабочей группой."
        telegramRequest(deviceKey: deviceKey, text: text) { [weak self] ok, message in
            self?.sendTelegramResult(ok: ok, message: message)
        }
    }

    private func telegramSend(body: [String: Any]) {
        let deviceKey = body["deviceKey"] as? String ?? ""
        let text = body["text"] as? String ?? ""
        guard !deviceKey.isEmpty, !text.isEmpty else { return }
        telegramRequest(deviceKey: deviceKey, text: text, completion: nil)
    }

    private func telegramSendShiftCloseReport(body: [String: Any]) {
        let deviceKey = body["deviceKey"] as? String ?? ""
        let report = body["report"] as? [String: Any] ?? [:]
        guard !deviceKey.isEmpty, !report.isEmpty else { return }

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
            self.telegramPhotoRequest(deviceKey: deviceKey, imageData: imageData, caption: caption) { [weak self] ok, message in
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

    private func telegramPhotoRequest(deviceKey: String, imageData: Data, caption: String? = nil, completion: @escaping (Bool, String) -> Void) {
        telegramRelay(deviceKey:deviceKey,body:["photo":imageData.base64EncodedString(),"caption":caption ?? ""],completion:completion)
    }

    private func telegramRequest(deviceKey: String, text: String, completion: ((Bool, String) -> Void)?) {
        telegramRelay(deviceKey:deviceKey,body:["text":text],completion:completion)
    }

    private func telegramRelay(deviceKey:String,body:[String:Any],completion:((Bool,String)->Void)?) {
        OwnerAccessController.request("report",body:body,key:deviceKey){result in
            DispatchQueue.main.async {
                switch result {
                case .success:completion?(true,"Сообщение отправлено в Telegram")
                case .failure(let error):completion?(false,error.localizedDescription)
                }
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
        let title = report["title"] as? String ?? "Складской учёт"
        let period = report["period"] as? String ?? ""
        let generated = report["generatedAt"] as? String ?? ""
        let company = report["company"] as? String ?? ""
        let notes = report["notes"] as? [String] ?? []
        let sections = report["sections"] as? [[String: Any]] ?? []
        let page = CGRect(x: 0, y: 0, width: 842, height: 595)
        let margin: CGFloat = 36
        let width: CGFloat = page.width - margin * 2
        let muted = UIColor(white: 0.42, alpha: 1)
        let accent = UIColor.black
        let paper = UIColor(white: 0.96, alpha: 1)
        let lineHeight: CGFloat = 15
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        let data = renderer.pdfData { context in
            var y: CGFloat = 0
            var pageNumber = 0
            var firstSection = true
            func draw(_ text: String, _ rect: CGRect, font: UIFont = .systemFont(ofSize: 10), color: UIColor = UIColor(white: 0.12, alpha: 1)) {
                (text as NSString).draw(in: rect, withAttributes: [.font: font, .foregroundColor: color])
            }
            func lines(_ text: String, width: CGFloat, font: UIFont = .systemFont(ofSize: 10)) -> [String] {
                var result: [String] = []
                for paragraph in text.components(separatedBy: "\n") {
                    var line = ""
                    for word in paragraph.split(separator: " ") {
                        let next = line.isEmpty ? String(word) : line + " " + word
                        if (next as NSString).size(withAttributes: [.font: font]).width <= width {
                            line = next
                        } else {
                            if !line.isEmpty { result.append(line); line = "" }
                            for character in word {
                                let nextPart = line + String(character)
                                if !line.isEmpty && (nextPart as NSString).size(withAttributes: [.font: font]).width > width {
                                    result.append(line); line = String(character)
                                } else { line = nextPart }
                            }
                        }
                    }
                    result.append(line)
                }
                return result
            }
            func newPage() {
                context.beginPage(); pageNumber += 1
                if pageNumber == 1 {
                let brand = company.trimmingCharacters(in: .whitespacesAndNewlines)
                let heading = brand.isEmpty ? "Название заведения не указано" : brand
                accent.setFill(); UIBezierPath(roundedRect: CGRect(x: margin - 8, y: 22, width: width + 16, height: 82), cornerRadius: 14).fill()
                UIBezierPath(rect: CGRect(x: margin - 8, y: 86, width: width + 16, height: 18)).fill()
                let companyFont = UIFont.boldSystemFont(ofSize: 18)
                let companyLines = lines(heading, width: width - 32, font: companyFont)
                let companyText = companyLines.count > 1 ? companyLines[0] + "…" : heading
                draw(companyText, CGRect(x: margin + 16, y: 34, width: width - 32, height: 24), font: companyFont, color: .white)
                draw(title + "  ·  " + period, CGRect(x: margin + 16, y: 69, width: width - 32, height: 20), font: .systemFont(ofSize: 11), color: .white)
                }
                let footer = "Сформировано: \(generated)" + (pageNumber > 1 ? "  ·  Период: \(period)" : "")
                draw(footer, CGRect(x: margin, y: page.height - 27, width: width - 65, height: 18), color: muted)
                draw("\(pageNumber)", CGRect(x: page.width - margin - 30, y: page.height - 27, width: 30, height: 18), color: muted)
                y = pageNumber == 1 ? 116 : 36
            }
            newPage()
            for section in sections {
                let sectionTitle = section["title"] as? String ?? ""
                let headers = section["headers"] as? [String] ?? []
                let rows = section["rows"] as? [[String]] ?? []
                guard !headers.isEmpty else { continue }
                let firstWidth: CGFloat = headers.count > 6 ? 170 : width / CGFloat(headers.count)
                let otherWidth: CGFloat = headers.count > 1 ? (width - firstWidth) / CGFloat(headers.count - 1) : width
                let widths = headers.indices.map { $0 == 0 ? firstWidth : otherWidth }
                let headerLines = headers.enumerated().map { lines($0.element, width: widths[$0.offset] - 12, font: .boldSystemFont(ofSize: 9)) }
                let headerHeight = CGFloat(headerLines.map { $0.count }.max() ?? 1) * lineHeight + 12
                var blockTop: CGFloat = 0
                func finishBlock() {
                    UIColor.black.setStroke()
                    let outline = UIBezierPath(roundedRect: CGRect(x: margin - 8, y: blockTop - 8, width: width + 16, height: y - blockTop + 16), cornerRadius: 14)
                    outline.lineWidth = 0.8; outline.stroke()
                }
                func tableHeader() {
                    blockTop = pageNumber == 1 && firstSection ? 30 : y
                    firstSection = false
                    draw(sectionTitle, CGRect(x: margin, y: y, width: width, height: 23), font: .boldSystemFont(ofSize: 13)); y += 26
                    accent.setFill(); UIBezierPath(roundedRect: CGRect(x: margin, y: y, width: width, height: headerHeight), cornerRadius: 10).fill()
                    var x = margin
                    for (index, cell) in headerLines.enumerated() {
                        for (lineIndex, line) in cell.enumerated() {
                            draw(line, CGRect(x: x + 6, y: y + 6 + CGFloat(lineIndex) * lineHeight, width: widths[index] - 12, height: lineHeight), font: .boldSystemFont(ofSize: 9), color: .white)
                        }
                        x += widths[index]
                    }
                    y += headerHeight + 6
                }
                if y + headerHeight + 65 > page.height - 45 { newPage() }
                y += 12; tableHeader()
                let displayRows = rows.isEmpty ? [Array(repeating: "—", count: headers.count)] : rows
                for (rowIndex, row) in displayRows.enumerated() {
                    let cells = headers.indices.map { lines($0 < row.count ? row[$0] : "", width: widths[$0] - 12) }
                    let count = cells.map { $0.count }.max() ?? 1
                    let fullRowHeight = CGFloat(count) * lineHeight + 12
                    let freshPageSpace = page.height - 45 - 36 - 26 - headerHeight - 6
                    if fullRowHeight <= freshPageSpace && y + fullRowHeight > page.height - 45 {
                        finishBlock(); newPage(); tableHeader()
                    }
                    var offset = 0
                    while offset < count {
                        var available = Int((page.height - 45 - y - 12) / lineHeight)
                        if available < 1 { finishBlock(); newPage(); tableHeader(); available = Int((page.height - 45 - y - 12) / lineHeight) }
                        let chunk = min(count - offset, available)
                        let height = CGFloat(chunk) * lineHeight + 12
                        (rowIndex % 2 == 0 ? paper : UIColor.white).setFill()
                        UIBezierPath(roundedRect: CGRect(x: margin, y: y, width: width, height: height), cornerRadius: 8).fill()
                        var x = margin
                        for (index, cell) in cells.enumerated() {
                            for lineIndex in 0..<chunk where offset + lineIndex < cell.count {
                                draw(cell[offset + lineIndex], CGRect(x: x + 6, y: y + 6 + CGFloat(lineIndex) * lineHeight, width: widths[index] - 12, height: lineHeight))
                            }
                            x += widths[index]
                        }
                        y += height + 4; offset += chunk
                    }
                }
                finishBlock()
                y += 30
            }
            if !notes.isEmpty {
                newPage()
                draw("Как читать отчёт", CGRect(x: margin, y: y, width: width, height: 26), font: .boldSystemFont(ofSize: 16)); y += 38
                for note in notes {
                    let content = lines(note, width: width - 28)
                    for start in stride(from: 0, to: content.count, by: 18) {
                        let chunk = Array(content[start..<min(start + 18, content.count)])
                        let height = CGFloat(chunk.count) * lineHeight + 24
                        if y + height > page.height - 45 { newPage() }
                        paper.setFill()
                        let noteBox = UIBezierPath(roundedRect: CGRect(x: margin, y: y, width: width, height: height), cornerRadius: 12)
                        noteBox.fill(); UIColor.black.setStroke(); noteBox.lineWidth = 0.8; noteBox.stroke()
                        for (index, text) in chunk.enumerated() {
                            draw(text, CGRect(x: margin + 14, y: y + 12 + CGFloat(index) * lineHeight, width: width - 28, height: lineHeight), color: muted)
                        }
                        y += height + 12
                    }
                }
            }
        }
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
        items: [(String, String)],
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
                drawText("M POS", x: margin, y: pageRect.height - 32, width: 160, font: smallBold, color: muted)
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
            drawText("\(items.count) позиций", x: pageRect.width - margin - 180, y: y, width: 180, font: smallBold, color: muted, alignment: .right)
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
                    with: CGSize(width: contentWidth - 170, height: 1000),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [.font: bodyFont],
                    context: nil
                ).height
                let quantityHeight = NSString(string: qty).boundingRect(with: CGSize(width: 120, height: 1000), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: boldFont], context: nil).height
                let rowHeight = max(CGFloat(39), ceil(max(textHeight, quantityHeight)) + 18)

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
                drawText(name, x: margin + 42, y: y + 10, width: contentWidth - 170, font: bodyFont, color: ink)
                drawText(qty, x: pageRect.width - margin - 132, y: y + 10, width: 120, font: boldFont, color: ink, alignment: .right)
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
            drawText("По позициям", x: pageRect.width - margin - 180, y: y + 25, width: 160, font: UIFont.boldSystemFont(ofSize: 20), color: dark, alignment: .right)
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
