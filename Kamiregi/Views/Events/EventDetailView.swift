import SwiftUI
import SwiftData

struct EventDetailView: View {
    @Bindable var event: Event
    @State private var selectedDayID: PersistentIdentifier?

    var body: some View {
        Form {
            Section {
                Picker("event.detail.day", selection: $selectedDayID) {
                    ForEach(event.sortedDays, id: \.persistentModelID) { day in
                        Text(day.label).tag(day.persistentModelID as PersistentIdentifier?)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            } header: {
                Text("event.detail.location")
            } footer: {
                Text("\(event.venue) · \(event.booth)")
            }

            if let day = currentDay {
                Section("event.detail.today") {
                    LabeledContent("event.detail.revenue") {
                        Text(yen(day.revenue))
                            .monospacedDigit()
                            .foregroundStyle(UC.tint)
                            .fontWeight(.semibold)
                    }
                    LabeledContent("event.detail.transactions") {
                        Text("\(day.transactions.count)")
                            .monospacedDigit()
                    }
                    LabeledContent("event.detail.stock.remaining") {
                        Text("\(day.stockLeft)")
                            .monospacedDigit()
                    }
                    if day.stockTotal > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            ProgressView(value: Double(day.soldCount), total: Double(day.stockTotal))
                            Text("event.detail.progress \(day.soldCount) \(day.stockTotal)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("event.detail.modes") {
                    NavigationLink(value: EventDetailRoute.pos(day)) {
                        Label("event.detail.standard", systemImage: "square.grid.2x2")
                    }
                    NavigationLink(value: EventDetailRoute.oshinagaki(day)) {
                        Label("event.detail.oshinagaki", systemImage: "photo")
                    }
                }

                Section("event.detail.manage") {
                    NavigationLink(value: EventDetailRoute.items(day)) {
                        Label("event.detail.items", systemImage: "bag")
                            .badge(event.items.count)
                    }
                    NavigationLink(value: EventDetailRoute.transactions(day)) {
                        Label("event.detail.transactions.list", systemImage: "doc.text")
                            .badge(day.transactions.count)
                    }
                    NavigationLink(value: EventDetailRoute.reservations(day)) {
                        Label("event.detail.reservations", systemImage: "person.2")
                            .badge(day.reservations.count)
                    }
                }
            }

            Section("event.detail.settings") {
                Button {
                } label: {
                    Label("event.detail.add.day", systemImage: "calendar.badge.plus")
                }
                Button {
                } label: {
                    Label("event.detail.receipt.qr", systemImage: "qrcode")
                }
                Button {
                } label: {
                    Label("event.detail.export", systemImage: "square.and.arrow.up")
                }
            }
        }
        .navigationTitle(event.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: EventDetailRoute.self) { route in
            switch route {
            case .pos(let day):           POSView(event: event, day: day)
            case .oshinagaki(let day):    OshinagakiView(event: event, day: day)
            case .items(let day):         ItemsSetupView(event: event, day: day)
            case .transactions(let day):  TransactionsView(event: event, day: day)
            case .reservations(let day):  ReservationsView(event: event, day: day)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("common.edit", systemImage: "pencil") { }
                    Button("event.detail.receipt.qr", systemImage: "qrcode") { }
                    Button("event.detail.export", systemImage: "square.and.arrow.up") { }
                    Section {
                        Button("event.delete", systemImage: "trash", role: .destructive) { }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .onAppear {
            if selectedDayID == nil {
                selectedDayID = event.sortedDays.first?.persistentModelID
            }
        }
    }

    private var currentDay: EventDay? {
        event.sortedDays.first { $0.persistentModelID == selectedDayID } ?? event.sortedDays.first
    }
}

enum EventDetailRoute: Hashable {
    case pos(EventDay)
    case oshinagaki(EventDay)
    case items(EventDay)
    case transactions(EventDay)
    case reservations(EventDay)
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
