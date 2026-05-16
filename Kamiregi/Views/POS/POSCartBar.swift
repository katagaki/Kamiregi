import SwiftUI

struct POSCartBar: View {
    @Bindable var cart: CartStore
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "cart")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .overlay(alignment: .topTrailing) {
                        if cart.count > 0 {
                            Text("\(cart.count)")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .frame(minWidth: 18, minHeight: 18)
                                .background(UC.tint, in: Capsule())
                                .offset(x: 10, y: -8)
                        }
                    }
                VStack(alignment: .leading, spacing: 0) {
                    Text("pos.cart.subtotal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text(yen(cart.subtotal))
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                }
                Spacer()
                Label("pos.cart.checkout", systemImage: "chevron.right")
                    .labelStyle(.titleAndIcon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 44)
                    .background(UC.tint, in: Capsule())
            }
            .padding(.horizontal, 18)
            .frame(height: 60)
            .background(.regularMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
