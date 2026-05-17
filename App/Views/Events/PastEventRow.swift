import SwiftUI

struct PastEventRow: View {
    var event: Event

    var body: some View {
        LabeledContent {
            Text(yen(event.sortedDays.reduce(0) { $0 + $1.revenue }))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.name)
                Text(dateText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "ja_JP")
        let day = event.sortedDays.first?.date ?? Date()
        return "\(formatter.string(from: day)) · 完了"
    }
}
