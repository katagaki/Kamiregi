import SwiftUI

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
