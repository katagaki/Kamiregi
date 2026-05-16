import Foundation
import SwiftData

@Model
final class SaleTransaction {
    var id: UUID = UUID()
    var number: Int = 0
    var timestamp: Date = Date()
    var total: Int = 0
    var paid: Int = 0
    var day: EventDay?

    @Relationship(deleteRule: .cascade, inverse: \TransactionLine.transaction)
    var lines: [TransactionLine] = []

    init(number: Int, timestamp: Date, total: Int, paid: Int) {
        self.id = UUID()
        self.number = number
        self.timestamp = timestamp
        self.total = total
        self.paid = paid
    }

    var change: Int { max(0, paid - total) }
    var itemCount: Int { lines.reduce(0) { $0 + $1.qty } }
}

@Model
final class TransactionLine {
    var id: UUID = UUID()
    var itemName: String = ""
    var qty: Int = 0
    var unitPrice: Int = 0
    var transaction: SaleTransaction?

    init(itemName: String, qty: Int, unitPrice: Int) {
        self.id = UUID()
        self.itemName = itemName
        self.qty = qty
        self.unitPrice = unitPrice
    }

    var subtotal: Int { qty * unitPrice }
}
