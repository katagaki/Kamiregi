import SwiftUI
import SwiftData

struct POSView: View {
    @Environment(\.modelContext) private var context
    @Bindable var event: Event
    @Bindable var day: EventDay
    @State private var isGrid: Bool = true
    @State private var showPayment = false
    @State private var oosItem: InventoryItem?
    @State private var cart = CartStore()

    var body: some View {
        Group {
            if sortedItems.isEmpty {
                ContentUnavailableView("pos.title", systemImage: "cart")
            } else if isGrid {
                gridContent
            } else {
                listContent
            }
        }
        .safeAreaInset(edge: .bottom) {
            POSCartBar(cart: cart) { showPayment = true }
        }
        .navigationTitle("pos.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("pos.view.display", systemImage: "ellipsis") {
                    Picker("pos.view.display", selection: $isGrid) {
                        Label("pos.view.grid", systemImage: "square.grid.2x2").tag(true)
                        Label("pos.view.list", systemImage: "list.bullet").tag(false)
                    }
                    .pickerStyle(.inline)
                    .labelsVisibility(.visible)
                }
            }
        }
        .sheet(isPresented: $showPayment) {
            PaymentSheet(cart: cart, event: event, day: day) { showPayment = false }
        }
        .alert(
            "pos.oos.title \(oosItem?.name ?? "")",
            isPresented: Binding(get: { oosItem != nil }, set: { if !$0 { oosItem = nil } })
        ) {
            Button("common.cancel", role: .cancel) { oosItem = nil }
            Button("pos.oos.continue", role: .destructive) {
                if let item = oosItem { cart.add(item) }
                oosItem = nil
            }
        } message: {
            Text("pos.oos.message")
        }
    }

    private var sortedItems: [InventoryItem] {
        event.items.sorted(by: { $0.sortIndex < $1.sortIndex })
    }

    private var gridContent: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 12)], spacing: 12) {
                ForEach(sortedItems, id: \.id) { item in
                    POSGridCard(item: item, day: day) { tap(item) }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var listContent: some View {
        List(sortedItems, id: \.id) { item in
            POSListRow(item: item, day: day) { tap(item) }
        }
    }

    private func tap(_ item: InventoryItem) {
        let remaining = item.stock(on: day)?.remaining ?? 0
        if remaining == 0 { oosItem = item } else { cart.add(item) }
    }
}
