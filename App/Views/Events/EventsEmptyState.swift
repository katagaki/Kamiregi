import SwiftUI

struct EventsEmptyState: View {
    var onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("events.empty.title", systemImage: "calendar")
        } description: {
            Text("events.empty.description")
        } actions: {
            Button {
                onAdd()
            } label: {
                Label("events.empty.action", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
