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
            POSCartBar(cart: cart) { showPayment = true }
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
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var listContent: some View {
        List(sortedItems, id: \.id) { item in
            POSListRow(item: item, day: day, cart: cart) { tap(item) }
        }
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
            ScrollView {
                VStack(spacing: 16) {
                    OshinagakiCanvas(
                        imageData: event.oshinagakiImage,
                        items: event.items,
                        day: day,
                        cart: cart,
                        onTap: tap
                    )
                    .padding(.horizontal, 16)
                }
                .padding(.top, 12)
                .padding(.bottom, 120)
            }
        }
    }

    private func tap(_ item: InventoryItem) {
        let remaining = max(0, (item.stock(on: day)?.remaining ?? 0) - cart.qty(for: item))
        if remaining == 0 { oosItem = item } else { cart.add(item) }
    }
}
