import SwiftUI

struct POSCartBar: View {
    @Bindable var cart: CartStore
    var onCheckout: () -> Void
    @State private var isExpanded = false
    @State private var showCheckoutConfirm = false
    @State private var showClearConfirm = false

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(alignment: .bottom, spacing: 8) {
                totalCapsule
                checkoutCapsule
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .contentShape(Rectangle())
        .onTapGesture {}
        .onChange(of: cart.lines.isEmpty) { _, isEmpty in
            if isEmpty {
                withAnimation(.smooth.speed(2.0)) { isExpanded = false }
            }
        }
        .alert(
            "pos.cart.checkout.confirm.title",
            isPresented: $showCheckoutConfirm
        ) {
            Button("common.cancel", role: .cancel) {}
            Button("pos.cart.continue") { onCheckout() }
        }
        .alert(
            "pos.cart.clear.confirm.title",
            isPresented: $showClearConfirm
        ) {
            Button("common.cancel", role: .cancel) {}
            Button("common.delete", role: .destructive) { cart.clear() }
        } message: {
            Text("pos.cart.clear.confirm.message")
        }
    }

    private var totalCapsule: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 8) {
                ForEach(cart.lines) { line in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(line.name)
                            .font(.subheadline)
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            Button {
                                withAnimation(.smooth.speed(2.0)) { cart.decrement(line) }
                            } label: {
                                Image(systemName: line.qty == 1 ? "trash" : "minus")
                                    .font(.caption2.weight(.semibold))
                                    .frame(width: 22, height: 22)
                                    .background(.secondary.opacity(0.15), in: Circle())
                            }
                            .buttonStyle(.plain)
                            Text("\(line.qty)")
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                                .frame(minWidth: 18, alignment: .center)
                                .contentTransition(.numericText())
                                .animation(.smooth.speed(2.0), value: line.qty)
                            Button {
                                withAnimation(.smooth.speed(2.0)) { cart.increment(line) }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.caption2.weight(.semibold))
                                    .frame(width: 22, height: 22)
                                    .background(.secondary.opacity(0.15), in: Circle())
                            }
                            .buttonStyle(.plain)
                            Spacer(minLength: 6)
                            Text(yen(line.subtotal))
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.smooth.speed(2.0), value: line.subtotal)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 18)
            .frame(maxHeight: isExpanded ? .infinity : 0, alignment: .top)
            .fixedSize(horizontal: false, vertical: isExpanded)
            .clipped()
            .padding(.top, isExpanded ? 12 : 0)
            .padding(.bottom, isExpanded ? 8 : 0)
            .opacity(isExpanded ? 1 : 0)
            .animation(.smooth.speed(2.0), value: isExpanded)

            Divider()
                .padding(.horizontal, 18)
                .frame(height: isExpanded ? 1 : 0)
                .opacity(isExpanded ? 1 : 0)
                .animation(.smooth.speed(2.0), value: isExpanded)

            HStack(spacing: 12) {
                Image(systemName: "cart")
                    .font(.body.weight(.semibold))
                VStack(alignment: .leading, spacing: 0) {
                    Text("pos.cart.subtotal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text(yen(cart.subtotal))
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: cart.subtotal)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.up")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .opacity(cart.lines.isEmpty ? 0 : 1)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(.horizontal, 18)
            .frame(height: 56)
            .contentShape(.rect)
            .onTapGesture {
                guard !cart.lines.isEmpty else { return }
                withAnimation(.smooth.speed(2.0)) {
                    isExpanded.toggle()
                }
            }
        }
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 28))
        .contextMenu {
            Button("pos.cart.clear.all", systemImage: "trash", role: .destructive) {
                showClearConfirm = true
            }
            .disabled(cart.lines.isEmpty)
        }
    }

    private var checkoutCapsule: some View {
        Button {
            showCheckoutConfirm = true
        } label: {
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
