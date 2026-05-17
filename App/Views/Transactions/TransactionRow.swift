import SwiftUI
import SwiftData

struct TransactionRow: View {
    @AppStorage("currency") private var currency: Currency = .yen
    var transaction: SaleTransaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.title3)
                .foregroundStyle(Brand.tint)
                .frame(width: 38, height: 38)
                .background(Brand.tintDim, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(timeLabel)
                    .font(.body.weight(.semibold))
                    .monospacedDigit()
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(currency.format(transaction.total))
                    .font(.body.weight(.bold))
                    .monospacedDigit()
                if transaction.change > 0 {
                    Text(currency.format(transaction.change))
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: transaction.timestamp)
    }

    private var detail: String {
        transaction.lines.prefix(3).map { "\($0.itemName) ×\($0.qty)" }.joined(separator: " · ")
    }
}
