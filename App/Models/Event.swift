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
    @Attribute(.externalStorage) var oshinagakiImage: Data?

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

    // Derived from the event's days; falls back to the manual flag when no days exist.
    var timing: EventTiming {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayStarts = days.map { calendar.startOfDay(for: $0.date) }
        guard let first = dayStarts.min(), let last = dayStarts.max() else {
            return isPastEvent ? .past : .upcoming
        }
        if today < first { return .upcoming }
        if today > last { return .past }
        return .today
    }

    var isLive: Bool { timing == .today }
}

enum EventTiming {
    case today, upcoming, past
}
