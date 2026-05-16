import SwiftUI

struct TapRegion: Identifiable {
    let id: UUID
    var name: String
    var emoji: String
    var price: Int
    var stock: Int
    var color: Color
    var rect: CGRect   // unit space 0..1

    var isOutOfStock: Bool { stock <= 0 }
}
