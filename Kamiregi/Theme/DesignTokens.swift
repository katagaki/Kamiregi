import SwiftUI

// Brand tokens — only the things that aren't already covered by SwiftUI's
// system-adaptive colors. Everything else (text, backgrounds, separators)
// should use .primary / .secondary / Color(.systemGroupedBackground) etc.
enum UC {
    static let tint = Color.accentColor
    static let tintDim = Color.accentColor.opacity(0.14)

    static let paletteSwatches = [
        "#FF5A4E", "#FF9F0A", "#FFCC00", "#34C759",
        "#5AC8FA", "#5A8DEE", "#AF52DE", "#FF2D55"
    ]
}

extension Color {
    init(hex: String) {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r, g, b, a: Double
        switch s.count {
        case 6:
            r = Double((v >> 16) & 0xFF) / 255
            g = Double((v >> 8) & 0xFF) / 255
            b = Double(v & 0xFF) / 255
            a = 1
        case 8:
            r = Double((v >> 24) & 0xFF) / 255
            g = Double((v >> 16) & 0xFF) / 255
            b = Double((v >> 8) & 0xFF) / 255
            a = Double(v & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0; a = 1
        }
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

func yen(_ n: Int) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.groupingSeparator = ","
    return "¥" + (f.string(from: NSNumber(value: n)) ?? String(n))
}
