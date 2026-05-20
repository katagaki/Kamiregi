import SwiftUI

struct ItemThumbnail: View {
    var name: String
    var photoData: Data?
    var size: CGFloat = 44
    var cornerRadius: CGFloat = 10

    var body: some View {
        Group {
            if let data = photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                let colors = Self.colors(for: name)
                ZStack {
                    colors.bg
                    Text(String(name.trimmingCharacters(in: .whitespaces).first ?? "?"))
                        .font(.system(size: size * 0.4, weight: .bold))
                        .foregroundStyle(colors.fg)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    static func colors(for name: String) -> (bg: Color, fg: Color) {
        let idx = abs(Int(name.unicodeScalars.first?.value ?? 0)) % palette.count
        return (Color(hex: palette[idx].bg), Color(hex: palette[idx].fg))
    }

    private static let palette: [(bg: String, fg: String)] = [
        ("#FFE4DC", "#C7372A"),
        ("#DFEEFF", "#1F5AA6"),
        ("#E0F4E2", "#1E8A38"),
        ("#FFF4D6", "#A07300"),
        ("#EBE3FF", "#6A3FB0"),
        ("#FFE2EE", "#B43374"),
        ("#FFE9CF", "#9C5F00"),
        ("#E6F4F1", "#1A6E5E")
    ]
}
