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
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月"
        f.locale = Locale(identifier: "ja_JP")
        let day = event.sortedDays.first?.date ?? Date()
        return "\(f.string(from: day)) · 完了"
    }
}
