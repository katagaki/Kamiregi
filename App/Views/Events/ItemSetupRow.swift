import SwiftData
import SwiftUI

struct ItemSetupRow: View {
    var item: InventoryItem
    var day: EventDay

    var body: some View {
        HStack(spacing: 12) {
            ItemThumbnail(name: item.name, photoData: item.photoData, size: 40, cornerRadius: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                Text("\(item.sub) · \(item.price > 0 ? yen(item.price) : String(localized: "items.free"))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text("\(item.stock(on: day)?.initial ?? 0)")
                .monospacedDigit()
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
