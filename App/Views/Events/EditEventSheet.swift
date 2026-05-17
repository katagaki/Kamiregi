import SwiftUI
import SwiftData

struct EditEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var event: Event

    @State private var name: String
    @State private var venue: String
    @State private var booth: String
    @State private var selectedColor: String

    init(event: Event) {
        self.event = event
        _name = State(initialValue: event.name)
        _venue = State(initialValue: event.venue)
        _booth = State(initialValue: event.booth)
        _selectedColor = State(initialValue: event.colorHex)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("event.add.name") {
                    TextField("event.add.name.placeholder", text: $name)
                }
                Section("event.add.location") {
                    TextField("event.add.venue.placeholder", text: $venue)
                    TextField("event.add.booth.placeholder", text: $booth)
                }
                Section("event.add.color") {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 8),
                        spacing: 12
                    ) {
                        ForEach(Brand.paletteSwatches, id: \.self) { hex in
                            Button {
                                selectedColor = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color(hex: hex), lineWidth: 2)
                                            .padding(-3)
                                            .opacity(selectedColor == hex ? 1 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("event.edit.title")
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
        event.name = name.trimmingCharacters(in: .whitespaces)
        event.venue = venue.trimmingCharacters(in: .whitespaces)
        event.booth = booth.trimmingCharacters(in: .whitespaces)
        event.colorHex = selectedColor
        dismiss()
    }
}
