import SwiftUI

// Aspect ratio used to lay out the Oshinagaki canvas. Matches the stored
// image's natural ratio so tap regions (stored in unit space) stay aligned;
// falls back to a portrait placeholder when no image is set.
enum OshinagakiLayout {
    static let placeholderAspect = CGSize(width: 1.0, height: 1.34)

    static func aspect(for imageData: Data?) -> CGSize {
        if let data = imageData, let uiImage = UIImage(data: data),
           uiImage.size.width > 0, uiImage.size.height > 0 {
            return uiImage.size
        }
        return placeholderAspect
    }
}

struct ZoomableOshinagakiCanvas: View {
    var imageData: Data?
    var items: [InventoryItem]
    var day: EventDay
    var cart: CartStore
    var onTap: (InventoryItem) -> Void

    var body: some View {
        ZoomableScrollView(aspect: OshinagakiLayout.aspect(for: imageData)) {
            OshinagakiCanvas(
                imageData: imageData,
                items: items,
                day: day,
                cart: cart,
                onTap: onTap
            )
        }
    }
}

// Read-only canvas that draws the stored Oshinagaki image and overlays each
// item's tap region. Tapping a region calls `onTap` with the corresponding item.
struct OshinagakiCanvas: View {
    var imageData: Data?
    var items: [InventoryItem]
    var day: EventDay
    var cart: CartStore
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
                    OshinagakiTapRegion(item: item, day: day, cart: cart, onTap: { onTap(item) })
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
                }
            }
        }
        .aspectRatio(OshinagakiLayout.aspect(for: imageData), contentMode: .fit)
    }

    private var itemsWithRegions: [InventoryItem] {
        items.filter { $0.hasRegion }
    }

    @ViewBuilder
    private var background: some View {
        if let data = imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else {
            StripedPlaceholder()
        }
    }
}

private struct OshinagakiTapRegion: View {
    @Bindable var item: InventoryItem
    var day: EventDay
    var cart: CartStore
    var onTap: () -> Void

    var body: some View {
        let remaining = max(0, (item.stock(on: day)?.remaining ?? 0) - cart.qty(for: item))
        let oos = remaining == 0
        let strokeColor: Color = oos ? .red : Brand.tint

        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(oos ? Color.black.opacity(0.35) : Color.clear)
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(strokeColor.opacity(0.6), lineWidth: 1.5)
                if oos {
                    Text("pos.stock.sold_out")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.black.opacity(0.85), in: Capsule())
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
