import SwiftUI

struct CartLineRow: View {
    var line: CartItem
    @Bindable var cart: CartStore

    private var liveQty: Int {
        cart.lines.first(where: { $0.id == line.id })?.qty ?? line.qty
    }

    var body: some View {
        HStack(spacing: 12) {
            ItemThumbnail(name: line.name, photoData: line.photoData)
            VStack(alignment: .leading, spacing: 2) {
                Text(line.name)
                    .font(.body.weight(.semibold))
                Text(line.sub)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Stepper(value: qtyBinding, in: 0...99) {
                Text("\(liveQty)").monospacedDigit().font(.body.weight(.semibold))
            }
            .labelsHidden()
            Text(yen(liveQty * line.price))
                .font(.body.weight(.bold))
                .monospacedDigit()
                .frame(minWidth: 64, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }

    private var qtyBinding: Binding<Int> {
        Binding(
            get: { liveQty },
            set: { newValue in
                if newValue <= 0 {
                    cart.decrement(line)
                } else if let idx = cart.lines.firstIndex(where: { $0.id == line.id }) {
                    cart.lines[idx].qty = newValue
                }
            }
        )
    }
}
