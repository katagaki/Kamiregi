import SwiftUI
import SwiftData

struct ReservationRow: View {
    @AppStorage("currency") private var currency: Currency = .yen
    @Bindable var res: Reservation
    var onEdit: () -> Void
    @State private var showConfirm = false
    @State private var profileImage: UIImage?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Avatar(name: res.name, image: profileImage, picked: res.pickedUp)
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
                Text(res.handle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !res.lines.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(res.sortedLines, id: \.id) { line in
                            HStack(spacing: 6) {
                                Text(line.displayName)
                                Text(verbatim: "×\(line.qty)")
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            .font(.footnote)
                            .foregroundStyle(res.pickedUp ? .secondary : .primary)
                        }
                    }
                    .padding(.top, 2)
                }
                if !res.note.isEmpty {
                    Text(res.note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 6) {
                Text(currency.format(res.total))
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
        .contentShape(Rectangle())
        .onTapGesture { onEdit() }
        .task(id: "\(res.contactRaw)|\(res.handle)") {
            guard res.contact == .sns else {
                profileImage = nil
                return
            }
            profileImage = await ProfileImageFetcher.shared.fetch(for: res.handle)
        }
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
