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

    // Oshinagaki tap region in unit space (0..1). Width = 0 means no region defined.
    var regionX: Double = 0
    var regionY: Double = 0
    var regionWidth: Double = 0
    var regionHeight: Double = 0

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

    var hasRegion: Bool { regionWidth > 0 && regionHeight > 0 }

    var regionRect: CGRect {
        get { CGRect(x: regionX, y: regionY, width: regionWidth, height: regionHeight) }
        set {
            regionX = newValue.minX
            regionY = newValue.minY
            regionWidth = newValue.width
            regionHeight = newValue.height
        }
    }

    func stock(on day: EventDay) -> DailyStock? {
        stocks.first { $0.day?.id == day.id }
    }
}
