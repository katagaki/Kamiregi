import SwiftUI

// Brand tokens - only the things that aren't already covered by SwiftUI's
// system-adaptive colors. Everything else (text, backgrounds, separators)
// should use .primary / .secondary / Color(.systemGroupedBackground) etc.
enum Brand {
    static let tint = Color.accentColor
    static let tintDim = Color.accentColor.opacity(0.14)

    static let paletteSwatches = [
        "#FF5A4E", "#FF9F0A", "#FFCC00", "#34C759",
        "#5AC8FA", "#5A8DEE", "#AF52DE", "#FF2D55"
    ]
}

extension Color {
    init(hex: String) {
        var cleaned = hex
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red, green, blue, alpha: Double
        switch cleaned.count {
        case 6:
            red   = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8)  & 0xFF) / 255
            blue  = Double( value        & 0xFF) / 255
            alpha = 1
        case 8:
            red   = Double((value >> 24) & 0xFF) / 255
            green = Double((value >> 16) & 0xFF) / 255
            blue  = Double((value >> 8)  & 0xFF) / 255
            alpha = Double( value        & 0xFF) / 255
        default:
            red = 0; green = 0; blue = 0; alpha = 1
        }
        self = Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

func yen(_ amount: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.groupingSeparator = ","
    return "¥" + (formatter.string(from: NSNumber(value: amount)) ?? String(amount))
}
