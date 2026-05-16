import SwiftUI

struct OshinagakiCanvas: View {
    var regions: [TapRegion]
    var editing: Bool = false
    var onTap: ((TapRegion) -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack {
                StripedPlaceholder()
                ForEach(regions) { region in
                    let frame = CGRect(
                        x: region.rect.minX * geo.size.width,
                        y: region.rect.minY * geo.size.height,
                        width: region.rect.width * geo.size.width,
                        height: region.rect.height * geo.size.height
                    )
                    TapRegionView(region: region, editing: editing) { onTap?(region) }
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
}
