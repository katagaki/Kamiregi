import SwiftUI
import SwiftData

struct EventDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var event: Event
    @State private var selectedDayID: PersistentIdentifier?
    @State private var showAddDay = false
    @State private var showEditEvent = false
    @State private var showDeleteConfirm = false

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
                    HStack(spacing: 0) {
                        VStack(spacing: 6) {
                            Text(yen(day.revenue))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .fontDesign(.rounded)
                                .monospacedDigit()
                                .frame(maxHeight: .infinity)
                            Text("event.detail.revenue")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        VStack(spacing: 6) {
                            Text("\(day.transactions.count)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .fontDesign(.rounded)
                                .monospacedDigit()
                                .frame(maxHeight: .infinity)
                            Text("event.detail.transactions")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .stroke(Color.orange.opacity(0.35), lineWidth: 5)
                                Circle()
                                    .trim(from: 0, to: day.stockTotal > 0 ? CGFloat(day.stockLeft) / CGFloat(day.stockTotal) : 1)
                                    .stroke(Brand.tint, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                Text("\(day.stockLeft)")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .fontDesign(.rounded)
                                    .monospacedDigit()
                            }
                            .frame(width: 44, height: 44)
                            Text("event.detail.stock.remaining")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(.vertical, 8)
                }

                Section("event.detail.modes") {
                    NavigationLink(value: EventDetailRoute.register(day)) {
                        Label("pos.title", systemImage: "cart")
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
                    showAddDay = true
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
            case .register(let day):      RegisterView(event: event, day: day)
            case .items(let day):         ItemsSetupView(event: event, day: day)
            case .transactions(let day):  TransactionsView(event: event, day: day)
            case .reservations(let day):  ReservationsView(event: event, day: day)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("common.edit", systemImage: "pencil") { showEditEvent = true }
                    Button("event.detail.receipt.qr", systemImage: "qrcode") { }
                    Button("event.detail.export", systemImage: "square.and.arrow.up") { }
                    Section {
                        Button("event.delete", systemImage: "trash", role: .destructive) {
                            showDeleteConfirm = true
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .sheet(isPresented: $showAddDay) {
            AddEventDaySheet(event: event)
        }
        .sheet(isPresented: $showEditEvent) {
            EditEventSheet(event: event)
        }
        .confirmationDialog(
            "event.delete.confirm.title",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("event.delete", role: .destructive) {
                context.delete(event)
                try? context.save()
                dismiss()
            }
            Button("common.cancel", role: .cancel) { }
        } message: {
            Text("event.delete.confirm.message")
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
    case register(EventDay)
    case items(EventDay)
    case transactions(EventDay)
    case reservations(EventDay)
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private struct AddEventDaySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var event: Event

    @State private var date: Date = Date()
    @State private var label: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("event.add.days") {
                    DatePicker("event.detail.day", selection: $date, displayedComponents: .date)
                    TextField("event.detail.add.day.label.placeholder", text: $label)
                }
            }
            .navigationTitle("event.detail.add.day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm, action: save)
                        .accessibilityLabel("common.save")
                        .disabled(label.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let day = EventDay(date: date, label: label.trimmingCharacters(in: .whitespaces))
        event.days.append(day)
        context.insert(day)
        try? context.save()
        dismiss()
    }
}
