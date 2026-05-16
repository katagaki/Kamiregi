import SwiftUI

struct StockPill: View {
    var stock: Int

    private struct Style {
        let background: Color
        let foreground: Color
        let labelKey: LocalizedStringKey
    }

    var body: some View {
        let style = currentStyle
        return Text(style.labelKey)
            .font(.caption2.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(style.foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(style.background, in: Capsule())
    }

    private var currentStyle: Style {
        if stock == 0 {
            return Style(background: .red.opacity(0.14), foreground: .red, labelKey: "pos.stock.sold_out")
        }
        if stock <= 10 {
            return Style(background: .orange.opacity(0.16), foreground: .orange, labelKey: "pos.stock.remaining \(stock)")
        }
        return Style(background: .green.opacity(0.16), foreground: .green, labelKey: "pos.stock.remaining \(stock)")
    }
}
