import SwiftUI
import SwiftData

struct AddEventSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = "コミティア150"
    @State private var venue: String = "東京ビッグサイト"
    @State private var booth: String = "え-21b"
    @State private var selectedColor: String = Brand.paletteSwatches[0]
    @State private var draftDays: [DraftDay] = [
        DraftDay(date: Self.date(year: 2026, month: 5, day: 5), label: "初日"),
        DraftDay(date: Self.date(year: 2026, month: 5, day: 6), label: "2日目")
    ]

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
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 8), spacing: 12) {
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
            .navigationTitle("event.add.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let event = Event(name: name, venue: venue, booth: booth, colorHex: selectedColor)
        for draft in draftDays {
            let day = EventDay(date: draft.date, label: draft.label)
            event.days.append(day)
        }
        context.insert(event)
        try? context.save()
        dismiss()
    }

    private static func date(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}

private struct DraftDay: Identifiable {
    let id = UUID()
    var date: Date
    var label: String
}
