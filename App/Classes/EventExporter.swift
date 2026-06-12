import Foundation

enum EventExporter {
    static func xlsxFile(for event: Event) throws -> URL {
        let url = tempURL(name: event.name, ext: "xlsx")
        try xlsxData(for: event).write(to: url, options: .atomic)
        return url
    }

    static func csvFile(for day: EventDay, in event: Event) throws -> URL {
        let url = tempURL(name: "\(event.name) \(day.label)", ext: "csv")
        try Data(csv(for: day).utf8).write(to: url, options: .atomic)
        return url
    }

    private static var columnHeaders: [String] {
        [
            "#",
            String(localized: "export.column.time"),
            String(localized: "export.column.total"),
            String(localized: "export.column.items")
        ]
    }

    private static func sortedTransactions(_ day: EventDay) -> [SaleTransaction] {
        day.transactions.sorted { $0.number < $1.number }
    }

    private static func itemsSummary(_ transaction: SaleTransaction) -> String {
        transaction.lines.map { "\($0.itemName) × \($0.qty)" }.joined(separator: " / ")
    }

    private static func tempURL(name: String, ext: String) -> URL {
        var safe = name.replacingOccurrences(of: "[/:\\\\]", with: "-", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        if safe.isEmpty { safe = "Export" }
        return FileManager.default.temporaryDirectory
            .appendingPathComponent(safe)
            .appendingPathExtension(ext)
    }

    // MARK: - CSV

    private static func csv(for day: EventDay) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        var lines = [columnHeaders.map(csvField).joined(separator: ",")]
        for transaction in sortedTransactions(day) {
            let fields = [
                "\(transaction.number)", fmt.string(from: transaction.timestamp),
                "\(transaction.total)", itemsSummary(transaction)
            ]
            lines.append(fields.map(csvField).joined(separator: ","))
        }
        // BOM so Excel detects UTF-8
        return "\u{FEFF}" + lines.joined(separator: "\n")
    }

    private static func csvField(_ value: String) -> String {
        guard value.contains(where: { ",\"\n".contains($0) }) else { return value }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    // MARK: - XLSX

    private static let relsNS = "http://schemas.openxmlformats.org/package/2006/relationships"
    private static let officeRelNS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    private static let sheetMLType = "application/vnd.openxmlformats-officedocument.spreadsheetml"

    private static func xlsxData(for event: Event) -> Data {
        let days = event.sortedDays
        var usedNames = Set<String>()
        let names = days.enumerated().map { sheetName($0.element.label, index: $0.offset, used: &usedNames) }

        var zip = ZipWriter()
        zip.add("[Content_Types].xml", xml(contentTypes(sheetCount: days.count)))
        zip.add("_rels/.rels", xml("""
            <Relationships xmlns="\(relsNS)">\
            <Relationship Id="rId1" Type="\(officeRelNS)/officeDocument" Target="xl/workbook.xml"/>\
            </Relationships>
            """))
        zip.add("xl/workbook.xml", xml(workbook(names: names)))
        zip.add("xl/_rels/workbook.xml.rels", xml(workbookRels(sheetCount: days.count)))
        zip.add("xl/styles.xml", xml(styles))
        for (index, day) in days.enumerated() {
            zip.add("xl/worksheets/sheet\(index + 1).xml", xml(worksheet(for: day)))
        }
        return zip.finish()
    }

    private static func sheetName(_ label: String, index: Int, used: inout Set<String>) -> String {
        var name = label.replacingOccurrences(of: "[\\[\\]:*?/\\\\]", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        if name.isEmpty { name = "Day \(index + 1)" }
        name = String(name.prefix(31))
        var candidate = name
        var suffix = 2
        while used.contains(candidate) {
            candidate = "\(name.prefix(28)) \(suffix)"
            suffix += 1
        }
        used.insert(candidate)
        return candidate
    }

    private static func xml(_ body: String) -> Data {
        Data(("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" + body).utf8)
    }

    private static func contentTypes(sheetCount: Int) -> String {
        var overrides = """
            <Override PartName="/xl/workbook.xml" ContentType="\(sheetMLType).sheet.main+xml"/>\
            <Override PartName="/xl/styles.xml" ContentType="\(sheetMLType).styles+xml"/>
            """
        for index in 1...max(sheetCount, 1) {
            overrides += "<Override PartName=\"/xl/worksheets/sheet\(index).xml\" "
                + "ContentType=\"\(sheetMLType).worksheet+xml\"/>"
        }
        return """
            <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\
            <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\
            <Default Extension="xml" ContentType="application/xml"/>\(overrides)</Types>
            """
    }

    private static func workbook(names: [String]) -> String {
        let sheets = names.enumerated().map { index, name in
            "<sheet name=\"\(xmlEscape(name))\" sheetId=\"\(index + 1)\" r:id=\"rId\(index + 1)\"/>"
        }.joined()
        return """
            <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" \
            xmlns:r="\(officeRelNS)">\
            <sheets>\(sheets)</sheets></workbook>
            """
    }

    private static func workbookRels(sheetCount: Int) -> String {
        var rels = (1...max(sheetCount, 1)).map { index in
            "<Relationship Id=\"rId\(index)\" Type=\"\(officeRelNS)/worksheet\" "
                + "Target=\"worksheets/sheet\(index).xml\"/>"
        }.joined()
        rels += "<Relationship Id=\"rId\(sheetCount + 1)\" Type=\"\(officeRelNS)/styles\" Target=\"styles.xml\"/>"
        return "<Relationships xmlns=\"\(relsNS)\">\(rels)</Relationships>"
    }

    private static var styles: String {
        // Header fill is AccentColor's light variant (#FF7B00)
        """
        <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">\
        <fonts count="2">\
        <font><sz val="12"/><name val="Calibri"/></font>\
        <font><b/><color rgb="FFFFFFFF"/><sz val="12"/><name val="Calibri"/></font>\
        </fonts>\
        <fills count="3">\
        <fill><patternFill patternType="none"/></fill>\
        <fill><patternFill patternType="gray125"/></fill>\
        <fill><patternFill patternType="solid"><fgColor rgb="FFFF7B00"/></patternFill></fill>\
        </fills>\
        <borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>\
        <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>\
        <cellXfs count="2">\
        <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>\
        <xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1">\
        <alignment horizontal="center"/></xf>\
        </cellXfs>\
        <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>\
        </styleSheet>
        """
    }

    private static func worksheet(for day: EventDay) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy/MM/dd HH:mm:ss"
        let columns = ["A", "B", "C", "D"]

        var rows = "<row r=\"1\">" + columnHeaders.enumerated().map { index, header in
            "<c r=\"\(columns[index])1\" s=\"1\" t=\"inlineStr\"><is><t>\(xmlEscape(header))</t></is></c>"
        }.joined() + "</row>"

        for (index, transaction) in sortedTransactions(day).enumerated() {
            let row = index + 2
            let time = xmlEscape(fmt.string(from: transaction.timestamp))
            rows += """
                <row r="\(row)">\
                <c r="A\(row)"><v>\(transaction.number)</v></c>\
                <c r="B\(row)" t="inlineStr"><is><t>\(time)</t></is></c>\
                <c r="C\(row)"><v>\(transaction.total)</v></c>\
                <c r="D\(row)" t="inlineStr"><is><t>\(xmlEscape(itemsSummary(transaction)))</t></is></c>\
                </row>
                """
        }

        return """
            <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">\
            <sheetViews><sheetView workbookViewId="0">\
            <pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>\
            </sheetView></sheetViews>\
            <cols>\
            <col min="1" max="1" width="8" customWidth="1"/>\
            <col min="2" max="2" width="20" customWidth="1"/>\
            <col min="3" max="3" width="11" customWidth="1"/>\
            <col min="4" max="4" width="50" customWidth="1"/>\
            </cols>\
            <sheetData>\(rows)</sheetData></worksheet>
            """
    }

    private static func xmlEscape(_ value: String) -> String {
        value.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

// Minimal ZIP container (stored entries, no compression)
private struct ZipWriter {
    private var body = Data()
    private var central = Data()
    private var count: UInt16 = 0

    mutating func add(_ name: String, _ content: Data) {
        let nameBytes = Data(name.utf8)
        let crc = crc32(content)
        let offset = UInt32(body.count)
        let size = UInt32(content.count)

        body.appendLE(UInt32(0x04034B50))
        body.appendLE(UInt16(20))
        body.appendLE(UInt16(0x0800))
        body.appendLE(UInt16(0))
        body.appendLE(UInt16(0))
        body.appendLE(UInt16(0x21))
        body.appendLE(crc)
        body.appendLE(size)
        body.appendLE(size)
        body.appendLE(UInt16(nameBytes.count))
        body.appendLE(UInt16(0))
        body.append(nameBytes)
        body.append(content)

        central.appendLE(UInt32(0x02014B50))
        central.appendLE(UInt16(20))
        central.appendLE(UInt16(20))
        central.appendLE(UInt16(0x0800))
        central.appendLE(UInt16(0))
        central.appendLE(UInt16(0))
        central.appendLE(UInt16(0x21))
        central.appendLE(crc)
        central.appendLE(size)
        central.appendLE(size)
        central.appendLE(UInt16(nameBytes.count))
        central.appendLE(UInt16(0))
        central.appendLE(UInt16(0))
        central.appendLE(UInt16(0))
        central.appendLE(UInt16(0))
        central.appendLE(UInt32(0))
        central.appendLE(offset)
        central.append(nameBytes)
        count += 1
    }

    func finish() -> Data {
        var out = body + central
        out.appendLE(UInt32(0x06054B50))
        out.appendLE(UInt16(0))
        out.appendLE(UInt16(0))
        out.appendLE(count)
        out.appendLE(count)
        out.appendLE(UInt32(central.count))
        out.appendLE(UInt32(body.count))
        out.appendLE(UInt16(0))
        return out
    }

    private func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                crc = (crc & 1) == 1 ? 0xEDB88320 ^ (crc >> 1) : crc >> 1
            }
        }
        return crc ^ 0xFFFFFFFF
    }
}

private extension Data {
    mutating func appendLE<T: FixedWidthInteger>(_ value: T) {
        Swift.withUnsafeBytes(of: value.littleEndian) { append(contentsOf: $0) }
    }
}
