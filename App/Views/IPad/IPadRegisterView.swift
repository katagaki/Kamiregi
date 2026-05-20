import SwiftUI
import SwiftData
import PhotosUI

struct IPadRegisterView: View {
    @AppStorage("currency") private var currency: Currency = .yen
    @Environment(\.modelContext) private var context
    @Bindable var event: Event
    @Bindable var day: EventDay
    @Bindable var cart: CartStore
    @State private var mode: RegisterMode = .grid
    @State private var oosItem: InventoryItem?
    @State private var showPayment = false
    @State private var showEdit = false
    @State private var photosPick: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var showClearConfirm = false

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
                    POSCartBar(cart: cart) { showPayment = true }
                        .frame(maxWidth: 320)
                        .padding()
                }
            }
        }
        .background(Color(.systemGroupedBackground))
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
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("oshinagaki.edit.image.change", systemImage: "photo") {
                            showPhotoPicker = true
                        }
                        Button("oshinagaki.edit.clear", systemImage: "trash.slash", role: .destructive) {
                            showClearConfirm = true
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photosPick, matching: .images)
        .onChange(of: photosPick) { _, newValue in
            Task { await loadPhoto(newValue) }
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
        .confirmationDialog(
            "oshinagaki.clear.confirm.title",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("common.delete", role: .destructive) { clearAllRegions() }
            Button("common.cancel", role: .cancel) { }
        } message: {
            Text("oshinagaki.clear.confirm.message")
        }
        .sheet(isPresented: $showEdit) {
            OshinagakiEditView(event: event, day: day)
        }
        .sheet(isPresented: $showPayment) {
            PaymentSheet(cart: cart, event: event, day: day) { showPayment = false }
        }
    }

    private var sortedItems: [InventoryItem] {
        event.items.sorted { $0.sortIndex < $1.sortIndex }
    }

    private var main: some View {
        ZStack {
            switch mode {
            case .grid:
                if sortedItems.isEmpty {
                    ContentUnavailableView("pos.title", systemImage: "cart")
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 12)],
                            spacing: 12
                        ) {
                            ForEach(sortedItems, id: \.id) { item in
                                POSGridCard(item: item, day: day, cart: cart) { tap(item) }
                            }
                        }
                        .padding(20)
                    }
                }
            case .list:
                if sortedItems.isEmpty {
                    ContentUnavailableView("pos.title", systemImage: "cart")
                } else {
                    List(sortedItems, id: \.id) { item in
                        POSListRow(item: item, day: day, cart: cart) { tap(item) }
                    }
                }
            case .oshinagaki:
                ScrollView {
                    HStack {
                        Spacer()
                        OshinagakiCanvas(
                            imageData: event.oshinagakiImage,
                            items: event.items,
                            day: day,
                            cart: cart,
                            onTap: tap
                        )
                        .frame(maxWidth: 540)
                        Spacer()
                    }
                    .padding(20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var cartPane: some View {
        VStack(spacing: 0) {
            HStack {
                Text("pos.cart.title")
                    .font(.headline)
                Spacer()
                Button("pos.cart.clear", role: .destructive) { cart.clear() }
                    .buttonStyle(.borderless)
                    .disabled(cart.lines.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            Divider()

            if cart.lines.isEmpty {
                ContentUnavailableView(
                    "pos.cart.title",
                    systemImage: "cart",
                    description: Text("pos.cart.subtotal")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(cart.lines.enumerated()), id: \.element.id) { idx, line in
                            CartLineRow(line: line, cart: cart)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            if idx < cart.lines.count - 1 {
                                Divider().padding(.leading, 72)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Button { showPayment = true } label: {
                HStack {
                    Text("pos.cart.continue")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(currency.format(cart.subtotal))
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .frame(height: 56)
                .glassEffect(.regular.tint(Brand.tint).interactive(), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(cart.lines.isEmpty)
            .padding(16)
        }
    }

    private func tap(_ item: InventoryItem) {
        let remaining = max(0, (item.stock(on: day)?.remaining ?? 0) - cart.qty(for: item))
        if remaining == 0 { oosItem = item } else { cart.add(item) }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            await MainActor.run {
                event.oshinagakiImage = data
                try? context.save()
            }
        }
    }

    private func clearAllRegions() {
        for item in event.items { item.regionRect = .zero }
        try? context.save()
    }
}
