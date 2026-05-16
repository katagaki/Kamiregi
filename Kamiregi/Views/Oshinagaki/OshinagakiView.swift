import SwiftUI
import SwiftData

struct OshinagakiView: View {
    @Environment(\.modelContext) private var context
    @Bindable var event: Event
    @Bindable var day: EventDay
    @State private var showEdit = false
    @State private var oosItem: InventoryItem?
    @State private var cart = CartStore()
    @State private var showCart = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                OshinagakiCanvas(regions: regions, onTap: handleTap)
                    .padding(.horizontal, 16)

                fileBanner
                    .padding(.horizontal, 16)
            }
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom) {
            POSCartBar(cart: cart) { showCart = true }
        }
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
        .sheet(isPresented: $showEdit) {
            OshinagakiEditView(regions: regions)
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

    private var fileBanner: some View {
        GroupBox {
            Label("\(event.name)_\(String(localized: "oshinagaki.title")).png", systemImage: "photo")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func handleTap(_ region: TapRegion) {
        guard let item = event.items.first(where: { $0.id == region.id }) else { return }
        let remaining = item.stock(on: day)?.remaining ?? 0
        if remaining == 0 { oosItem = item } else { cart.add(item) }
    }
}
