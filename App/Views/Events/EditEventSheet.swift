import SwiftUI
import SwiftData

struct EditEventSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var event: Event

    @State private var name: String
    @State private var venue: String
    @State private var booth: String
    @State private var selectedColor: String
    @State private var draftDays: [DraftDay]

    init(event: Event) {
        self.event = event
        _name = State(initialValue: event.name)
        _venue = State(initialValue: event.venue)
        _booth = State(initialValue: event.booth)
        _selectedColor = State(initialValue: event.colorHex)
        _draftDays = State(initialValue: event.sortedDays.map {
            DraftDay(date: $0.date, label: $0.label, existing: $0)
        })
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
                Section("event.add.days") {
                    ForEach($draftDays) { $draft in
                        HStack {
                            DatePicker(draft.label, selection: $draft.date, displayedComponents: .date)
                            Button(role: .destructive) {
                                draftDays.removeAll { $0.id == draft.id }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.borderless)
                            .disabled(hasRecords(draft))
                        }
                    }
                    Button {
                        let last = draftDays.last?.date ?? Date()
                        let next = last.addingTimeInterval(86400)
                        draftDays.append(DraftDay(date: next, label: "\(draftDays.count + 1)日目"))
                    } label: {
                        Label("event.add.day.add", systemImage: "plus")
                    }
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

    // Days with sales data can't be removed; deleting would cascade their transactions
    private func hasRecords(_ draft: DraftDay) -> Bool {
        guard let day = draft.existing else { return false }
        return !day.transactions.isEmpty || !day.reservations.isEmpty
    }

    private func save() {
        event.name = name.trimmingCharacters(in: .whitespaces)
        event.venue = venue.trimmingCharacters(in: .whitespaces)
        event.booth = booth.trimmingCharacters(in: .whitespaces)
        event.colorHex = selectedColor

        let removed = event.days.filter { day in
            !draftDays.contains { $0.existing === day }
        }
        for day in removed {
            context.delete(day)
        }
        for draft in draftDays {
            if let day = draft.existing {
                day.date = draft.date
            } else {
                event.days.append(EventDay(date: draft.date, label: draft.label))
            }
        }
        try? context.save()
        dismiss()
    }
}

private struct DraftDay: Identifiable {
    let id = UUID()
    var date: Date
    var label: String
    var existing: EventDay?
}
