import SwiftUI

struct ExportMenu: View {
    let event: Event
    var currentDay: EventDay?

    var body: some View {
        Menu {
            if let url = xlsxURL {
                ShareLink(item: url) {
                    Label("export.excel", systemImage: "tablecells")
                }
            }
            if let day = currentDay ?? event.sortedDays.first,
               let url = try? EventExporter.csvFile(for: day, in: event) {
                ShareLink(item: url) {
                    Label("export.csv", systemImage: "doc.text")
                }
            }
        } label: {
            Label("event.detail.export", systemImage: "square.and.arrow.up")
        }
    }

    private var xlsxURL: URL? {
        guard !event.sortedDays.isEmpty else { return nil }
        return try? EventExporter.xlsxFile(for: event)
    }
}
