import SwiftUI
import SwiftData

struct ItemsSetupView: View {
    @Environment(\.modelContext) private var context
    @Bindable var event: Event
    @Bindable var day: EventDay
    @State private var selectedDayID: PersistentIdentifier?

    var body: some View {
        Form {
            Section {
                Picker("items.day", selection: $selectedDayID) {
                    ForEach(event.sortedDays, id: \.persistentModelID) { d in
                        Text(d.label).tag(d.persistentModelID as PersistentIdentifier?)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            Section {
                ForEach(event.items.sorted(by: { $0.sortIndex < $1.sortIndex }), id: \.id) { item in
                    ItemSetupRow(item: item, day: activeDay)
                }
                Button {
                } label: {
                    Label("items.add", systemImage: "plus")
                }
                Button {
                } label: {
                    Label("items.copy.previous", systemImage: "arrow.counterclockwise")
                }
            } header: {
                Text("items.section.title")
            } footer: {
                Text("items.section.footer")
            }
        }
        .navigationTitle("items.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { } label: { Image(systemName: "plus") }
            }
        }
        .onAppear {
            if selectedDayID == nil { selectedDayID = day.persistentModelID }
        }
    }

    private var activeDay: EventDay {
        event.sortedDays.first { $0.persistentModelID == selectedDayID } ?? day
    }
}
