import SwiftData
import SwiftUI

// Editable canvas: shows the image + each item's region rect with handles.
// Tap a region to select it; drag the center to move; drag any of the four
// corner handles to resize. Coordinates are stored in unit space (0..1).
struct OshinagakiEditCanvas: View {
    var imageData: Data?
    var items: [InventoryItem]
    @Binding var selectedItemID: PersistentIdentifier?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                background

                ForEach(itemsWithRegions, id: \.persistentModelID) { item in
                    OshinagakiEditableRegion(
                        item: item,
                        canvasSize: geo.size,
                        isSelected: selectedItemID == item.persistentModelID
                    )
                    .onTapGesture {
                        selectedItemID = item.persistentModelID
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectedItemID = nil
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
        }
        .aspectRatio(1.0 / 1.34, contentMode: .fit)
    }

    private var itemsWithRegions: [InventoryItem] {
        items.filter { $0.hasRegion }
    }

    @ViewBuilder
    private var background: some View {
        if let data = imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                StripedPlaceholder()
                Text("oshinagaki.empty.tap_to_pick")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(.regularMaterial, in: Capsule())
            }
        }
    }
}

private struct OshinagakiEditableRegion: View {
    @Bindable var item: InventoryItem
    let canvasSize: CGSize
    let isSelected: Bool

    @GestureState private var moveDelta: CGSize = .zero
    @GestureState private var resizeDelta: ResizeDelta = .zero

    private struct ResizeDelta {
        var originDx: CGFloat = 0
        var originDy: CGFloat = 0
        var widthDelta: CGFloat = 0
        var heightDelta: CGFloat = 0
        static let zero = ResizeDelta()
    }

    private enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    var body: some View {
        let liveRect = computeLiveRect()
        let strokeColor: Color = isSelected ? Brand.tint : Brand.tint.opacity(0.6)

        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Brand.tint.opacity(0.18) : Color.white.opacity(0.15))
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(strokeColor, style: StrokeStyle(lineWidth: 2, dash: isSelected ? [] : [4, 3]))

            Text(item.name)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Brand.tint, in: Capsule())
        }
        .frame(width: liveRect.width, height: liveRect.height)
        .position(x: liveRect.midX, y: liveRect.midY)
        .gesture(moveGesture)
        .overlay(handlesOverlay(rect: liveRect))
    }

    // MARK: live rect computation

    private func computeLiveRect() -> CGRect {
        let baseX = item.regionX * canvasSize.width + resizeDelta.originDx + moveDelta.width
        let baseY = item.regionY * canvasSize.height + resizeDelta.originDy + moveDelta.height
        let baseWidth = max(40, item.regionWidth * canvasSize.width + resizeDelta.widthDelta)
        let baseHeight = max(40, item.regionHeight * canvasSize.height + resizeDelta.heightDelta)
        return CGRect(x: baseX, y: baseY, width: baseWidth, height: baseHeight)
    }

    // MARK: gestures

    private var moveGesture: some Gesture {
        DragGesture()
            .updating($moveDelta) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                commitMove(by: value.translation)
            }
    }

    private func commitMove(by translation: CGSize) {
        let unitDx = translation.width / canvasSize.width
        let unitDy = translation.height / canvasSize.height
        var rect = item.regionRect
        rect.origin.x = clamp(rect.origin.x + unitDx, lower: 0, upper: 1 - rect.width)
        rect.origin.y = clamp(rect.origin.y + unitDy, lower: 0, upper: 1 - rect.height)
        item.regionRect = rect
    }

    // MARK: corner handles

    @ViewBuilder
    private func handlesOverlay(rect: CGRect) -> some View {
        if isSelected {
            ZStack {
                handle(at: CGPoint(x: rect.minX, y: rect.minY), corner: .topLeft)
                handle(at: CGPoint(x: rect.maxX, y: rect.minY), corner: .topRight)
                handle(at: CGPoint(x: rect.minX, y: rect.maxY), corner: .bottomLeft)
                handle(at: CGPoint(x: rect.maxX, y: rect.maxY), corner: .bottomRight)
            }
            .allowsHitTesting(true)
        }
    }

    private func handle(at point: CGPoint, corner: Corner) -> some View {
        Circle()
            .fill(.white)
            .overlay(Circle().stroke(Brand.tint, lineWidth: 2))
            .frame(width: 18, height: 18)
            .position(x: point.x, y: point.y)
            .gesture(resizeGesture(for: corner))
    }

    private func resizeGesture(for corner: Corner) -> some Gesture {
        DragGesture()
            .updating($resizeDelta) { value, state, _ in
                state = delta(for: corner, translation: value.translation)
            }
            .onEnded { value in
                commitResize(corner: corner, translation: value.translation)
            }
    }

    private func delta(for corner: Corner, translation: CGSize) -> ResizeDelta {
        switch corner {
        case .topLeft:
            return ResizeDelta(
                originDx: translation.width,
                originDy: translation.height,
                widthDelta: -translation.width,
                heightDelta: -translation.height
            )
        case .topRight:
            return ResizeDelta(
                originDx: 0,
                originDy: translation.height,
                widthDelta: translation.width,
                heightDelta: -translation.height
            )
        case .bottomLeft:
            return ResizeDelta(
                originDx: translation.width,
                originDy: 0,
                widthDelta: -translation.width,
                heightDelta: translation.height
            )
        case .bottomRight:
            return ResizeDelta(
                originDx: 0,
                originDy: 0,
                widthDelta: translation.width,
                heightDelta: translation.height
            )
        }
    }

    private func commitResize(corner: Corner, translation: CGSize) {
        let unitDx = translation.width / canvasSize.width
        let unitDy = translation.height / canvasSize.height
        var rect = item.regionRect
        let minSize: CGFloat = 0.05

        switch corner {
        case .topLeft:
            let newX = clamp(rect.origin.x + unitDx, lower: 0, upper: rect.maxX - minSize)
            let newY = clamp(rect.origin.y + unitDy, lower: 0, upper: rect.maxY - minSize)
            rect.size.width += rect.origin.x - newX
            rect.size.height += rect.origin.y - newY
            rect.origin.x = newX
            rect.origin.y = newY
        case .topRight:
            let newY = clamp(rect.origin.y + unitDy, lower: 0, upper: rect.maxY - minSize)
            let newWidth = clamp(rect.width + unitDx, lower: minSize, upper: 1 - rect.origin.x)
            rect.size.height += rect.origin.y - newY
            rect.origin.y = newY
            rect.size.width = newWidth
        case .bottomLeft:
            let newX = clamp(rect.origin.x + unitDx, lower: 0, upper: rect.maxX - minSize)
            let newHeight = clamp(rect.height + unitDy, lower: minSize, upper: 1 - rect.origin.y)
            rect.size.width += rect.origin.x - newX
            rect.origin.x = newX
            rect.size.height = newHeight
        case .bottomRight:
            rect.size.width = clamp(rect.width + unitDx, lower: minSize, upper: 1 - rect.origin.x)
            rect.size.height = clamp(rect.height + unitDy, lower: minSize, upper: 1 - rect.origin.y)
        }

        item.regionRect = rect
    }

    private func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        Swift.max(lower, Swift.min(upper, value))
    }
}
