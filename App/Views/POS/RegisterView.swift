import SwiftUI
import SwiftData

enum RegisterMode: CaseIterable, Hashable {
    case grid, list, oshinagaki
}

struct RegisterView: View {
    @Bindable var event: Event
    @Bindable var day: EventDay
    @State private var mode: RegisterMode = .grid
    @State private var showPayment = false
    @State private var showEdit = false
    @State private var oosItem: InventoryItem?
    @State private var cart = CartStore()
    @State private var flight = CartFlightController()

    var body: some View {
        ZStack {
            if sortedItems.isEmpty && mode != .oshinagaki {
                ContentUnavailableView("pos.title", systemImage: "cart")
            } else {
                switch mode {
                case .grid: gridContent
                case .list: listContent
                case .oshinagaki: oshinagakiContent
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: POSCartBar.collapsedHeight)
        }
        .overlay(alignment: .bottom) {
            POSCartBar(cart: cart, flight: flight) { showPayment = true }
        }
        .overlay {
            CartFlightOverlay(controller: flight)
        }
        .navigationTitle("pos.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("register.mode", selection: $mode) {
                    Image(systemName: "square.grid.2x2").tag(RegisterMode.grid)
                    Image(systemName: "list.bullet").tag(RegisterMode.list)
                    Image(systemName: "photo").tag(RegisterMode.oshinagaki)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
            if mode == .oshinagaki {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showEdit = true } label: {
                        Label("common.edit", systemImage: "pencil")
                    }
                }
            }
        }
        .sheet(isPresented: $showPayment) {
            PaymentSheet(cart: cart, event: event, day: day) { showPayment = false }
        }
        .sheet(isPresented: $showEdit) {
            OshinagakiEditView(event: event, day: day)
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
        event.items.sorted { $0.sortIndex < $1.sortIndex }
    }

    private var gridContent: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 12)], spacing: 12) {
                ForEach(sortedItems, id: \.id) { item in
                    POSGridCard(item: item, day: day, cart: cart) { tap(item) }
                        .reportGlobalFrame { flight.sourceAnchors[item.persistentModelID] = $0 }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var listContent: some View {
        List(sortedItems, id: \.id) { item in
            POSListRow(
                item: item,
                day: day,
                cart: cart,
                onThumbFrame: { flight.sourceAnchors[item.persistentModelID] = $0 },
                onAdd: { tap(item) }
            )
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private var oshinagakiContent: some View {
        if event.oshinagakiImage == nil && event.items.allSatisfy({ !$0.hasRegion }) {
            ContentUnavailableView {
                Label("oshinagaki.empty.title", systemImage: "photo.on.rectangle.angled")
            } description: {
                Text("oshinagaki.empty.description")
            } actions: {
                Button { showEdit = true } label: {
                    Label("oshinagaki.empty.action", systemImage: "pencil")
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            ZoomableOshinagakiCanvas(
                imageData: event.oshinagakiImage,
                items: event.items,
                day: day,
                cart: cart,
                onTap: { item, rect in tapOshinagaki(item, rect) }
            )
        }
    }

    private func tap(_ item: InventoryItem) {
        let rect = flight.sourceAnchors[item.persistentModelID] ?? .zero
        let corner: CGFloat = mode == .grid ? 16 : 10
        addToCart(item, from: rect, corner: corner, visual: CartFlightFactory.visual(for: item))
    }

    private func tapOshinagaki(_ item: InventoryItem, _ rect: CGRect) {
        addToCart(
            item,
            from: rect,
            corner: 12,
            visual: CartFlightFactory.oshinagakiVisual(for: item, background: event.oshinagakiImage),
            fadeOnly: true
        )
    }

    private func addToCart(
        _ item: InventoryItem,
        from rect: CGRect,
        corner: CGFloat,
        visual: FlyVisual,
        fadeOnly: Bool = false
    ) {
        let remaining = max(0, item.available(on: day) - cart.qty(for: item))
        if remaining == 0 { oosItem = item; return }
        cart.add(item)
        guard rect != .zero else { return }
        flight.launch(CartFlight(
            visual: visual,
            start: rect,
            corner: corner,
            fadeOnly: fadeOnly,
            targetItemID: item.persistentModelID
        ))
    }
}
