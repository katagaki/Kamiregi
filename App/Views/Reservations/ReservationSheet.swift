import SwiftUI
import SwiftData

struct ReservationSheet: View {
    @AppStorage("currency") private var currency: Currency = .yen
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let event: Event
    let day: EventDay
    let reservation: Reservation?

    @State private var name: String
    @State private var contact: ContactKind
    @State private var handle: String
    @State private var note: String
    @State private var discount: Int
    @State private var quantities: [UUID: Int]

    private let originalQuantities: [UUID: Int]

    init(event: Event, day: EventDay, reservation: Reservation? = nil) {
        self.event = event
        self.day = day
        self.reservation = reservation

        var qtys: [UUID: Int] = [:]
        for line in reservation?.lines ?? [] {
            if let itemID = line.item?.id { qtys[itemID, default: 0] += line.qty }
        }
        originalQuantities = qtys
        _name = State(initialValue: reservation?.name ?? "")
        _contact = State(initialValue: reservation?.contact ?? .sns)
        _handle = State(initialValue: reservation?.handle ?? "")
        _note = State(initialValue: reservation?.note ?? "")
        _discount = State(initialValue: reservation?.discount ?? 0)
        _quantities = State(initialValue: qtys)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("reservation.add.name.placeholder", text: $name)
                } header: {
                    Text("reservation.add.name")
                } footer: {
                    Text("reservation.add.name.footer")
                }

                Section {
                    Picker("reservation.add.contact.method", selection: $contact) {
                        ForEach(ContactKind.allCases, id: \.self) { kind in
                            Label(kind.labelKey, systemImage: kind.systemImage).tag(kind)
                        }
                    }
                    .pickerStyle(.menu)
                    TextField(contactPlaceholder, text: $handle)
                        .keyboardType(keyboardType)
                        .textContentType(textContentType)
                } header: {
                    Text("reservation.add.contact")
                } footer: {
                    Text("reservation.add.contact.footer")
                }

                Section {
                    ForEach(sortedItems, id: \.id) { item in
                        itemRow(item)
                    }
                } header: {
                    Text("reservation.items")
                } footer: {
                    Text("reservation.items.footer")
                }

                Section {
                    LabeledContent("reservation.items.total") {
                        Text(currency.format(itemsTotal))
                            .monospacedDigit()
                    }
                    HStack {
                        Text("reservation.discount")
                        Spacer()
                        Text(verbatim: "−").foregroundStyle(.secondary)
                        TextField("0", value: $discount, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                            .frame(maxWidth: 120)
                    }
                    LabeledContent("reservation.add.total") {
                        Text(currency.format(total))
                            .font(.body.weight(.bold))
                            .monospacedDigit()
                    }
                } footer: {
                    Text("reservation.discount.footer")
                }

                Section("reservation.add.note") {
                    TextField("reservation.add.note.placeholder", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(reservation == nil ? "reservation.add.title" : "reservation.edit.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm, action: save)
                        .accessibilityLabel("common.save")
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty
                                  || handle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private func itemRow(_ item: InventoryItem) -> some View {
        let qty = quantities[item.id] ?? 0
        let max = maxQty(of: item)
        HStack(spacing: 12) {
            ItemThumbnail(name: item.name, photoData: item.photoData, size: 36, cornerRadius: 9)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    Text(item.price > 0 ? currency.format(item.price) : String(localized: "items.free"))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    StockPill(stock: max - qty)
                }
            }
            Spacer(minLength: 8)
            if qty > 0 {
                Text(verbatim: "×\(qty)")
                    .font(.body.weight(.semibold))
                    .monospacedDigit()
            }
            Stepper(
                "",
                value: Binding(
                    get: { quantities[item.id] ?? 0 },
                    set: { quantities[item.id] = $0 }
                ),
                in: 0...max
            )
            .labelsHidden()
            .disabled(max == 0)
        }
        .opacity(max == 0 && qty == 0 ? 0.5 : 1)
    }

    private var sortedItems: [InventoryItem] {
        event.items.sorted { $0.sortIndex < $1.sortIndex }
    }

    // Stock this reservation can claim: what's free plus what it already holds.
    private func maxQty(of item: InventoryItem) -> Int {
        item.available(on: day) + (originalQuantities[item.id] ?? 0)
    }

    private var orphanLines: [ReservationLine] {
        reservation?.lines.filter { $0.item == nil } ?? []
    }

    private var itemsTotal: Int {
        let live = sortedItems.reduce(0) { $0 + (quantities[$1.id] ?? 0) * $1.price }
        return live + orphanLines.reduce(0) { $0 + $1.subtotal }
    }

    private var total: Int { max(0, itemsTotal - discount) }

    private var contactPlaceholder: LocalizedStringKey {
        switch contact {
        case .sns:  "reservation.add.contact.sns.placeholder"
        case .mail: "reservation.add.contact.mail.placeholder"
        case .tel:  "reservation.add.contact.tel.placeholder"
        }
    }

    private var keyboardType: UIKeyboardType {
        switch contact {
        case .mail: .emailAddress
        case .tel:  .phonePad
        default:    .default
        }
    }

    private var textContentType: UITextContentType? {
        switch contact {
        case .mail: .emailAddress
        case .tel:  .telephoneNumber
        default:    nil
        }
    }

    private func save() {
        let res: Reservation
        if let existing = reservation {
            res = existing
            res.name = name
            res.handle = handle
            res.contact = contact
            res.note = note
        } else {
            res = Reservation(name: name, handle: handle, contact: contact, note: note)
            res.day = day
            context.insert(res)
        }
        res.discount = discount

        for item in sortedItems {
            let qty = quantities[item.id] ?? 0
            if let line = res.lines.first(where: { $0.item?.id == item.id }) {
                if qty == 0 {
                    context.delete(line)
                } else {
                    line.qty = qty
                    line.itemName = item.name
                    line.unitPrice = item.price
                }
            } else if qty > 0 {
                let line = ReservationLine(item: item, qty: qty)
                line.reservation = res
                context.insert(line)
            }
        }
        res.total = total
        try? context.save()
        dismiss()
    }
}

extension ContactKind {
    var labelKey: LocalizedStringKey {
        switch self {
        case .sns:  "reservation.contact.sns"
        case .mail: "reservation.contact.mail"
        case .tel:  "reservation.contact.tel"
        }
    }
}
