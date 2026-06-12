import Foundation
import SwiftData

@Model
final class EventDay {
    var id: UUID = UUID()
    var date: Date = Date()
    var label: String = ""
    var event: Event?

    @Relationship(deleteRule: .cascade, inverse: \DailyStock.day)
    var stocks: [DailyStock] = []

    @Relationship(deleteRule: .cascade, inverse: \SaleTransaction.day)
    var transactions: [SaleTransaction] = []

    @Relationship(deleteRule: .cascade, inverse: \Reservation.day)
    var reservations: [Reservation] = []

    init(date: Date, label: String) {
        self.id = UUID()
        self.date = date
        self.label = label
    }

    var stockTotal: Int { stocks.reduce(0) { $0 + $1.initial } }
    var stockLeft: Int {
        stocks.reduce(0) { sum, stock in
            let reserved = stock.item.map { reservedQty(of: $0) } ?? 0
            return sum + max(0, stock.initial - stock.sold - reserved)
        }
    }
    var soldCount: Int { stocks.reduce(0) { $0 + $1.sold } }

    // Reserved items are committed to a reservation, picked up or not.
    func reservedQty(of item: InventoryItem) -> Int {
        reservations.reduce(0) { $0 + $1.reservedQty(of: item) }
    }
    var revenue: Int {
        transactions.reduce(0) { $0 + $1.total }
    }
}

@Model
final class DailyStock {
    var id: UUID = UUID()
    var initial: Int = 0
    var sold: Int = 0
    var item: InventoryItem?
    var day: EventDay?

    init(initial: Int, sold: Int = 0) {
        self.id = UUID()
        self.initial = initial
        self.sold = sold
    }

    var remaining: Int { max(0, initial - sold) }
    var isOutOfStock: Bool { remaining == 0 }
}
