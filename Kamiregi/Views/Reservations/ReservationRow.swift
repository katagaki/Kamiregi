import SwiftUI
import SwiftData

struct ReservationRow: View {
    @Bindable var res: Reservation
    @State private var showConfirm = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Avatar(name: res.name, picked: res.pickedUp)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(res.name)
                        .font(.body.weight(.semibold))
                        .strikethrough(res.pickedUp)
                        .foregroundStyle(res.pickedUp ? .secondary : .primary)
                    if res.pickedUp {
                        Text("reservations.received")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.18), in: Capsule())
                    }
                }
                Label {
                    Text(res.handle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: res.contact.systemImage)
                        .foregroundStyle(res.contact.color)
                        .font(.caption)
                }
                Text(res.note)
                    .font(.footnote)
                    .foregroundStyle(res.pickedUp ? .secondary : .primary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 6) {
                Text(yen(res.total))
                    .font(.body.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(res.pickedUp ? .secondary : .primary)
                Button {
                    showConfirm = true
                } label: {
                    Image(systemName: res.pickedUp ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(res.pickedUp ? Color.green : Color.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
        .alert(
            res.pickedUp
                ? LocalizedStringKey("reservations.confirm.revert.title")
                : LocalizedStringKey("reservations.confirm.pickup.title"),
            isPresented: $showConfirm
        ) {
            Button(res.pickedUp
                   ? LocalizedStringKey("reservations.confirm.revert.action")
                   : LocalizedStringKey("reservations.confirm.pickup.action")) {
                res.pickedUp.toggle()
            }
            Button("common.cancel", role: .cancel) {}
        }
    }
}

extension ContactKind {
    var systemImage: String {
        switch self {
        case .sns:  "at"
        case .mail: "envelope"
        case .tel:  "phone"
        }
    }
    var color: Color {
        switch self {
        case .sns:  .purple
        case .mail: .blue
        case .tel:  .green
        }
    }
}
