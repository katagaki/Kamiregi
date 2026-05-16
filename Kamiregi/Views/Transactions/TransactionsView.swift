import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Bindable var event: Event
    @Bindable var day: EventDay
    @State private var searchText = ""

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
                                .foregroundStyle(UC.tint)
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
                        ForEach(filteredTransactions, id: \.persistentModelID) { tx in
                            NavigationLink(value: tx.persistentModelID) {
                                TransactionRow(tx: tx)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("transactions.title")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: Text("transactions.search.prompt"))
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
                    Button("transactions.export.csv", systemImage: "square.and.arrow.up") { }
                    Button("transactions.export.pdf", systemImage: "doc") { }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
    }

    private var totalRevenue: Int { day.transactions.reduce(0) { $0 + $1.total } }
    private var totalItems: Int { day.transactions.reduce(0) { $0 + $1.itemCount } }

    private var filteredTransactions: [SaleTransaction] {
        let txs = day.transactions.sorted { $0.timestamp > $1.timestamp }
        guard !searchText.isEmpty else { return txs }
        let q = searchText.lowercased()
        return txs.filter { tx in
            tx.lines.contains { $0.itemName.lowercased().contains(q) }
                || "#\(tx.number)".contains(q)
        }
    }
}
