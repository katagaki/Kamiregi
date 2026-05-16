import SwiftUI

struct TapRegionView: View {
    var region: TapRegion
    var editing: Bool
    var onTap: () -> Void

    var body: some View {
        let oos = region.isOutOfStock
        let stroke: Color = editing ? (oos ? .red : UC.tint) : UC.tint.opacity(0.45)
        let strokeStyle: StrokeStyle = editing
            ? StrokeStyle(lineWidth: 2, dash: [4, 3])
            : StrokeStyle(lineWidth: 1.5)
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.regularMaterial)
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(stroke, style: strokeStyle)
                VStack {
                    HStack(spacing: 2) {
                        Text(region.emoji)
                        Text(region.name)
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(oos ? Color.red : UC.tint, in: Capsule())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    HStack(alignment: .bottom) {
                        Text(region.price > 0 ? yen(region.price) : String(localized: "items.free"))
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
                            Text("pos.stock.remaining \(region.stock)")
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
