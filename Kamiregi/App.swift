import SwiftUI
import SwiftData

@main
struct KamiregiApp: App {
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Event.self,
            EventDay.self,
            InventoryItem.self,
            DailyStock.self,
            SaleTransaction.self,
            TransactionLine.self,
            Reservation.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await SampleData.seedIfEmpty(container: sharedModelContainer)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
