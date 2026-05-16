import SwiftUI

struct OshinagakiEditView: View {
    @Environment(\.dismiss) private var dismiss
    var regions: [TapRegion]
    @State private var tool: Tool = .rectangle

    enum Tool: Hashable {
        case rectangle, freeform
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("oshinagaki.edit.tool", selection: $tool) {
                    Label("oshinagaki.edit.tool.rect", systemImage: "rectangle.dashed").tag(Tool.rectangle)
                    Label("oshinagaki.edit.tool.free", systemImage: "pencil.tip").tag(Tool.freeform)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                OshinagakiCanvas(regions: regions, editing: true)
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("oshinagaki.edit.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("oshinagaki.edit.image.change", systemImage: "photo") { }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}
