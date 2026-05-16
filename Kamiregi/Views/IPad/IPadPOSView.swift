import SwiftUI
import SwiftData

struct IPadPOSView: View {
    @Environment(\.modelContext) private var context
    @Bindable var event: Event
    @Bindable var day: EventDay
    @Bindable var cart: CartStore
    @State private var isGrid = true
    @State private var oosItem: InventoryItem?
    @State private var showPayment = false
    @State private var searchText = ""
    @State private var showCartSheet = false

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.width < 720
            HStack(spacing: 0) {
                main
                if !compact {
                    Divider()
                    cartPane.frame(width: 320)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if compact && cart.count > 0 {
                    POSCartBar(cart: cart) { showCartSheet = true }
                        .frame(maxWidth: 320)
                        .padding()
                }
            }
        }
        .background(Color(.systemGroupedBackground))
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
        .sheet(isPresented: $showPayment) {
            PaymentSheet(cart: cart, event: event, day: day) { showPayment = false }
        }
        .sheet(isPresented: $showCartSheet) {
            CartSheet(cart: cart, event: event, day: day)
        }
    }

    private var filteredItems: [InventoryItem] {
        let items = event.items.sorted(by: { $0.sortIndex < $1.sortIndex })
        guard !searchText.isEmpty else { return items }
        let q = searchText.lowercased()
        return items.filter { $0.name.lowercased().contains(q) || $0.sub.lowercased().contains(q) }
    }

    @ViewBuilder
    private var main: some View {
        if filteredItems.isEmpty {
            ContentUnavailableView.search(text: searchText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if isGrid {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 12)], spacing: 12) {
                    ForEach(filteredItems, id: \.id) { item in
                        POSGridCard(item: item, day: day) { tap(item) }
                    }
                }
                .padding(20)
            }
        } else {
            List(filteredItems, id: \.id) { item in
                POSListRow(item: item, day: day) { tap(item) }
            }
        }
    }

    private var cartPane: some View {
        NavigationStack {
            Group {
                if cart.lines.isEmpty {
                    ContentUnavailableView(
                        "pos.cart.title",
                        systemImage: "cart",
                        description: Text("pos.cart.subtotal")
                    )
                } else {
                    List {
                        ForEach(cart.lines) { line in
                            CartLineRow(line: line, cart: cart)
                        }
                        Section {
                            LabeledContent("pos.cart.total") {
                                Text(yen(cart.subtotal))
                                    .font(.title2.weight(.bold))
                                    .monospacedDigit()
                                    .foregroundStyle(UC.tint)
                            }
                        }
                    }
                }
            }
            .navigationTitle("pos.cart.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("pos.cart.clear", role: .destructive) { cart.clear() }
                        .disabled(cart.lines.isEmpty)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button { showPayment = true } label: {
                        Text("pos.cart.continue").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(cart.lines.isEmpty)
                }
            }
        }
    }

    private func tap(_ item: InventoryItem) {
        let remaining = item.stock(on: day)?.remaining ?? 0
        if remaining == 0 { oosItem = item } else { cart.add(item) }
    }
}
