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

    // Quick "received amount" denominations, expressed in the underlying yen.
    // USD values are derived from the conversion rate so they render as
    // $1 / $5 / $10 / $50 / $100.
    var quickAmounts: [Int] {
        switch self {
        case .yen:
            return [100, 500, 1000, 5000, 10000]
        case .dollar:
            return [1, 5, 10, 50, 100].map { Int((Double($0) / Self.usdPerJpy).rounded()) }
        }
    }

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
