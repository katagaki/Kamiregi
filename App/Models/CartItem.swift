import Foundation
import SwiftData

struct CartItem: Identifiable, Equatable {
    let id = UUID()
    let itemID: PersistentIdentifier?
    var name: String
    var sub: String
    var price: Int
    var photoData: Data?
    var qty: Int

    var subtotal: Int { qty * price }

    static func == (lhs: CartItem, rhs: CartItem) -> Bool { lhs.id == rhs.id && lhs.qty == rhs.qty }
}
