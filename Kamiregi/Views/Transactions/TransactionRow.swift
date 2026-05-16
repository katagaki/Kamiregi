import SwiftUI
import SwiftData

struct TransactionRow: View {
    var transaction: SaleTransaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.title3)
                .foregroundStyle(Brand.tint)
                .frame(width: 38, height: 38)
                .background(Brand.tintDim, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text("#\(String(format: "%03d", transaction.number)) · \(transaction.itemCount)点")
                    .font(.body.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(yen(transaction.total))
                    .font(.body.weight(.bold))
                    .monospacedDigit()
                if transaction.change > 0 {
                    Text("\(timeLabel) · \(yen(transaction.change))")
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
