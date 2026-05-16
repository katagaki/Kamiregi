import SwiftUI

// Read-only canvas that draws the stored Oshinagaki image and overlays each
// item's tap region. Tapping a region calls `onTap` with the corresponding item.
struct OshinagakiCanvas: View {
    var imageData: Data?
    var items: [InventoryItem]
    var day: EventDay
    var onTap: (InventoryItem) -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack {
                background
                ForEach(itemsWithRegions, id: \.id) { item in
                    let rect = item.regionRect
                    let frame = CGRect(
                        x: rect.minX * geo.size.width,
                        y: rect.minY * geo.size.height,
                        width: rect.width * geo.size.width,
                        height: rect.height * geo.size.height
                    )
                    OshinagakiTapRegion(item: item, day: day, onTap: { onTap(item) })
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
        }
        .aspectRatio(1.0 / 1.34, contentMode: .fit)
    }

    private var itemsWithRegions: [InventoryItem] {
        items.filter { $0.hasRegion }
    }

    @ViewBuilder
    private var background: some View {
        if let data = imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            StripedPlaceholder()
        }
    }
}

private struct OshinagakiTapRegion: View {
    @Bindable var item: InventoryItem
    var day: EventDay
    var onTap: () -> Void

    var body: some View {
        let remaining = item.stock(on: day)?.remaining ?? 0
        let oos = remaining == 0
        let strokeColor: Color = oos ? .red : Brand.tint

        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.regularMaterial)
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(strokeColor.opacity(0.6), lineWidth: 1.5)
                VStack {
                    HStack(spacing: 2) {
                        Text(item.emoji)
                        Text(item.name)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(oos ? Color.red : Brand.tint, in: Capsule())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    HStack(alignment: .bottom) {
                        Text(item.price > 0 ? yen(item.price) : String(localized: "items.free"))
                            .font(.footnote.weight(.bold))
                            .monospacedDigit()
                        Spacer()
                        if oos {
                            Text("pos.stock.sold_out")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.black.opacity(0.85), in: Capsule())
                        } else {
                            Text("pos.stock.remaining \(remaining)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(8)
            }
        }
        .buttonStyle(.plain)
    }
}
