import SwiftUI
import SwiftData

struct ConfirmedSheet: View {
    var transaction: SaleTransaction
    var paid: Int
    var onDone: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 72))
                                .foregroundStyle(.green)
                            Text("payment.thank_you")
                                .font(.title2.weight(.semibold))
                            Text(timeLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
                .listRowBackground(Color.clear)

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
                        Text(yen(paid)).monospacedDigit()
                    }
                    LabeledContent("payment.change") {
                        Text(yen(transaction.change))
                            .monospacedDigit()
                            .foregroundStyle(Brand.tint)
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("payment.thank_you")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        onDone()
                    } label: {
                        Text("payment.next").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
    }

    private var timeLabel: String {
        let formatter = DateFormatter(); formatter.dateFormat = "HH:mm"
        return "#\(String(format: "%03d", transaction.number)) · \(formatter.string(from: transaction.timestamp))"
    }
}
