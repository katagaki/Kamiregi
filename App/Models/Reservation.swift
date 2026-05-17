import Foundation
import SwiftData

@Model
final class Reservation {
    var id: UUID = UUID()
    var name: String = ""
    var handle: String = ""
    var contactRaw: String = ContactKind.sns.rawValue
    var note: String = ""
    var total: Int = 0
    var pickedUp: Bool = false
    var createdAt: Date = Date()
    var day: EventDay?

    init(name: String, handle: String, contact: ContactKind, note: String, total: Int, pickedUp: Bool = false) {
        self.id = UUID()
        self.name = name
        self.handle = handle
        self.contactRaw = contact.rawValue
        self.note = note
        self.total = total
        self.pickedUp = pickedUp
        self.createdAt = Date()
    }

    var contact: ContactKind {
        get { ContactKind(rawValue: contactRaw) ?? .sns }
        set { contactRaw = newValue.rawValue }
    }
}
