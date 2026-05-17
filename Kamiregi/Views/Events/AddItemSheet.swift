import SwiftUI
import SwiftData

struct AddItemSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var event: Event

    @State private var name: String = ""
    @State private var sub: String = ""
    @State private var price: Int = 0
    @State private var emoji: String = "📦"
    @State private var swatchHex: String = itemSwatches[0]

    var body: some View {
        NavigationStack {
            Form {
                Section("event.add.name") {
                    TextField("item.add.name.placeholder", text: $name)
                }

                Section("item.add.sub") {
                    TextField("item.add.sub.placeholder", text: $sub, axis: .vertical)
                        .lineLimit(1...2)
                }

                Section("item.add.emoji") {
                    TextField("", text: $emoji)
                        .onChange(of: emoji) { _, new in
                            guard new.count > 1 else { return }
                            emoji = String(new.prefix(1))
                        }
                }

                Section("item.add.price") {
                    TextField("0", value: $price, format: .number)
                        .keyboardType(.numberPad)
                }

                Section("item.add.color") {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 8),
                        spacing: 12
                    ) {
                        ForEach(Self.itemSwatches, id: \.self) { hex in
                            Button {
                                swatchHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color(hex: hex), lineWidth: 2)
                                            .padding(-3)
                                            .opacity(swatchHex == hex ? 1 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("item.add.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm, action: save)
                        .accessibilityLabel("common.save")
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let nextSort = (event.items.map(\.sortIndex).max() ?? -1) + 1
        let item = InventoryItem(
            name: name.trimmingCharacters(in: .whitespaces),
            sub: sub.trimmingCharacters(in: .whitespaces),
            price: price,
            emoji: emoji.isEmpty ? "📦" : String(emoji.prefix(1)),
            swatchHex: swatchHex,
            sortIndex: nextSort
        )
        item.event = event
        event.items.append(item)
        context.insert(item)
        try? context.save()
        dismiss()
    }

    static let itemSwatches = [
        "#FFE4DC", "#DFEEFF", "#E0F4E2", "#FFF4D6",
        "#FFE2EE", "#EBE3FF", "#FFE9CF", "#E6F4F1"
    ]
}
