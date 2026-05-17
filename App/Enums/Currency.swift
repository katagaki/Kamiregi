import SwiftUI

enum Currency: String, CaseIterable, Identifiable {
    case yen = "JPY"
    case dollar = "USD"

    var id: String { rawValue }

    var labelKey: LocalizedStringKey {
        switch self {
        case .yen:    "currency.yen"
        case .dollar: "currency.dollar"
        }
    }

    // Fixed display-only conversion. Underlying amounts remain integer yen;
    // this just controls how they're rendered when the user picks USD.
    private static let usdPerJpy: Double = 1.0 / 150.0

    func format(_ amount: Int) -> String {
        switch self {
        case .yen:
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.groupingSeparator = ","
            return "¥" + (formatter.string(from: NSNumber(value: amount)) ?? String(amount))
        case .dollar:
            let usd = Double(amount) * Self.usdPerJpy
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            formatter.locale = Locale(identifier: "en_US")
            return formatter.string(from: NSNumber(value: usd)) ?? "$\(usd)"
        }
    }
}
