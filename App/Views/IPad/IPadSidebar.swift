import SwiftUI
import SwiftData

enum IPadSection: Hashable, CaseIterable {
    case register, items, transactions, reservations
}

struct IPadSidebar: View {
    @Query(sort: \Event.createdAt, order: .forward) private var events: [Event]
    @Binding var selectedEventID: PersistentIdentifier?
    @Binding var selectedDayID: PersistentIdentifier?
    @Binding var section: IPadSection
    @Binding var showAddEvent: Bool
    @State private var searchText = ""
    @State private var expandedEventID: PersistentIdentifier?

    var body: some View {
        List {
            Section("events.title") {
                ForEach(filteredEvents, id: \.persistentModelID) { event in
                    DisclosureGroup(isExpanded: expansion(for: event)) {
                        ForEach(subNavRows(for: event), id: \.id) { row in
                            let isCurrent = section == row.id
                                && selectedEventID == event.persistentModelID
                            Button {
                                selectedEventID = event.persistentModelID
                                section = row.id
                            } label: {
                                Label {
                                    Text(row.labelKey)
                                        .foregroundStyle(.primary)
                                        .fontWeight(isCurrent ? .semibold : .regular)
                                } icon: {
                                    Image(systemName: row.icon)
                                        .foregroundStyle(isCurrent ? Brand.tint : .secondary)
                                }
                                .badge(row.badge ?? 0)
                            }
                            .buttonStyle(.plain)
                        }
                    } label: {
                        EventSidebarRow(event: event, isLive: event.isLive)
                            .contextMenu {
                                ExportMenu(event: event, currentDay: exportDay(for: event))
                            }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $searchText, prompt: Text("common.search"))
        .onChange(of: selectedEventID) { _, newID in
            if let event = events.first(where: { $0.persistentModelID == newID }) {
                selectedDayID = event.sortedDays.first?.persistentModelID
            }
        }
        .onAppear {
            if expandedEventID == nil { expandedEventID = selectedEventID }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SettingsMenu()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddEvent = true } label: {
                    Label("events.add", systemImage: "plus")
                }
            }
        }
    }

    // Tapping an event toggles its expansion; only a sub-nav button navigates.
    private func expansion(for event: Event) -> Binding<Bool> {
        Binding(
            get: { expandedEventID == event.persistentModelID },
            set: { expanded in
                expandedEventID = expanded ? event.persistentModelID : nil
            }
        )
    }

    private var activeEvent: Event? {
        events.first { $0.persistentModelID == selectedEventID }
    }

    private var activeDay: EventDay? {
        activeEvent?.sortedDays.first { $0.persistentModelID == selectedDayID }
    }

    // CSV exports the selected day; falls back to the event's first day for non-active rows.
    private func exportDay(for event: Event) -> EventDay? {
        event.persistentModelID == selectedEventID ? activeDay : nil
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
        let day = event.persistentModelID == selectedEventID ? activeDay : event.sortedDays.first
        let txCount = day?.transactions.count
        let resCount = day?.reservations.count
        return [
            SubNavRow(id: .register, labelKey: "pos.title", icon: "cart", badge: nil),
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
        .contentShape(Rectangle())
    }
}
