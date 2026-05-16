import Foundation
import SwiftData
import SwiftUI

@Model
final class InventoryItem {
    var id: UUID = UUID()
    var name: String = ""
    var sub: String = ""
    var price: Int = 0
    var emoji: String = "📦"
    var swatchHex: String = "#FFE4DC"
    var sortIndex: Int = 0
    var event: Event?

    @Relationship(deleteRule: .cascade, inverse: \DailyStock.item)
    var stocks: [DailyStock] = []

    init(name: String, sub: String, price: Int, emoji: String, swatchHex: String, sortIndex: Int = 0) {
        self.id = UUID()
        self.name = name
        self.sub = sub
        self.price = price
        self.emoji = emoji
        self.swatchHex = swatchHex
        self.sortIndex = sortIndex
    }

    var swatch: Color { Color(hex: swatchHex) }

    func stock(on day: EventDay) -> DailyStock? {
        stocks.first { $0.day?.id == day.id }
    }
}
