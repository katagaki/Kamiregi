import SwiftUI

struct BreakdownRow: View {
    @AppStorage("currency") private var currency: Currency = .yen
    @Bindable var item: InventoryItem
    var day: EventDay

    var body: some View {
        let sold = item.stock(on: day)?.sold ?? 0
        let initial = item.stock(on: day)?.initial ?? 0
        let percent: Double = initial > 0 ? Double(sold) / Double(initial) : 0
        let oos = (item.stock(on: day)?.remaining ?? 0) == 0

        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ItemThumbnail(name: item.name, photoData: item.photoData, size: 36, cornerRadius: 9)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                    Text("\(sold) / \(initial) · \(currency.format(sold * item.price))")
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
                .tint(oos ? .red : Brand.tint)
        }
        .padding(.vertical, 2)
    }
}
