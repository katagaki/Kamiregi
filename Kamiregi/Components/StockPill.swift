import SwiftUI

struct StockPill: View {
    var stock: Int

    var body: some View {
        let (bg, fg, key): (Color, Color, LocalizedStringKey) = {
            if stock == 0 {
                return (Color.red.opacity(0.14), .red, "pos.stock.sold_out")
            }
            if stock <= 10 {
                return (Color.orange.opacity(0.16), .orange, "pos.stock.remaining \(stock)")
            }
            return (Color.green.opacity(0.16), .green, "pos.stock.remaining \(stock)")
        }()
        return Text(key)
            .font(.caption2.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bg, in: Capsule())
    }
}
