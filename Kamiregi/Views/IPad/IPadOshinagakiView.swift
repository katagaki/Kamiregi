import SwiftUI
import SwiftData

struct IPadOshinagakiView: View {
    @Bindable var event: Event
    @Bindable var day: EventDay
    @Bindable var cart: CartStore
    @State private var oosItem: InventoryItem?
    @State private var showPayment = false
    @State private var showEdit = false
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
        .navigationTitle("oshinagaki.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showEdit = true } label: {
                    Label("common.edit", systemImage: "pencil")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("oshinagaki.edit.image.change", systemImage: "photo") { }
                    Button("oshinagaki.edit.clear", systemImage: "trash", role: .destructive) { }
                } label: {
                    Image(systemName: "ellipsis")
                }
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
        .sheet(isPresented: $showEdit) {
            OshinagakiEditView(regions: regions)
        }
        .sheet(isPresented: $showPayment) {
            PaymentSheet(cart: cart, event: event, day: day) { showPayment = false }
        }
        .sheet(isPresented: $showCartSheet) {
            CartSheet(cart: cart, event: event, day: day)
        }
    }

    private var regions: [TapRegion] {
        let items = event.items.sorted(by: { $0.sortIndex < $1.sortIndex })
        let layout: [CGRect] = [
            CGRect(x: 0.06, y: 0.08, width: 0.40, height: 0.30),
            CGRect(x: 0.52, y: 0.08, width: 0.40, height: 0.30),
            CGRect(x: 0.06, y: 0.42, width: 0.40, height: 0.22),
            CGRect(x: 0.52, y: 0.42, width: 0.19, height: 0.22),
            CGRect(x: 0.73, y: 0.42, width: 0.19, height: 0.22),
            CGRect(x: 0.06, y: 0.70, width: 0.28, height: 0.22),
            CGRect(x: 0.38, y: 0.70, width: 0.26, height: 0.22),
            CGRect(x: 0.68, y: 0.70, width: 0.24, height: 0.22),
        ]
        return zip(items.prefix(layout.count), layout).map { item, rect in
            TapRegion(
                id: item.id, name: item.name, emoji: item.emoji,
                price: item.price, stock: item.stock(on: day)?.remaining ?? 0,
                color: item.swatch, rect: rect
            )
        }
    }

    private var main: some View {
        ScrollView {
            HStack {
                Spacer(); OshinagakiCanvas(regions: regions, onTap: handleTap).frame(maxWidth: 540); Spacer()
            }
            .padding(20)
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

    private func handleTap(_ region: TapRegion) {
        guard let item = event.items.first(where: { $0.id == region.id }) else { return }
        let remaining = item.stock(on: day)?.remaining ?? 0
        if remaining == 0 { oosItem = item } else { cart.add(item) }
    }
}
