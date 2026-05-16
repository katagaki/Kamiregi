import SwiftUI
import SwiftData

enum IPadSection: Hashable, CaseIterable {
    case pos, oshinagaki, items, transactions, reservations
}

struct IPadSidebar: View {
    @Query(sort: \Event.createdAt, order: .forward) private var events: [Event]
    @Binding var selectedEventID: PersistentIdentifier?
    @Binding var selectedDayID: PersistentIdentifier?
    @Binding var section: IPadSection
    @Binding var showAddEvent: Bool
    @State private var searchText = ""

    var body: some View {
        List(selection: $selectedEventID) {
            Section("events.title") {
                ForEach(filteredEvents, id: \.persistentModelID) { event in
                    EventSidebarRow(event: event, isLive: isLive(event))
                        .tag(event.persistentModelID as PersistentIdentifier?)
                }
            }

            if let event = activeEvent, searchText.isEmpty {
                Section(event.name) {
                    ForEach(subNavRows(for: event), id: \.id) { row in
                        Button { section = row.id } label: {
                            Label {
                                Text(row.labelKey)
                                    .foregroundStyle(.primary)
                                    .fontWeight(section == row.id ? .semibold : .regular)
                            } icon: {
                                Image(systemName: row.icon)
                                    .foregroundStyle(section == row.id ? Brand.tint : .secondary)
                            }
                            .badge(row.badge ?? 0)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Ushio Cash")
        .searchable(text: $searchText, prompt: Text("common.search"))
        .onChange(of: selectedEventID) { _, newID in
            if let event = events.first(where: { $0.persistentModelID == newID }) {
                selectedDayID = event.sortedDays.first?.persistentModelID
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddEvent = true } label: {
                    Label("events.add", systemImage: "plus")
                }
            }
        }
    }

    private var activeEvent: Event? {
        events.first { $0.persistentModelID == selectedEventID }
    }

    private var activeDay: EventDay? {
        activeEvent?.sortedDays.first { $0.persistentModelID == selectedDayID }
    }

    private func isLive(_ event: Event) -> Bool {
        !event.isPastEvent && event == events.first(where: { !$0.isPastEvent })
    }

    private var filteredEvents: [Event] {
        guard !searchText.isEmpty else { return events }
        let query = searchText.lowercased()
        return events.filter {
            $0.name.lowercased().contains(query)
                || $0.venue.lowercased().contains(query)
                || $0.booth.lowercased().contains(query)
        }
    }

    private struct SubNavRow: Identifiable {
        let id: IPadSection
        let labelKey: LocalizedStringKey
        let icon: String
        let badge: Int?
    }

    private func subNavRows(for event: Event) -> [SubNavRow] {
        let txCount = activeDay?.transactions.count
        let resCount = activeDay?.reservations.count
        return [
            SubNavRow(id: .pos, labelKey: "event.detail.standard", icon: "cart", badge: nil),
            SubNavRow(id: .oshinagaki, labelKey: "event.detail.oshinagaki", icon: "photo", badge: nil),
            SubNavRow(id: .items, labelKey: "event.detail.items", icon: "bag", badge: event.items.count),
            SubNavRow(id: .transactions, labelKey: "event.detail.transactions.list", icon: "doc.text", badge: txCount),
            SubNavRow(id: .reservations, labelKey: "event.detail.reservations", icon: "person.2", badge: resCount)
        ]
    }
}

private struct EventSidebarRow: View {
    var event: Event
    var isLive: Bool

    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(event.color).frame(width: 8, height: 8)
            Text(event.name).lineLimit(1)
            Spacer(minLength: 0)
            if isLive {
                Text("events.live")
                    .font(.caption2.bold())
                    .foregroundStyle(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.18), in: Capsule())
            }
        }
    }
}
