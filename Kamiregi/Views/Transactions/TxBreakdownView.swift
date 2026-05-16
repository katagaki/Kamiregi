import SwiftUI
import SwiftData

struct TxBreakdownView: View {
    @Bindable var event: Event
    @Bindable var day: EventDay

    var body: some View {
        Group {
            if items.isEmpty {
                ContentUnavailableView(
                    "transactions.breakdown.title",
                    systemImage: "chart.bar",
                    description: Text("transactions.empty")
                )
            } else {
                List {
                    Section {
                        LabeledContent("event.detail.revenue") {
                            Text(yen(day.revenue))
                                .font(.title3.weight(.bold))
                                .monospacedDigit()
                                .foregroundStyle(UC.tint)
                        }
                        LabeledContent("transactions.items.sold") {
                            Text("\(day.soldCount)").monospacedDigit()
                        }
                        LabeledContent("event.detail.stock.remaining") {
                            Text("\(day.stockLeft)").monospacedDigit()
                        }
                    }
                    Section("transactions.breakdown.title") {
                        ForEach(items, id: \.id) { item in
                            BreakdownRow(item: item, day: day)
                        }
                    }
                }
            }
        }
        .navigationTitle("transactions.breakdown.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var items: [InventoryItem] {
        event.items
            .filter { ($0.stock(on: day)?.sold ?? 0) > 0 }
            .sorted { ($0.stock(on: day)?.sold ?? 0) > ($1.stock(on: day)?.sold ?? 0) }
    }
}
