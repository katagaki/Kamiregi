import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var hSize
    @AppStorage("keepScreenOn") private var keepScreenOn = false

    var body: some View {
        Group {
            if hSize == .regular {
                IPadRootView()
            } else {
                EventsListView()
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = keepScreenOn
        }
        .onChange(of: keepScreenOn) { _, newValue in
            UIApplication.shared.isIdleTimerDisabled = newValue
        }
    }
}
