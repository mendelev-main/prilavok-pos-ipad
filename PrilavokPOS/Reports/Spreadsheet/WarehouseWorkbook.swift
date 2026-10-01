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

