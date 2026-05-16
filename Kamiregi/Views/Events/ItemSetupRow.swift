import SwiftData
import SwiftUI

struct ItemSetupRow: View {
    @Environment(\.modelContext) private var context
    @Bindable var item: InventoryItem
    @Bindable var day: EventDay

    var body: some View {
        HStack(spacing: 12) {
            Text(item.emoji)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(item.swatch, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                Text("\(item.sub) · \(item.price > 0 ? yen(item.price) : String(localized: "items.free"))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Stepper(value: initialBinding, in: 0...9_999) {
                Text("\(initialBinding.wrappedValue)")
                    .monospacedDigit()
                    .font(.body.weight(.semibold))
            }
            .labelsHidden()
        }
        .padding(.vertical, 2)
    }

    private var initialBinding: Binding<Int> {
        Binding(
            get: { item.stock(on: day)?.initial ?? 0 },
            set: { newValue in
                if let stock = item.stock(on: day) {
                    stock.initial = newValue
                } else {
                    let stock = DailyStock(initial: newValue)
                    stock.item = item
                    stock.day = day
                    context.insert(stock)
                }
            }
        )
    }
}
