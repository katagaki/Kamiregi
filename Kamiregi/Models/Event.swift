import Foundation
import SwiftData
import SwiftUI

@Model
final class Event {
    var id: UUID = UUID()
    var name: String = ""
    var venue: String = ""
    var booth: String = ""
    var colorHex: String = "#FF5A4E"
    var createdAt: Date = Date()
    var isPastEvent: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \EventDay.event)
    var days: [EventDay] = []

    @Relationship(deleteRule: .cascade, inverse: \InventoryItem.event)
    var items: [InventoryItem] = []

    init(name: String, venue: String, booth: String, colorHex: String = "#FF5A4E", isPastEvent: Bool = false) {
        self.id = UUID()
        self.name = name
        self.venue = venue
        self.booth = booth
        self.colorHex = colorHex
        self.createdAt = Date()
        self.isPastEvent = isPastEvent
    }

    var color: Color { Color(hex: colorHex) }

    var sortedDays: [EventDay] {
        days.sorted { $0.date < $1.date }
    }
}
