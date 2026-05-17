import Foundation
import SwiftData
import SwiftUI

struct CartItem: Identifiable, Equatable {
    let id = UUID()
    let itemID: PersistentIdentifier?
    var name: String
    var sub: String
    var price: Int
    var emoji: String
    var swatchHex: String
    var qty: Int

    var swatch: Color { Color(hex: swatchHex) }
    var subtotal: Int { qty * price }

    static func == (lhs: CartItem, rhs: CartItem) -> Bool { lhs.id == rhs.id && lhs.qty == rhs.qty }
}

@MainActor
@Observable
final class CartStore {
    var lines: [CartItem] = []
    var transactionNumber: Int = 24

    var subtotal: Int { lines.reduce(0) { $0 + $1.subtotal } }
    var count: Int { lines.reduce(0) { $0 + $1.qty } }
    var distinctCount: Int { lines.count }
    var isEmpty: Bool { lines.isEmpty }

    func add(_ item: InventoryItem) {
        if let idx = lines.firstIndex(where: { $0.itemID == item.persistentModelID }) {
            lines[idx].qty += 1
        } else {
            lines.append(
                CartItem(
                    itemID: item.persistentModelID,
                    name: item.name,
                    sub: item.sub,
                    price: item.price,
                    emoji: item.emoji,
                    swatchHex: item.swatchHex,
                    qty: 1
                )
            )
        }
    }

    func increment(_ line: CartItem) {
        guard let idx = lines.firstIndex(where: { $0.id == line.id }) else { return }
        lines[idx].qty += 1
    }

    func decrement(_ line: CartItem) {
        guard let idx = lines.firstIndex(where: { $0.id == line.id }) else { return }
        if lines[idx].qty > 1 { lines[idx].qty -= 1 } else { lines.remove(at: idx) }
    }

    func clear() { lines.removeAll() }
}
