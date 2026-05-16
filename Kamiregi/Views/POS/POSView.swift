import SwiftUI
import SwiftData

struct POSView: View {
    @Environment(\.modelContext) private var context
    @Bindable var event: Event
    @Bindable var day: EventDay
    @State private var isGrid: Bool = true
    @State private var showCart = false
    @State private var oosItem: InventoryItem?
    @State private var cart = CartStore()
    @State private var searchText = ""

    var body: some View {
        Group {
            if filteredItems.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else if isGrid {
                gridContent
            } else {
                listContent
            }
        }
        .safeAreaInset(edge: .bottom) {
            POSCartBar(cart: cart) { showCart = true }
        }
        .navigationTitle("pos.title")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: Text("pos.search.prompt"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Picker("pos.view.display", selection: $isGrid) {
                    Image(systemName: "square.grid.2x2").tag(true)
                    Image(systemName: "list.bullet").tag(false)
                }
                .pickerStyle(.segmented)
            }
        }
        .sheet(isPresented: $showCart) {
            CartSheet(cart: cart, event: event, day: day)
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

    private var filteredItems: [InventoryItem] {
        let items = event.items.sorted(by: { $0.sortIndex < $1.sortIndex })
        guard !searchText.isEmpty else { return items }
        let q = searchText.lowercased()
        return items.filter { $0.name.lowercased().contains(q) || $0.sub.lowercased().contains(q) }
    }

    private var gridContent: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 12)], spacing: 12) {
                ForEach(filteredItems, id: \.id) { item in
                    POSGridCard(item: item, day: day) { tap(item) }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var listContent: some View {
        List(filteredItems, id: \.id) { item in
            POSListRow(item: item, day: day) { tap(item) }
        }
    }

    private func tap(_ item: InventoryItem) {
        let remaining = item.stock(on: day)?.remaining ?? 0
        if remaining == 0 { oosItem = item } else { cart.add(item) }
    }
}
