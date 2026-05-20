import SwiftUI

struct POSListRow: View {
    @AppStorage("currency") private var currency: Currency = .yen
    @Bindable var item: InventoryItem
    var day: EventDay
    var cart: CartStore
    var onAdd: () -> Void

    var body: some View {
        let remaining = max(0, (item.stock(on: day)?.remaining ?? 0) - cart.qty(for: item))
        let oos = remaining == 0
        Button(action: onAdd) {
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
                Text(item.price > 0 ? currency.format(item.price) : String(localized: "items.free"))
                    .font(.body.weight(.semibold))
                    .monospacedDigit()
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(oos ? Color.secondary : Brand.tint)
            }
            .opacity(oos ? 0.5 : 1)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
