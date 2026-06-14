import SwiftUI
import SwiftData
import UIKit

enum FlyVisual {
    case image(UIImage)
    case letter(String)
}

struct CartFlight: Identifiable {
    let id = UUID()
    var visual: FlyVisual
    var start: CGRect
    var corner: CGFloat
    var fadeOnly: Bool
    var targetItemID: PersistentIdentifier?
}

@MainActor
@Observable
final class CartFlightController {
    var flights: [CartFlight] = []

    var cartBarAnchor: CGRect = .zero
    var sidebarListAnchor: CGRect = .zero
    var sourceAnchors: [PersistentIdentifier: CGRect] = [:]
    var sidebarRowAnchors: [PersistentIdentifier: CGRect] = [:]

    var bounceToken = 0
    var rowPulseTokens: [PersistentIdentifier: Int] = [:]

    /// The right sidebar is on screen when its list area has reported a frame.
    var sidebarActive: Bool { sidebarListAnchor != .zero }

    func launch(_ flight: CartFlight) {
        flights.append(flight)
        if flights.count > 6 { flights.removeFirst(flights.count - 6) }
    }

    func finish(_ flight: CartFlight) {
        if sidebarActive {
            if let id = flight.targetItemID, sidebarRowAnchors[id] != nil {
                rowPulseTokens[id, default: 0] &+= 1
            }
        } else {
            bounceToken &+= 1
        }
        flights.removeAll { $0.id == flight.id }
    }

    func rowAnchor(for flight: CartFlight) -> CGRect? {
        guard let id = flight.targetItemID, let row = sidebarRowAnchors[id], row != .zero else { return nil }
        return row
    }

    func target(for flight: CartFlight, fallback: CGRect) -> CGRect {
        if let row = rowAnchor(for: flight) { return row }
        if sidebarListAnchor != .zero { return sidebarListAnchor }
        if cartBarAnchor != .zero { return cartBarAnchor }
        return fallback
    }
}

enum CartFlightFactory {
    static func visual(for item: InventoryItem) -> FlyVisual {
        if let data = item.photoData, let image = UIImage(data: data) { return .image(image) }
        return .letter(item.name)
    }

    static func oshinagakiVisual(for item: InventoryItem, background: Data?) -> FlyVisual {
        if let cropped = croppedBackground(item: item, background: background) { return .image(cropped) }
        return visual(for: item)
    }

    private static func croppedBackground(item: InventoryItem, background: Data?) -> UIImage? {
        guard let data = background, let image = UIImage(data: data), let cgImage = image.cgImage else { return nil }
        let rect = item.regionRect
        guard rect.width > 0, rect.height > 0 else { return nil }
        let width = CGFloat(cgImage.width), height = CGFloat(cgImage.height)
        let crop = CGRect(
            x: rect.minX * width,
            y: rect.minY * height,
            width: rect.width * width,
            height: rect.height * height
        ).integral
        guard let sub = cgImage.cropping(to: crop) else { return nil }
        return UIImage(cgImage: sub, scale: image.scale, orientation: image.imageOrientation)
    }
}

private struct GlobalFrameReporter: ViewModifier {
    var onChange: (CGRect) -> Void
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { onChange(proxy.frame(in: .global)) }
                    .onChange(of: proxy.frame(in: .global)) { _, new in onChange(new) }
            }
        )
    }
}

extension View {
    func reportGlobalFrame(_ onChange: @escaping (CGRect) -> Void) -> some View {
        modifier(GlobalFrameReporter(onChange: onChange))
    }
}

struct CartFlightOverlay: View {
    @Bindable var controller: CartFlightController

    var body: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .global)
            let fallback = CGRect(x: frame.maxX - 110, y: frame.maxY - 96, width: 64, height: 64)
            ZStack {
                ForEach(controller.flights) { flight in
                    CartFlightView(
                        flight: flight,
                        controller: controller,
                        overlayOrigin: frame.origin,
                        fallbackTarget: fallback
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

private struct CartFlightView: View {
    let flight: CartFlight
    @Bindable var controller: CartFlightController
    let overlayOrigin: CGPoint
    let fallbackTarget: CGRect
    @State private var arrived = false

    var body: some View {
        let target = controller.target(for: flight, fallback: fallbackTarget)
        let from = center(of: flight.start)
        let end = center(of: target)
        let size = arrived ? target.size : flight.start.size

        visual(size: size)
            .opacity(arrived ? 0 : 1)
            .animation(.easeOut(duration: 0.3), value: arrived)
            .position(arrived ? end : from)
            .onAppear { begin() }
    }

    private func center(of rect: CGRect) -> CGPoint {
        CGPoint(x: rect.midX - overlayOrigin.x, y: rect.midY - overlayOrigin.y)
    }

    private func begin() {
        Task { @MainActor in
            // A freshly inserted sidebar row needs a layout pass before its frame is known.
            var attempts = 0
            while controller.sidebarActive,
                  flight.targetItemID != nil,
                  controller.rowAnchor(for: flight) == nil,
                  attempts < 12 {
                try? await Task.sleep(for: .milliseconds(16))
                attempts += 1
            }
            let animation: Animation = flight.fadeOnly
                ? .easeOut(duration: 0.5)
                : .spring(response: 0.5, dampingFraction: 0.82)
            withAnimation(animation) {
                arrived = true
            } completion: {
                controller.finish(flight)
            }
        }
    }

    @ViewBuilder
    private func visual(size: CGSize) -> some View {
        Group {
            switch flight.visual {
            case .image(let image):
                Image(uiImage: image).resizable().scaledToFill()
            case .letter(let name):
                let colors = ItemThumbnail.colors(for: name)
                ZStack {
                    colors.bg
                    Text(String(name.trimmingCharacters(in: .whitespaces).first ?? "?"))
                        .font(.system(size: max(12, size.height * 0.4), weight: .bold))
                        .foregroundStyle(colors.fg)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: flight.corner, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
    }
}
