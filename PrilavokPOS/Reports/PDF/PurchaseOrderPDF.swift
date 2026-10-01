import UIKit

// Document rendering is independent of the view controller and WebKit bridge.
enum PurchaseOrderPDF {
    static func createPurchaseOrderPDF(
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

    private static func formatterString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }

}
