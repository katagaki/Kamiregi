import SwiftUI

struct StripedPlaceholder: View {
    var body: some View {
        Canvas { ctx, size in
            let bg = Color(hex: "#F4F1EA")
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(bg))
            let stripe = Color(hex: "#E9E5DD")
            let gap: CGFloat = 18
            let diagonal = max(size.width, size.height) * 1.5
            var x = -diagonal
            while x < diagonal {
                var p = Path()
                p.move(to: CGPoint(x: x, y: -diagonal))
                p.addLine(to: CGPoint(x: x + diagonal * 2, y: diagonal))
                ctx.stroke(p, with: .color(stripe), lineWidth: 1)
                x += gap
            }
        }
    }
}
