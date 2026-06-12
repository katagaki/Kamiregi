import SwiftUI
import SwiftData

struct SettingsMenu: View {
    @Environment(\.modelContext) private var context
    @AppStorage("currency") private var currency: Currency = .yen
    @AppStorage("showReceiptScreen") private var showReceiptScreen = true
    @AppStorage("keepScreenOn") private var keepScreenOn = false
    @State private var showSampleDataConfirm = false

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
            .labelsVisibility(.visible)

            Toggle(isOn: $keepScreenOn) {
                Label("settings.keepScreenOn", systemImage: "sun.max")
            }

            Toggle(isOn: $showReceiptScreen) {
                Label("settings.showReceiptScreen", systemImage: "checkmark.seal")
            }

            Section {
                Button {
                    showSampleDataConfirm = true
                } label: {
                    Label("settings.createSampleData", systemImage: "sparkles")
                }
            }

            Section {
                Link(destination: URL(string: "https://github.com/katagaki/Kamiregi")!) {
                    Label("settings.sourceCode", systemImage: "chevron.left.forwardslash.chevron.right")
                }
            }
        } label: {
            Label("common.more", systemImage: "ellipsis")
        }
        .confirmationDialog(
            "settings.createSampleData.confirm.title",
            isPresented: $showSampleDataConfirm,
            titleVisibility: .visible
        ) {
            Button("settings.createSampleData.confirm.action") {
                SampleData.populate(context: context)
            }
            Button("common.cancel", role: .cancel) { }
        } message: {
            Text("settings.createSampleData.confirm.message")
        }
    }
}
