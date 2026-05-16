import SwiftUI

struct POSCartBar: View {
    @Bindable var cart: CartStore
    var onTap: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                totalCapsule
                checkoutCapsule
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var totalCapsule: some View {
        HStack(spacing: 12) {
            Image(systemName: "cart")
                .font(.body.weight(.semibold))
                .overlay(alignment: .topTrailing) {
                    if cart.count > 0 {
                        Text("\(cart.count)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(Brand.tint, in: Capsule())
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
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .frame(height: 56)
        .glassEffect(.regular, in: Capsule())
    }

    private var checkoutCapsule: some View {
        Button(action: onTap) {
            Label("pos.cart.checkout", systemImage: "chevron.right")
                .labelStyle(.titleAndIcon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(height: 56)
                .background(Brand.tint, in: Capsule())
                .glassEffect(.regular.tint(Brand.tint).interactive(), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(cart.lines.isEmpty)
    }
}
