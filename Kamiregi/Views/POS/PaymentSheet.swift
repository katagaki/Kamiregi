import SwiftUI
import SwiftData

struct PaymentSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var cart: CartStore
    @Bindable var event: Event
    @Bindable var day: EventDay
    var onConfirmed: () -> Void

    @State private var paid: Int = 0
    @State private var confirmedTx: SaleTransaction?
    @State private var showConfirmed = false

    private let quickAmounts = [1000, 2000, 3000, 4000, 5000, 10000]

    var change: Int { max(0, paid - cart.subtotal) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("pos.cart.total") {
                        Text(yen(cart.subtotal))
                            .font(.title.weight(.bold))
                            .monospacedDigit()
                    }
                }

                Section("payment.received") {
                    HStack {
                        Text("¥").foregroundStyle(.secondary)
                        TextField("0", value: $paid, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title.weight(.semibold))
                            .monospacedDigit()
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(quickAmounts, id: \.self) { amount in
                            Button {
                                paid = amount
                            } label: {
                                Text(yen(amount))
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                            .tint(paid == amount ? UC.tint : .secondary)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section {
                    LabeledContent("payment.change") {
                        Text(yen(change))
                            .font(.largeTitle.weight(.bold))
                            .monospacedDigit()
                            .foregroundStyle(UC.tint)
                    }
                }
            }
            .navigationTitle("payment.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        confirm()
                    } label: {
                        Text("payment.confirm").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(paid < cart.subtotal)
                }
            }
            .sheet(isPresented: $showConfirmed) {
                if let tx = confirmedTx {
                    ConfirmedSheet(transaction: tx, paid: paid) {
                        showConfirmed = false
                        confirmedTx = nil
                        cart.clear()
                        paid = 0
                        onConfirmed()
                    }
                }
            }
        }
    }

    private func confirm() {
        guard paid >= cart.subtotal else { return }
        let tx = SaleTransaction(
            number: cart.transactionNumber,
            timestamp: Date(),
            total: cart.subtotal,
            paid: paid
        )
        tx.day = day
        for line in cart.lines {
            let l = TransactionLine(itemName: line.name, qty: line.qty, unitPrice: line.price)
            tx.lines.append(l)
            context.insert(l)
        }
        context.insert(tx)
        for line in cart.lines {
            if let id = line.itemID,
               let item = event.items.first(where: { $0.persistentModelID == id }),
               let stock = item.stock(on: day) {
                stock.sold += line.qty
            }
        }
        try? context.save()
        cart.transactionNumber += 1
        confirmedTx = tx
        showConfirmed = true
    }
}
