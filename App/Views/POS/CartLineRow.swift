import SwiftUI

struct CartLineRow: View {
    @AppStorage("currency") private var currency: Currency = .yen
    var line: CartItem
    @Bindable var cart: CartStore
    var flight: CartFlightController?
    @State private var pulse = false

    private var liveQty: Int {
        cart.lines.first(where: { $0.id == line.id })?.qty ?? line.qty
    }

    private var pulseToken: Int {
        guard let id = line.itemID else { return 0 }
        return flight?.rowPulseTokens[id] ?? 0
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ItemThumbnail(name: line.name, photoData: line.photoData)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(line.name)
                        .font(.body.weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(currency.format(liveQty * line.price))
                        .font(.body.weight(.bold))
                        .monospacedDigit()
                }
                Text(line.sub)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Button {
                        cart.decrement(line)
                    } label: {
                        Image(systemName: liveQty == 1 ? "trash" : "minus")
                            .font(.caption.weight(.semibold))
                            .frame(width: 26, height: 26)
                            .background(.secondary.opacity(0.15), in: Circle())
                    }
                    .buttonStyle(.plain)
                    Text("\(liveQty)")
                        .font(.body.weight(.semibold))
                        .monospacedDigit()
                        .frame(minWidth: 22, alignment: .center)
                    Button {
                        cart.increment(line)
                    } label: {
                        Image(systemName: "plus")
                            .font(.caption.weight(.semibold))
                            .frame(width: 26, height: 26)
                            .background(.secondary.opacity(0.15), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 2)
        .scaleEffect(pulse ? 1.06 : 1)
        .reportGlobalFrame { rect in
            if let id = line.itemID { flight?.sidebarRowAnchors[id] = rect }
        }
        .onChange(of: pulseToken) { _, _ in
            withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) { pulse = true }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.12)) { pulse = false }
        }
    }
}
