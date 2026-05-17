import SwiftUI

struct StripedPlaceholder: View {
    var body: some View {
        Canvas { ctx, size in
            let backgroundColor = Color(hex: "#F4F1EA")
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(backgroundColor))
            let stripeColor = Color(hex: "#E9E5DD")
            let gap: CGFloat = 18
            let diagonal = max(size.width, size.height) * 1.5
            var origin = -diagonal
            while origin < diagonal {
                var path = Path()
                path.move(to: CGPoint(x: origin, y: -diagonal))
                path.addLine(to: CGPoint(x: origin + diagonal * 2, y: diagonal))
                ctx.stroke(path, with: .color(stripeColor), lineWidth: 1)
                origin += gap
            }
        }
    }
}
