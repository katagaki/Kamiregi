import SwiftUI
import SwiftData

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

