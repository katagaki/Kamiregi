import SwiftUI
import SwiftData

struct TransactionRow: View {
    var tx: SaleTransaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.title3)
                .foregroundStyle(UC.tint)
                .frame(width: 38, height: 38)
                .background(UC.tintDim, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text("#\(String(format: "%03d", tx.number)) · \(tx.itemCount)点")
                    .font(.body.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(yen(tx.total))
                    .font(.body.weight(.bold))
                    .monospacedDigit()
                if tx.change > 0 {
                    Text("\(timeLabel) · \(yen(tx.change))")
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var timeLabel: String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.string(from: tx.timestamp)
    }

    private var detail: String {
        tx.lines.prefix(3).map { "\($0.itemName) ×\($0.qty)" }.joined(separator: " · ")
    }
}
