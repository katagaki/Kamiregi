import SwiftUI
import SwiftData

struct AddReservationSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var event: Event
    @Bindable var day: EventDay

    @State private var name: String = ""
    @State private var contact: ContactKind = .sns
    @State private var handle: String = ""
    @State private var note: String = ""
    @State private var total: Int = 0

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
                        Label("reservation.contact.sns",  systemImage: "at").tag(ContactKind.sns)
                        Label("reservation.contact.mail", systemImage: "envelope").tag(ContactKind.mail)
                        Label("reservation.contact.tel",  systemImage: "phone").tag(ContactKind.tel)
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

                Section("reservation.add.total") {
                    TextField("reservation.add.total.placeholder", value: $total, format: .number)
                        .keyboardType(.numberPad)
                }

                Section("reservation.add.note") {
                    TextField("reservation.add.note.placeholder", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("reservation.add.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty
                                  || handle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

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
        let res = Reservation(
            name: name,
            handle: handle,
            contact: contact,
            note: note,
            total: total,
            pickedUp: false
        )
        res.day = day
        context.insert(res)
        try? context.save()
        dismiss()
    }
}
