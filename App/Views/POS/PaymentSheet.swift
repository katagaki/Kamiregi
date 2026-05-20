import SwiftUI
import SwiftData

struct PaymentSheet: View {
    @AppStorage("currency") private var currency: Currency = .yen
    @AppStorage("showReceiptScreen") private var showReceiptScreen = true
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
                        Text(currency.format(cart.subtotal))
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
                        Button {
                            paid = 0
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .opacity(paid == 0 ? 0 : 1)
                        .disabled(paid == 0)
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(quickAmounts, id: \.self) { amount in
                            Button {
                                paid += amount
                            } label: {
                                Text(currency.format(amount))
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                            .tint(Brand.tint)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section {
                    LabeledContent("payment.change") {
                        Text(currency.format(change))
                            .font(.largeTitle.weight(.bold))
                            .monospacedDigit()
                            .foregroundStyle(Brand.tint)
                    }
                }
            }
            .navigationTitle("payment.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }
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
                if let transaction = confirmedTx {
                    ConfirmedSheet(transaction: transaction, paid: paid) {
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
        let transaction = SaleTransaction(
            number: cart.transactionNumber,
            timestamp: Date(),
            total: cart.subtotal,
            paid: paid
        )
        transaction.day = day
        for line in cart.lines {
            let txLine = TransactionLine(itemName: line.name, qty: line.qty, unitPrice: line.price)
            transaction.lines.append(txLine)
            context.insert(txLine)
        }
        context.insert(transaction)
        for line in cart.lines {
            if let id = line.itemID,
               let item = event.items.first(where: { $0.persistentModelID == id }),
               let stock = item.stock(on: day) {
                stock.sold += line.qty
            }
        }
        try? context.save()
        cart.transactionNumber += 1
        if showReceiptScreen {
            confirmedTx = transaction
            showConfirmed = true
        } else {
            cart.clear()
            paid = 0
            onConfirmed()
        }
    }
}
