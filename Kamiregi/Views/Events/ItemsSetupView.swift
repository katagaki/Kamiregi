import SwiftUI
import SwiftData

struct ItemsSetupView: View {
    @Environment(\.modelContext) private var context
    @Bindable var event: Event
    @Bindable var day: EventDay
    @State private var selectedDayID: PersistentIdentifier?
    @State private var showAddItem = false
    @State private var editingItem: InventoryItem?
    @State private var searchText = ""

    var body: some View {
        Form {
            Section {
                Picker("items.day", selection: $selectedDayID) {
                    ForEach(event.sortedDays, id: \.persistentModelID) { dayEntry in
                        Text(dayEntry.label).tag(dayEntry.persistentModelID as PersistentIdentifier?)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            Section {
                ForEach(filteredItems, id: \.id) { item in
                    Button {
                        editingItem = item
                    } label: {
                        ItemSetupRow(item: item, day: activeDay)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { indexSet in
                    for idx in indexSet { delete(filteredItems[idx]) }
                }
                Button {
                    showAddItem = true
                } label: {
                    Label("items.add", systemImage: "plus")
                }
                Button {
                    copyFromPreviousDay()
                } label: {
                    Label("items.copy.previous", systemImage: "arrow.counterclockwise")
                }
                .disabled(!hasPreviousDay)
            } header: {
                Text("items.section.title")
            } footer: {
                Text("items.section.footer")
            }
        }
        .navigationTitle("items.title")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: Text("items.search.prompt"))
        .toolbar {
            DefaultToolbarItem(kind: .search, placement: .bottomBar)
            ToolbarSpacer(.fixed, placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                Button("common.add", systemImage: "plus") { showAddItem = true }
                    .buttonBorderShape(.circle)
                    .buttonStyle(.glassProminent)
            }
        }
        .sheet(isPresented: $showAddItem) {
            AddItemSheet(event: event)
        }
        .sheet(item: $editingItem) { item in
            EditItemSheet(item: item, day: activeDay)
        }
        .onAppear {
            if selectedDayID == nil { selectedDayID = day.persistentModelID }
        }
    }

    private var filteredItems: [InventoryItem] {
        let sorted = event.items.sorted(by: { $0.sortIndex < $1.sortIndex })
        guard !searchText.isEmpty else { return sorted }
        let query = searchText.lowercased()
        return sorted.filter { $0.name.lowercased().contains(query) || $0.sub.lowercased().contains(query) }
    }

    private var activeDay: EventDay {
        event.sortedDays.first { $0.persistentModelID == selectedDayID } ?? day
    }

    private var hasPreviousDay: Bool {
        let sorted = event.sortedDays
        guard let idx = sorted.firstIndex(where: { $0.persistentModelID == activeDay.persistentModelID }) else { return false }
        return idx > 0
    }

    private func delete(_ item: InventoryItem) {
        event.items.removeAll { $0.id == item.id }
        context.delete(item)
        try? context.save()
    }

    private func copyFromPreviousDay() {
        let sorted = event.sortedDays
        guard let idx = sorted.firstIndex(where: { $0.persistentModelID == activeDay.persistentModelID }),
              idx > 0 else { return }
        let previousDay = sorted[idx - 1]
        for item in event.items {
            guard let prevStock = item.stock(on: previousDay) else { continue }
            if let existing = item.stock(on: activeDay) {
                existing.initial = prevStock.initial
            } else {
                let stock = DailyStock(initial: prevStock.initial)
                stock.item = item
                stock.day = activeDay
                context.insert(stock)
            }
        }
    }
}
