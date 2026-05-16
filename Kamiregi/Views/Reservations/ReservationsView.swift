import SwiftUI
import SwiftData

struct ReservationsView: View {
    @Bindable var event: Event
    @Bindable var day: EventDay
    @State private var filter: PickupFilter = .pending
    @State private var showAdd = false
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
                        ReservationRow(res: res)
                    }
                }
            }
        }
        .navigationTitle("reservations.title")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: Text("reservations.search.prompt"))
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("reservations.filter", selection: $filter) {
                    Text("reservations.filter.pending \(pendingCount)").tag(PickupFilter.pending)
                    Text("reservations.filter.done \(pickedCount)").tag(PickupFilter.done)
                    Text("reservations.filter.all \(allCount)").tag(PickupFilter.all)
                }
                .pickerStyle(.segmented)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: {
                    Label("reservations.add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddReservationSheet(event: event, day: day)
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
        let q = searchText.lowercased()
        return scope.filter {
            $0.name.lowercased().contains(q)
                || $0.handle.lowercased().contains(q)
                || $0.note.lowercased().contains(q)
        }
    }
}
