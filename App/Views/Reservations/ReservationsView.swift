import SwiftUI
import SwiftData

struct ReservationsView: View {
    @Environment(\.horizontalSizeClass) private var hSize
    @Bindable var event: Event
    @Bindable var day: EventDay
    @State private var filter: PickupFilter = .pending
    @State private var showAdd = false
    @State private var editing: Reservation?
    @State private var searchText = ""

    enum PickupFilter: Hashable, CaseIterable {
        case pending, done, all

        var labelKey: LocalizedStringKey {
            switch self {
            case .pending: "reservations.filter.pending"
            case .done:    "reservations.filter.done"
            case .all:     "reservations.filter.all"
            }
        }
    }

    var body: some View {
        Group {
            if filtered.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else if filtered.isEmpty {
                ContentUnavailableView(
                    "reservations.empty.title",
                    systemImage: "person.2",
                    description: Text("reservations.empty.description")
                )
            } else {
                List {
                    ForEach(filtered, id: \.id) { res in
                        ReservationRow(res: res) { editing = res }
                    }
                }
            }
        }
        .navigationTitle("reservations.title")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: Text("reservations.search.prompt"))
        .toolbar {
            if hSize == .regular {
                ToolbarItem(placement: .topBarTrailing) { filterMenu }
                ToolbarItem(placement: .topBarTrailing) { addButton }
            } else {
                ToolbarItem(placement: .bottomBar) { filterMenu }
                ToolbarSpacer(.fixed, placement: .bottomBar)
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                ToolbarSpacer(.fixed, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    addButton
                        .buttonBorderShape(.circle)
                        .buttonStyle(.glassProminent)
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            ReservationSheet(event: event, day: day)
        }
        .sheet(item: $editing) { res in
            ReservationSheet(event: event, day: day, reservation: res)
        }
    }

    private var filterMenu: some View {
        Menu("reservations.filter", systemImage: "line.3.horizontal.decrease") {
            Picker("reservations.filter", selection: $filter) {
                Label("reservations.filter.pending", systemImage: "clock").tag(PickupFilter.pending)
                Label("reservations.filter.done", systemImage: "checkmark.circle").tag(PickupFilter.done)
                Label("reservations.filter.all", systemImage: "list.bullet").tag(PickupFilter.all)
            }
            .pickerStyle(.inline)
            .labelsVisibility(.visible)
        }
    }

    private var addButton: some View {
        Button { showAdd = true } label: {
            Label("reservations.add", systemImage: "plus")
        }
    }

    private var allCount: Int { day.reservations.count }
    private var pendingCount: Int { day.reservations.filter { !$0.pickedUp }.count }
    private var pickedCount: Int { day.reservations.filter { $0.pickedUp }.count }

    private var filtered: [Reservation] {
        let sorted = day.reservations.sorted { $0.createdAt < $1.createdAt }
        let scope: [Reservation] = {
            switch filter {
            case .pending: return sorted.filter { !$0.pickedUp }
            case .done:    return sorted.filter {  $0.pickedUp }
            case .all:     return sorted
            }
        }()
        guard !searchText.isEmpty else { return scope }
        let query = searchText.lowercased()
        return scope.filter {
            $0.name.lowercased().contains(query)
                || $0.handle.lowercased().contains(query)
                || $0.note.lowercased().contains(query)
                || $0.lines.contains { $0.displayName.lowercased().contains(query) }
        }
    }
}
