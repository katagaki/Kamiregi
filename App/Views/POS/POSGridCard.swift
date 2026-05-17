import SwiftUI

struct POSGridCard: View {
    @AppStorage("currency") private var currency: Currency = .yen
    @Bindable var item: InventoryItem
    var day: EventDay
    var onAdd: () -> Void

    var body: some View {
        let remaining = item.stock(on: day)?.remaining ?? 0
        let oos = remaining == 0
        Button(action: onAdd) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    itemBanner
                        .frame(maxWidth: .infinity)
                        .frame(height: 96)
                        .clipped()
                    StockPill(stock: remaining).padding(8)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(item.sub)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text(item.price > 0 ? currency.format(item.price) : String(localized: "items.free"))
                            .font(.body.weight(.bold))
                            .monospacedDigit()
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(oos ? Color.secondary : Brand.tint)
                    }
                }
                .padding(10)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(oos ? 0.55 : 1)
            .overlay {
                if oos {
                    Text("pos.stock.sold_out")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.85), in: Capsule())
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(false)
    }

    @ViewBuilder
    private var itemBanner: some View {
        if let data = item.photoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            let colors = ItemThumbnail.colors(for: item.name)
            ZStack {
                colors.bg
                Text(String(item.name.trimmingCharacters(in: .whitespaces).first ?? "?"))
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(colors.fg)
            }
        }
    }
}
