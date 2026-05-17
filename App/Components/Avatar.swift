import SwiftUI

struct Avatar: View {
    var name: String
    var picked: Bool = false

    private static let palette = ["#FFE4DC", "#DFEEFF", "#E0F4E2", "#FFF4D6", "#EBE3FF", "#FFE2EE", "#FFE9CF"]
    private static let foreground = ["#C7372A", "#1F5AA6", "#1E8A38", "#A07300", "#6A3FB0", "#B43374", "#9C5F00"]

    var body: some View {
        let initial = String(name.trimmingCharacters(in: .whitespaces).first ?? "?")
        let idx = abs(Int(name.unicodeScalars.first?.value ?? 0)) % Self.palette.count
        ZStack(alignment: .bottomTrailing) {
            Text(initial)
                .font(.body.weight(.bold))
                .foregroundStyle(Color(hex: Self.foreground[idx]))
                .frame(width: 44, height: 44)
                .background(Color(hex: Self.palette[idx]), in: Circle())
                .opacity(picked ? 0.45 : 1)
            if picked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white, .green)
                    .background(Color(.systemBackground), in: Circle())
                    .offset(x: 2, y: 2)
            }
        }
    }
}
