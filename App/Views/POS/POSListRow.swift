import SwiftUI

struct POSListRow: View {
    @Bindable var item: InventoryItem
    var day: EventDay
    var onAdd: () -> Void

    var body: some View {
        let remaining = item.stock(on: day)?.remaining ?? 0
        let oos = remaining == 0
        HStack(spacing: 12) {
            ItemThumbnail(name: item.name, photoData: item.photoData)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.body.weight(.semibold))
                    StockPill(stock: remaining)
                }
                Text(item.sub)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(item.price > 0 ? yen(item.price) : String(localized: "items.free"))
                .font(.body.weight(.semibold))
                .monospacedDigit()
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(oos ? Color.secondary : Brand.tint)
            }
            .buttonStyle(.borderless)
        }
        .opacity(oos ? 0.5 : 1)
        .padding(.vertical, 2)
    }
}
