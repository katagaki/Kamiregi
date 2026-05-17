import SwiftUI
import SwiftData

struct EventsListView: View {
    @Query(sort: \Event.createdAt, order: .forward) private var events: [Event]
    @State private var showAdd = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("events.title")
                .searchable(text: $searchText, prompt: Text("events.search.prompt"))
                .toolbarTitleDisplayMode(.inlineLarge)
                .toolbar {
                    DefaultToolbarItem(kind: .search, placement: .bottomBar)
                    ToolbarSpacer(.fixed, placement: .bottomBar)
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button {
                            showAdd = true
                        } label: {
                            Label("events.add", systemImage: "plus")
                        }
                        .buttonStyle(.glassProminent)
                        .buttonBorderShape(.circle)
                    }
                }
        }
        .sheet(isPresented: $showAdd) {
            AddEventSheet()
        }
    }

    @ViewBuilder
    private var content: some View {
        if events.isEmpty {
            EventsEmptyState(onAdd: { showAdd = true })
        } else if filteredActive.isEmpty && filteredPast.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            List {
                if !filteredActive.isEmpty {
                    Section("events.section.active") {
                        ForEach(filteredActive) { event in
                            NavigationLink(value: event) {
                                EventRow(event: event, isLive: event == events.first(where: { !$0.isPastEvent }))
                            }
                        }
                    }
                }
                if !filteredPast.isEmpty {
                    Section("events.section.past") {
                        ForEach(filteredPast) { event in
                            NavigationLink(value: event) {
                                PastEventRow(event: event)
                            }
                        }
                    }
                }
            }
            .navigationDestination(for: Event.self) { event in
                EventDetailView(event: event)
            }
        }
    }

    private var filteredActive: [Event] {
        let active = events.filter { !$0.isPastEvent }
        return matchSearch(active)
    }

    private var filteredPast: [Event] {
        let past = events.filter { $0.isPastEvent }
        return matchSearch(past)
    }

    private func matchSearch(_ src: [Event]) -> [Event] {
        guard !searchText.isEmpty else { return src }
        let query = searchText.lowercased()
        return src.filter {
            $0.name.lowercased().contains(query)
                || $0.venue.lowercased().contains(query)
                || $0.booth.lowercased().contains(query)
        }
    }
}
