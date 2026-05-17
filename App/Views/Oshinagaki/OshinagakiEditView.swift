import SwiftUI
import SwiftData
import PhotosUI

struct OshinagakiEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var event: Event
    @Bindable var day: EventDay

    @State private var photosPick: PhotosPickerItem?
    @State private var selectedItemID: PersistentIdentifier?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                OshinagakiEditCanvas(
                    imageData: event.oshinagakiImage,
                    items: event.items,
                    selectedItemID: $selectedItemID
                )
                .padding(.horizontal)
                .padding(.top)

                Divider().padding(.top, 12)

                itemPicker
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("oshinagaki.edit.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(selection: $photosPick, matching: .images) {
                        Label("oshinagaki.edit.image.change", systemImage: "photo")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("oshinagaki.edit.region.delete", systemImage: "trash", role: .destructive) {
                            deleteSelectedRegion()
                        }
                        .disabled(selectedItemID == nil)
                        Button("oshinagaki.edit.clear", systemImage: "trash.slash", role: .destructive) {
                            clearAllRegions()
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") {
                        try? context.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: photosPick) { _, newValue in
                Task { await loadPhoto(newValue) }
            }
        }
    }

    private var itemPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(event.items.sorted(by: { $0.sortIndex < $1.sortIndex }), id: \.persistentModelID) { item in
                    Button {
                        selectItem(item)
                    } label: {
                        VStack(spacing: 4) {
                            ZStack(alignment: .bottomTrailing) {
                                ItemThumbnail(name: item.name, photoData: item.photoData, size: 56, cornerRadius: 12)
                                if item.hasRegion {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.white, .green)
                                        .background(Color(.systemBackground), in: Circle())
                                        .offset(x: 4, y: 4)
                                }
                            }
                            Text(item.name)
                                .font(.caption2)
                                .lineLimit(1)
                                .frame(maxWidth: 70)
                        }
                        .padding(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(selectedItemID == item.persistentModelID ? Brand.tint : .clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            await MainActor.run {
                event.oshinagakiImage = data
                try? context.save()
            }
        }
    }

    private func selectItem(_ item: InventoryItem) {
        if !item.hasRegion {
            item.regionRect = CGRect(x: 0.35, y: 0.4, width: 0.30, height: 0.20)
        }
        selectedItemID = item.persistentModelID
    }

    private func deleteSelectedRegion() {
        guard let id = selectedItemID,
              let item = event.items.first(where: { $0.persistentModelID == id }) else { return }
        item.regionRect = .zero
        selectedItemID = nil
    }

    private func clearAllRegions() {
        for item in event.items { item.regionRect = .zero }
        selectedItemID = nil
    }
}
