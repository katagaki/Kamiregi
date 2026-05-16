import SwiftUI

struct BreakdownRow: View {
    @Bindable var item: InventoryItem
    var day: EventDay

    var body: some View {
        let sold = item.stock(on: day)?.sold ?? 0
        let initial = item.stock(on: day)?.initial ?? 0
        let percent: Double = initial > 0 ? Double(sold) / Double(initial) : 0
        let oos = (item.stock(on: day)?.remaining ?? 0) == 0

        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Text(item.emoji)
                    .font(.title3)
                    .frame(width: 36, height: 36)
                    .background(item.swatch, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                    Text("\(sold) / \(initial) · \(yen(sold * item.price))")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int((percent * 100).rounded()))%")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: percent)
                .tint(oos ? .red : UC.tint)
        }
        .padding(.vertical, 2)
    }
}
