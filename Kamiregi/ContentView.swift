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

#Preview {
    ContentView()
        .modelContainer(for: [Event.self, EventDay.self, InventoryItem.self, DailyStock.self, SaleTransaction.self, TransactionLine.self, Reservation.self], inMemory: true)
}
