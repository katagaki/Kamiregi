import SwiftUI
import SwiftData

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
}

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var hSize

    var body: some View {
        if hSize == .regular {
            IPadRootView()
        } else {
            EventsListView()
        }
    }
}

struct SettingsMenu: View {
    @AppStorage("currency") private var currency: Currency = .yen

    var body: some View {
        Menu {
            Picker(selection: $currency) {
                ForEach(Currency.allCases) { option in
                    Text(option.labelKey).tag(option)
                }
            } label: {
                Text("settings.currency")
            }
            .pickerStyle(.inline)

            Divider()

            Link(destination: URL(string: "https://github.com/Kamicash")!) {
                Label("settings.sourceCode", systemImage: "chevron.left.forwardslash.chevron.right")
            }
        } label: {
            Label("common.more", systemImage: "ellipsis")
        }
    }
}
