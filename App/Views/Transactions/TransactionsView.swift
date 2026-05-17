import SwiftUI
import SwiftData

struct TransactionsView: View {
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
                            Text(yen(totalRevenue))
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
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ShareLink(item: exportCSV, subject: Text("transactions.export.csv")) {
                        Label("transactions.export.csv", systemImage: "tablecells")
                    }
                    .disabled(day.transactions.isEmpty)
                    Button("transactions.export.pdf", systemImage: "doc") { }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
    }

    private var totalRevenue: Int { day.transactions.reduce(0) { $0 + $1.total } }
    private var totalItems: Int { day.transactions.reduce(0) { $0 + $1.itemCount } }

    private var sortedTransactions: [SaleTransaction] {
        day.transactions.sorted { $0.timestamp > $1.timestamp }
    }

    private var exportCSV: String {
        var lines = ["#,日時,合計,受取,お釣り,内訳"]
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        for tx in day.transactions.sorted(by: { $0.number < $1.number }) {
            let items = tx.lines.map { "\($0.itemName) × \($0.qty)" }.joined(separator: " / ")
            lines.append("\(tx.number),\(fmt.string(from: tx.timestamp)),\(tx.total),\(tx.paid),\(tx.change),\"\(items)\"")
        }
        return lines.joined(separator: "\n")
    }
}

private struct TransactionDetailView: View {
    var transaction: SaleTransaction

    var body: some View {
        Form {
            Section("transactions.title") {
                ForEach(transaction.lines, id: \.id) { line in
                    LabeledContent {
                        Text(yen(line.subtotal)).monospacedDigit()
                    } label: {
                        Text("\(line.itemName) × \(line.qty)")
                    }
                }
            }
            Section {
                LabeledContent("pos.cart.total") {
                    Text(yen(transaction.total)).monospacedDigit()
                }
                LabeledContent("payment.received") {
                    Text(yen(transaction.paid)).monospacedDigit()
                }
                LabeledContent("payment.change") {
                    Text(yen(transaction.change))
                        .monospacedDigit()
                        .foregroundStyle(Brand.tint)
                        .fontWeight(.semibold)
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
