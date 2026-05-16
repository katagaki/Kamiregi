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
            Reservation.self
        ])
        // TODO: Re-enable iCloud/CloudKit sync.
        //
        // The app's entitlements declare CloudKit, but the SwiftData schema
        // isn't CloudKit-compatible yet, so the store fails to load with:
        // "CloudKit integration requires that all relationships be optional".
        //
        // To enable sync, every @Relationship in the models needs to be:
        //   - optional on the to-one side (e.g. `var event: Event?`), and
        //   - either optional or have a default value on the to-many side
        //     (e.g. `var items: [InventoryItem] = []`).
        //
        // Also audit non-optional scalar properties: CloudKit requires them
        // to have default values. Once the schema is migrated, swap
        // `.none` below for `.automatic` (or `.private(...)`) and verify
        // the store loads on a clean simulator.
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
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
