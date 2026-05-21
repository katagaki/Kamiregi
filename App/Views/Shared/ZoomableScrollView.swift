import SwiftUI
import UIKit

// Bridges to UIKit because SwiftUI's magnificationGesture can't anchor a zoom to
// the point under the user's fingers; UIScrollView does that (and pan) for free.
struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    private let aspect: CGSize
    private let minScale: CGFloat
    private let maxScale: CGFloat
    private let content: Content

    init(
        aspect: CGSize,
        minScale: CGFloat = 1.0,
        maxScale: CGFloat = 5.0,
        @ViewBuilder content: () -> Content
    ) {
        self.aspect = aspect
        self.minScale = minScale
        self.maxScale = maxScale
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(rootView: content)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = LayoutNotifyingScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = maxScale
        scrollView.bouncesZoom = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.clipsToBounds = false
        // Let a pinch/pan started over a tap region win over the region's tap.
        scrollView.delaysContentTouches = true
        scrollView.canCancelContentTouches = true
        scrollView.backgroundColor = .clear

        let hosted = context.coordinator.hostingController.view!
        hosted.backgroundColor = .clear
        hosted.translatesAutoresizingMaskIntoConstraints = true
        scrollView.addSubview(hosted)

        context.coordinator.scrollView = scrollView
        context.coordinator.aspect = aspect
        scrollView.onLayout = { [weak coordinator = context.coordinator] in
            coordinator?.relayout()
        }
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = maxScale
        context.coordinator.aspect = aspect
        context.coordinator.hostingController.rootView = content
        context.coordinator.relayout()
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        let hostingController: UIHostingController<Content>
        weak var scrollView: UIScrollView?
        var aspect = CGSize(width: 1, height: 1)

        private var lastBounds: CGSize = .zero
        private var lastAspect: CGSize = .zero

        init(rootView: Content) {
            hostingController = UIHostingController(rootView: rootView)
            hostingController.view.backgroundColor = .clear
            super.init()
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostingController.view
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerContent()
        }

        // Only reset when bounds/aspect change, so scroll/zoom passes keep the user's zoom.
        func relayout() {
            guard let scrollView else { return }
            let bounds = scrollView.bounds.size
            guard bounds.width > 0, bounds.height > 0, aspect.width > 0, aspect.height > 0 else { return }

            let boundsChanged = abs(bounds.width - lastBounds.width) > 0.5
                || abs(bounds.height - lastBounds.height) > 0.5
            let aspectChanged = abs(aspect.width - lastAspect.width) > 0.5
                || abs(aspect.height - lastAspect.height) > 0.5
            guard boundsChanged || aspectChanged else { return }

            let fitScale = min(bounds.width / aspect.width, bounds.height / aspect.height)
            let contentSize = CGSize(width: aspect.width * fitScale, height: aspect.height * fitScale)
            scrollView.setZoomScale(1.0, animated: false)
            hostingController.view.frame = CGRect(origin: .zero, size: contentSize)
            scrollView.contentSize = contentSize
            lastBounds = bounds
            lastAspect = aspect
            centerContent()
        }

        private func centerContent() {
            guard let scrollView else { return }
            let viewport = scrollView.bounds.size
            let content = scrollView.contentSize
            let horizontal = max(0, (viewport.width - content.width) / 2)
            let vertical = max(0, (viewport.height - content.height) / 2)
            scrollView.contentInset = UIEdgeInsets(
                top: vertical, left: horizontal, bottom: vertical, right: horizontal
            )
        }
    }
}

private final class LayoutNotifyingScrollView: UIScrollView {
    var onLayout: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
    }
}
