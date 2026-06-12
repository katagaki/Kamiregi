import SwiftUI
import SwiftData

struct TransactionsView: View {
    @AppStorage("currency") private var currency: Currency = .yen
    @Bindable var event: Event
    @Bindable var day: EventDay
    var body: some View {
        Group {
            if day.transactions.isEmpty {
                ContentUnavailableView(
                    "transactions.title",
                    systemImage: "doc.text",
                    description: Text("transactions.empty")
                )
            } else {
                List {
                    Section {
                        LabeledContent("event.detail.revenue") {
                            Text(currency.format(totalRevenue))
                                .font(.title3.weight(.bold))
                                .monospacedDigit()
                                .foregroundStyle(Brand.tint)
                        }
                        LabeledContent("event.detail.transactions") {
                            Text("\(day.transactions.count)").monospacedDigit()
                        }
                        LabeledContent("transactions.items.sold") {
                            Text("\(totalItems)").monospacedDigit()
                        }
                    } header: {
                        Text("event.detail.today")
                    }

                    Section("transactions.title") {
                        ForEach(sortedTransactions, id: \.persistentModelID) { transaction in
                            NavigationLink(value: transaction.persistentModelID) {
                                TransactionRow(transaction: transaction)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("transactions.title")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: PersistentIdentifier.self) { id in
            if let tx = day.transactions.first(where: { $0.persistentModelID == id }) {
                TransactionDetailView(transaction: tx)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    TxBreakdownView(event: event, day: day)
                } label: {
                    Label("transactions.breakdown.title", systemImage: "chart.bar")
                }
            }
        }
    }

    private var totalRevenue: Int { day.transactions.reduce(0) { $0 + $1.total } }
    private var totalItems: Int { day.transactions.reduce(0) { $0 + $1.itemCount } }

    private var sortedTransactions: [SaleTransaction] {
        day.transactions.sorted { $0.timestamp > $1.timestamp }
    }
}

private struct TransactionDetailView: View {
    @AppStorage("currency") private var currency: Currency = .yen
    var transaction: SaleTransaction

    var body: some View {
        Form {
            Section("transactions.title") {
                ForEach(transaction.lines, id: \.id) { line in
                    LabeledContent {
                        Text(currency.format(line.subtotal)).monospacedDigit()
                    } label: {
                        Text("\(line.itemName) × \(line.qty)")
                    }
                }
            }
            Section {
                LabeledContent("pos.cart.total") {
                    Text(currency.format(transaction.total)).monospacedDigit()
                }
            }
        }
        .navigationTitle(titleLabel)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var titleLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "#\(String(format: "%03d", transaction.number)) · \(formatter.string(from: transaction.timestamp))"
    }
}
