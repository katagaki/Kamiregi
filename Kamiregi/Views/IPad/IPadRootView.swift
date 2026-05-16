import SwiftUI
import SwiftData

struct IPadRootView: View {
    @Query(sort: \Event.createdAt, order: .forward) private var events: [Event]
    @State private var selectedEventID: PersistentIdentifier?
    @State private var selectedDayID: PersistentIdentifier?
    @State private var section: IPadSection = .pos
    @State private var showAddEvent = false
    @State private var cart = CartStore()

    var body: some View {
        NavigationSplitView {
            IPadSidebar(
                selectedEventID: $selectedEventID,
                selectedDayID: $selectedDayID,
                section: $section,
                showAddEvent: $showAddEvent
            )
            .navigationSplitViewColumnWidth(min: 260, ideal: 280, max: 320)
        } detail: {
            NavigationStack { detail }
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showAddEvent) { AddEventSheet() }
        .onAppear { ensureSelection() }
        .onChange(of: events.count) { _, _ in ensureSelection() }
    }

    private func ensureSelection() {
        if selectedEventID == nil {
            if let first = events.first(where: { !$0.isPastEvent }) ?? events.first {
                selectedEventID = first.persistentModelID
                selectedDayID = first.sortedDays.first?.persistentModelID
            }
        }
    }

    private var currentEvent: Event? {
        events.first { $0.persistentModelID == selectedEventID }
    }

    private var currentDay: EventDay? {
        currentEvent?.sortedDays.first { $0.persistentModelID == selectedDayID }
    }

    @ViewBuilder
    private var detail: some View {
        if let event = currentEvent, let day = currentDay {
            switch section {
            case .pos:          IPadPOSView(event: event, day: day, cart: cart)
            case .oshinagaki:   IPadOshinagakiView(event: event, day: day, cart: cart)
            case .items:        ItemsSetupView(event: event, day: day)
            case .transactions: IPadTransactionsView(event: event, day: day)
            case .reservations: ReservationsView(event: event, day: day)
            }
        } else {
            ContentUnavailableView(
                "events.empty.title",
                systemImage: "calendar",
                description: Text("events.empty.description")
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddEvent = true } label: {
                        Label("events.add", systemImage: "plus")
                    }
                }
            }
        }
    }
}
