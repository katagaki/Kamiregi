import SwiftUI

struct CartLineRow: View {
    var line: CartItem
    @Bindable var cart: CartStore

    var body: some View {
        HStack(spacing: 12) {
            Text(line.emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(line.swatch, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(line.name)
                    .font(.body.weight(.semibold))
                Text(line.sub)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Stepper(value: qtyBinding, in: 0...99) {
                Text("\(line.qty)").monospacedDigit().font(.body.weight(.semibold))
            }
            .labelsHidden()
            Text(yen(line.subtotal))
                .font(.body.weight(.bold))
                .monospacedDigit()
                .frame(minWidth: 64, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }

    private var qtyBinding: Binding<Int> {
        Binding(
            get: { line.qty },
            set: { newValue in
                if newValue <= 0 {
                    cart.decrement(line)
                } else if let idx = cart.lines.firstIndex(of: line) {
                    cart.lines[idx].qty = newValue
                }
            }
        )
    }
}
