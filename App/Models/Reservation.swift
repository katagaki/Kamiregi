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
    var discount: Int = 0
    var pickedUp: Bool = false
    var createdAt: Date = Date()
    var day: EventDay?

    @Relationship(deleteRule: .cascade, inverse: \ReservationLine.reservation)
    var lines: [ReservationLine] = []

    init(name: String, handle: String, contact: ContactKind, note: String, discount: Int = 0, pickedUp: Bool = false) {
        self.id = UUID()
        self.name = name
        self.handle = handle
        self.contactRaw = contact.rawValue
        self.note = note
        self.discount = discount
        self.pickedUp = pickedUp
        self.createdAt = Date()
    }

    var contact: ContactKind {
        get { ContactKind(rawValue: contactRaw) ?? .sns }
        set { contactRaw = newValue.rawValue }
    }

    var sortedLines: [ReservationLine] {
        lines.sorted { ($0.item?.sortIndex ?? Int.max) < ($1.item?.sortIndex ?? Int.max) }
    }

    var itemsTotal: Int { lines.reduce(0) { $0 + $1.subtotal } }

    func reservedQty(of item: InventoryItem) -> Int {
        lines.filter { $0.item?.id == item.id }.reduce(0) { $0 + $1.qty }
    }
}

@Model
final class ReservationLine {
    var id: UUID = UUID()
    var itemName: String = ""
    var unitPrice: Int = 0
    var qty: Int = 1
    var item: InventoryItem?
    var reservation: Reservation?

    init(item: InventoryItem, qty: Int) {
        self.id = UUID()
        self.item = item
        self.itemName = item.name
        self.unitPrice = item.price
        self.qty = qty
    }

    // Snapshots keep the line meaningful if the item is later deleted.
    var displayName: String { item?.name ?? itemName }
    var price: Int { item?.price ?? unitPrice }
    var subtotal: Int { price * qty }
}
