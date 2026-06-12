import Foundation
import SwiftUI

enum ContactKind: String, Codable, CaseIterable {
    case sns, mail, tel

    var systemImage: String {
        switch self {
        case .sns:  "at"
        case .mail: "envelope"
        case .tel:  "phone"
        }
    }

    var color: Color {
        switch self {
        case .sns:  .purple
        case .mail: .blue
        case .tel:  .green
        }
    }
}
