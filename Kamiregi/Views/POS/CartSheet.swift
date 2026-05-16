import SwiftUI
import SwiftData

struct CartSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var cart: CartStore
    @Bindable var event: Event
    @Bindable var day: EventDay
    @State private var showPayment = false

    var body: some View {
        NavigationStack {
            Group {
                if cart.lines.isEmpty {
                    ContentUnavailableView(
                        "pos.cart.title",
                        systemImage: "cart",
                        description: Text("pos.cart.subtotal")
                    )
                } else {
                    List {
                        Section {
                            ForEach(cart.lines) { line in
                                CartLineRow(line: line, cart: cart)
                            }
                        }

                        Section {
                            LabeledContent("pos.cart.total") {
                                Text(yen(cart.subtotal))
                                    .font(.title2.weight(.bold))
                                    .monospacedDigit()
                                    .foregroundStyle(Brand.tint)
                            }
                        }
                    }
                }
            }
            .navigationTitle("pos.cart.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("pos.cart.clear", role: .destructive) {
                        cart.clear()
                    }
                    .disabled(cart.lines.isEmpty)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showPayment = true
                    } label: {
                        Text("pos.cart.continue")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(cart.lines.isEmpty)
                }
            }
            .sheet(isPresented: $showPayment) {
                PaymentSheet(cart: cart, event: event, day: day, onConfirmed: {
                    showPayment = false
                    dismiss()
                })
            }
        }
    }
}
