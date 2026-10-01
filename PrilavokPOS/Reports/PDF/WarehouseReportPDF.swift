import UIKit

// Document rendering is independent of the view controller and WebKit bridge.
enum WarehouseReportPDF {
    static func makeWarehouseReportPDF(report: [String: Any]) -> Data {
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
            return data
    }

}
