import SwiftUI
import SwiftData
import PhotosUI

struct AddItemSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var event: Event

    @State private var name: String = ""
    @State private var sub: String = ""
    @State private var price: Int = 0
    @State private var photoData: Data?
    @State private var photosPickerItem: PhotosPickerItem?

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
            photoData: photoData,
            sortIndex: nextSort
        )
        item.event = event
        event.items.append(item)
        context.insert(item)
        try? context.save()
        dismiss()
    }
}
