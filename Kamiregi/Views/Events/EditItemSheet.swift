import SwiftUI
import SwiftData
import PhotosUI

struct EditItemSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: InventoryItem
    var day: EventDay

    @State private var name: String
    @State private var sub: String
    @State private var price: Int
    @State private var photoData: Data?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var stockInitial: Int

    init(item: InventoryItem, day: EventDay) {
        self.item = item
        self.day = day
        _name = State(initialValue: item.name)
        _sub = State(initialValue: item.sub)
        _price = State(initialValue: item.price)
        _photoData = State(initialValue: item.photoData)
        _stockInitial = State(initialValue: item.stock(on: day)?.initial ?? 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("item.add.photo") {
                    HStack(spacing: 16) {
                        ItemThumbnail(name: name.isEmpty ? "?" : name, photoData: photoData, size: 56, cornerRadius: 14)
                        PhotosPicker(selection: $photosPickerItem, matching: .images) {
                            Label("item.add.photo.choose", systemImage: "photo")
                        }
                        if photoData != nil {
                            Button(role: .destructive) {
                                photoData = nil
                                photosPickerItem = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: photosPickerItem) { _, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            photoData = data
                        }
                    }
                }

                Section("item.add.name") {
                    TextField("item.add.name.placeholder", text: $name)
                }

                Section("item.add.sub") {
                    TextField("item.add.sub.placeholder", text: $sub, axis: .vertical)
                        .lineLimit(1...2)
                }

                Section("item.add.price") {
                    TextField("0", value: $price, format: .number)
                        .keyboardType(.numberPad)
                }

                Section("item.edit.stock") {
                    TextField("0", value: $stockInitial, format: .number)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("item.edit.title")
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
        item.name = name.trimmingCharacters(in: .whitespaces)
        item.sub = sub.trimmingCharacters(in: .whitespaces)
        item.price = price
        item.photoData = photoData
        if let stock = item.stock(on: day) {
            stock.initial = stockInitial
        } else if stockInitial > 0 {
            let stock = DailyStock(initial: stockInitial)
            stock.item = item
            stock.day = day
            context.insert(stock)
        }
        try? context.save()
        dismiss()
    }
}
