import Foundation
import SwiftData

enum SampleData {
    @MainActor
    static func seedIfEmpty(container: ModelContainer) async {
        let context = container.mainContext
        let descriptor = FetchDescriptor<Event>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        // Build "コミティア150"
        let comitia = Event(
            name: "コミティア150",
            venue: "東京ビッグサイト",
            booth: "え-21b",
            colorHex: "#FF5A4E"
        )
        context.insert(comitia)

        let d1 = makeDate(2026, 5, 5)
        let d2 = makeDate(2026, 5, 6)
        let day1 = EventDay(date: d1, label: "初日 · 5月5日")
        let day2 = EventDay(date: d2, label: "2日目 · 5月6日")
        comitia.days = [day1, day2]

        let comitiaItems: [(name: String, sub: String, price: Int, stock: Int, sold: Int, emoji: String, swatch: String)] = [
            ("夏の終わりに",          "B5新刊・100頁", 1200, 60, 18, "📕", "#FFE4DC"),
            ("残響レコード",          "B5新刊・80頁",  1000, 45, 14, "📘", "#DFEEFF"),
            ("海猫荘の夜",            "A5既刊・64頁",  800,  26,  8, "📗", "#E0F4E2"),
            ("アクリルキーホルダー",  "4種 / 各",      600,  82, 22, "🔑", "#FFF4D6"),
            ("缶バッジセット",        "3個セット",     500,  24, 24, "🟡", "#FFE2EE"),
            ("ポストカード4種",       "4枚セット",     400,  34,  6, "✉️", "#EBE3FF"),
            ("ステッカー",            "1枚",           200, 100, 12, "⭐", "#FFE9CF"),
            ("おまけ無配",            "ペーパー",       0,   80, 30, "🎁", "#E6F4F1"),
        ]
        for (idx, raw) in comitiaItems.enumerated() {
            let item = InventoryItem(
                name: raw.name,
                sub: raw.sub,
                price: raw.price,
                emoji: raw.emoji,
                swatchHex: raw.swatch,
                sortIndex: idx
            )
            comitia.items.append(item)
            // Day 1 stock (with sales)
            let stock1 = DailyStock(initial: raw.stock, sold: raw.sold)
            stock1.item = item
            stock1.day = day1
            context.insert(stock1)
            // Day 2 stock (fresh)
            let stock2 = DailyStock(initial: max(20, raw.stock / 2), sold: 0)
            stock2.item = item
            stock2.day = day2
            context.insert(stock2)
        }

        // Seed sample transactions for day 1
        let sampleTx: [(time: String, total: Int, paid: Int, lines: [(String, Int, Int)])] = [
            ("10:14", 2400, 3000, [("夏の終わりに", 1, 1200), ("アクリルキーホルダー", 2, 600)]),
            ("10:21", 1000, 1000, [("残響レコード", 1, 1000)]),
            ("10:33", 1600, 2000, [("夏の終わりに", 1, 1200), ("ステッカー", 2, 200)]),
            ("10:47", 3200, 5000, [("夏の終わりに", 1, 1200), ("残響レコード", 1, 1000), ("海猫荘の夜", 1, 800), ("ステッカー", 1, 200)]),
            ("11:02", 800, 1000,  [("海猫荘の夜", 1, 800)]),
            ("11:09", 1700, 2000, [("アクリルキーホルダー", 2, 600), ("ポストカード4種", 1, 400), ("ステッカー", 1, 200)]),
            ("11:24", 2000, 2000, [("残響レコード", 1, 1000), ("アクリルキーホルダー", 1, 600), ("ポストカード4種", 1, 400)]),
            ("11:38", 1200, 1500, [("夏の終わりに", 1, 1200)]),
            ("11:51",  600, 1000, [("アクリルキーホルダー", 1, 600)]),
        ]
        for (idx, raw) in sampleTx.enumerated() {
            let tx = SaleTransaction(
                number: idx + 1,
                timestamp: parseTime(raw.time, on: d1),
                total: raw.total,
                paid: raw.paid
            )
            tx.day = day1
            for (n, q, p) in raw.lines {
                let line = TransactionLine(itemName: n, qty: q, unitPrice: p)
                tx.lines.append(line)
                context.insert(line)
            }
            context.insert(tx)
        }

        // Reservations on day 1
        let reservations: [(name: String, handle: String, kind: ContactKind, note: String, total: Int, picked: Bool)] = [
            ("山田 こはる",   "@koharu_y",  .sns,  "夏の終わりに ×2、海猫荘の夜 ×1", 3200, false),
            ("佐藤 真央",     "mao.sato@…", .mail, "残響レコード ×1、ステッカー全種",  1400, true),
            ("Anna Müller",   "+49 30 …",   .tel,  "新刊セット",                       3000, false),
            ("高橋 ゆず",     "@yuzu_dot",  .sns,  "夏の終わりに ×1",                  1200, false),
        ]
        for r in reservations {
            let res = Reservation(
                name: r.name,
                handle: r.handle,
                contact: r.kind,
                note: r.note,
                total: r.total,
                pickedUp: r.picked
            )
            res.day = day1
            context.insert(res)
        }

        // Past events
        let past1 = Event(name: "コミティア149", venue: "東京ビッグサイト", booth: "え-08a", colorHex: "#5A8DEE", isPastEvent: true)
        past1.createdAt = makeDate(2026, 2, 11)
        let past1Day = EventDay(date: makeDate(2026, 2, 11), label: "完了")
        past1.days = [past1Day]
        context.insert(past1)

        let past2 = Event(name: "コミックマーケット106", venue: "東京ビッグサイト", booth: "東-A11b", colorHex: "#34C759", isPastEvent: true)
        past2.createdAt = makeDate(2025, 12, 30)
        let past2Day = EventDay(date: makeDate(2025, 12, 30), label: "完了")
        past2.days = [past2Day]
        context.insert(past2)

        try? context.save()
    }

    private static func makeDate(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d)) ?? Date()
    }

    private static func parseTime(_ s: String, on date: Date) -> Date {
        let parts = s.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return date }
        return Calendar.current.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: date) ?? date
    }
}
