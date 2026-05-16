import SwiftUI

struct EventRow: View {
    var event: Event
    var isLive: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.title2)
                .foregroundStyle(event.color)
                .frame(width: 44, height: 44)
                .background(event.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(event.name)
                        .font(.headline)
                    if isLive {
                        Text("events.live")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.18), in: Capsule())
                    }
                }
                Text("\(event.venue) · \(event.booth)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}
