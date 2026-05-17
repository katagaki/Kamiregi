import SwiftUI
import SwiftData

struct OshinagakiView: View {
    @Bindable var event: Event
    @Bindable var day: EventDay
    @State private var showEdit = false
    @State private var oosItem: InventoryItem?
    @State private var cart = CartStore()
    @State private var showPayment = false

    var body: some View {
        Group {
            if event.oshinagakiImage == nil && event.items.allSatisfy({ !$0.hasRegion }) {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        OshinagakiCanvas(
                            imageData: event.oshinagakiImage,
                            items: event.items,
                            day: day,
                            onTap: handleTap
                        )
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 120)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom) {
            POSCartBar(cart: cart) { showPayment = true }
        }
        .navigationTitle("oshinagaki.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showEdit = true } label: {
                    Label("common.edit", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            OshinagakiEditView(event: event, day: day)
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

    private var emptyState: some View {
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
    }

    private func handleTap(_ item: InventoryItem) {
        let remaining = item.stock(on: day)?.remaining ?? 0
        if remaining == 0 { oosItem = item } else { cart.add(item) }
    }
}
