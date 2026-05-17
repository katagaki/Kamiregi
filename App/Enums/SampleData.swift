import CoreGraphics
import Foundation
import SwiftData

enum SampleData {
    private struct ItemSeed {
        let name: String
        let sub: String
        let price: Int
        let stock: Int
        let sold: Int
    }

    private struct TransactionLineSeed {
        let itemName: String
        let qty: Int
        let unitPrice: Int
    }

    private struct TransactionSeed {
        let time: String
        let total: Int
        let paid: Int
        let lines: [TransactionLineSeed]
    }

    private struct ReservationSeed {
        let name: String
        let handle: String
        let kind: ContactKind
        let note: String
        let total: Int
        let picked: Bool
    }

    @MainActor
    static func seedIfEmpty(container: ModelContainer) async {
        let context = container.mainContext
        let descriptor = FetchDescriptor<Event>()
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }

        let comitia = Event(
            name: "コミティア150",
            venue: "東京ビッグサイト",
            booth: "え-21b",
            colorHex: "#FF5A4E"
        )
        context.insert(comitia)

        let firstDate = makeDate(year: 2026, month: 5, day: 5)
        let secondDate = makeDate(year: 2026, month: 5, day: 6)
        let day1 = EventDay(date: firstDate, label: "初日 · 5月5日")
        let day2 = EventDay(date: secondDate, label: "2日目 · 5月6日")
        comitia.days = [day1, day2]

        seedItems(into: comitia, day1: day1, day2: day2, context: context)
        seedTransactions(into: day1, on: firstDate, context: context)
        seedReservations(into: day1, context: context)
        seedPastEvents(context: context)

        try? context.save()
    }

    private static let comitiaItems: [ItemSeed] = [
        ItemSeed(name: "夏の終わりに", sub: "B5新刊・100頁", price: 1200, stock: 60, sold: 18),
        ItemSeed(name: "残響レコード", sub: "B5新刊・80頁", price: 1000, stock: 45, sold: 14),
        ItemSeed(name: "海猫荘の夜", sub: "A5既刊・64頁", price: 800, stock: 26, sold: 8),
        ItemSeed(name: "アクリルキーホルダー", sub: "4種 / 各", price: 600, stock: 82, sold: 22),
        ItemSeed(name: "缶バッジセット", sub: "3個セット", price: 500, stock: 24, sold: 24),
        ItemSeed(name: "ポストカード4種", sub: "4枚セット", price: 400, stock: 34, sold: 6),
        ItemSeed(name: "ステッカー", sub: "1枚", price: 200, stock: 100, sold: 12),
        ItemSeed(name: "おまけ無配", sub: "ペーパー", price: 0, stock: 80, sold: 30)
    ]

    private static let regionLayout: [CGRect] = [
        CGRect(x: 0.06, y: 0.08, width: 0.40, height: 0.30),
        CGRect(x: 0.52, y: 0.08, width: 0.40, height: 0.30),
        CGRect(x: 0.06, y: 0.42, width: 0.40, height: 0.22),
        CGRect(x: 0.52, y: 0.42, width: 0.19, height: 0.22),
        CGRect(x: 0.73, y: 0.42, width: 0.19, height: 0.22),
        CGRect(x: 0.06, y: 0.70, width: 0.28, height: 0.22),
        CGRect(x: 0.38, y: 0.70, width: 0.26, height: 0.22),
        CGRect(x: 0.68, y: 0.70, width: 0.24, height: 0.22)
    ]

    private static func seedItems(into event: Event, day1: EventDay, day2: EventDay, context: ModelContext) {
        for (idx, seed) in comitiaItems.enumerated() {
            let item = InventoryItem(
                name: seed.name,
                sub: seed.sub,
                price: seed.price,
                sortIndex: idx
            )
            if idx < regionLayout.count {
                item.regionRect = regionLayout[idx]
            }
            event.items.append(item)

            let stockDay1 = DailyStock(initial: seed.stock, sold: seed.sold)
            stockDay1.item = item
            stockDay1.day = day1
            context.insert(stockDay1)

            let stockDay2 = DailyStock(initial: max(20, seed.stock / 2), sold: 0)
            stockDay2.item = item
            stockDay2.day = day2
            context.insert(stockDay2)
        }
    }

    private static let sampleTransactions: [TransactionSeed] = [
        TransactionSeed(time: "10:14", total: 2400, paid: 3000, lines: [
            TransactionLineSeed(itemName: "夏の終わりに", qty: 1, unitPrice: 1200),
            TransactionLineSeed(itemName: "アクリルキーホルダー", qty: 2, unitPrice: 600)
        ]),
        TransactionSeed(time: "10:21", total: 1000, paid: 1000, lines: [
            TransactionLineSeed(itemName: "残響レコード", qty: 1, unitPrice: 1000)
        ]),
        TransactionSeed(time: "10:33", total: 1600, paid: 2000, lines: [
            TransactionLineSeed(itemName: "夏の終わりに", qty: 1, unitPrice: 1200),
            TransactionLineSeed(itemName: "ステッカー", qty: 2, unitPrice: 200)
        ]),
        TransactionSeed(time: "10:47", total: 3200, paid: 5000, lines: [
            TransactionLineSeed(itemName: "夏の終わりに", qty: 1, unitPrice: 1200),
            TransactionLineSeed(itemName: "残響レコード", qty: 1, unitPrice: 1000),
            TransactionLineSeed(itemName: "海猫荘の夜", qty: 1, unitPrice: 800),
            TransactionLineSeed(itemName: "ステッカー", qty: 1, unitPrice: 200)
        ]),
        TransactionSeed(time: "11:02", total: 800, paid: 1000, lines: [
            TransactionLineSeed(itemName: "海猫荘の夜", qty: 1, unitPrice: 800)
        ]),
        TransactionSeed(time: "11:09", total: 1700, paid: 2000, lines: [
            TransactionLineSeed(itemName: "アクリルキーホルダー", qty: 2, unitPrice: 600),
            TransactionLineSeed(itemName: "ポストカード4種", qty: 1, unitPrice: 400),
            TransactionLineSeed(itemName: "ステッカー", qty: 1, unitPrice: 200)
        ]),
        TransactionSeed(time: "11:24", total: 2000, paid: 2000, lines: [
            TransactionLineSeed(itemName: "残響レコード", qty: 1, unitPrice: 1000),
            TransactionLineSeed(itemName: "アクリルキーホルダー", qty: 1, unitPrice: 600),
            TransactionLineSeed(itemName: "ポストカード4種", qty: 1, unitPrice: 400)
        ]),
        TransactionSeed(time: "11:38", total: 1200, paid: 1500, lines: [
            TransactionLineSeed(itemName: "夏の終わりに", qty: 1, unitPrice: 1200)
        ]),
        TransactionSeed(time: "11:51", total: 600, paid: 1000, lines: [
            TransactionLineSeed(itemName: "アクリルキーホルダー", qty: 1, unitPrice: 600)
        ])
    ]

    private static func seedTransactions(into day: EventDay, on date: Date, context: ModelContext) {
        for (idx, seed) in sampleTransactions.enumerated() {
            let transaction = SaleTransaction(
                number: idx + 1,
                timestamp: parseTime(seed.time, on: date),
                total: seed.total,
                paid: seed.paid
            )
            transaction.day = day
            for lineSeed in seed.lines {
                let line = TransactionLine(
                    itemName: lineSeed.itemName,
                    qty: lineSeed.qty,
                    unitPrice: lineSeed.unitPrice
                )
                transaction.lines.append(line)
                context.insert(line)
            }
            context.insert(transaction)
        }
    }

    private static let reservationSeeds: [ReservationSeed] = [
        ReservationSeed(
            name: "山田 こはる", handle: "@koharu_y", kind: .sns,
            note: "夏の終わりに ×2、海猫荘の夜 ×1", total: 3200, picked: false
        ),
        ReservationSeed(
            name: "佐藤 真央", handle: "mao.sato@…", kind: .mail,
            note: "残響レコード ×1、ステッカー全種", total: 1400, picked: true
        ),
        ReservationSeed(
            name: "Anna Müller", handle: "+49 30 …", kind: .tel,
            note: "新刊セット", total: 3000, picked: false
        ),
        ReservationSeed(
            name: "高橋 ゆず", handle: "@yuzu_dot", kind: .sns,
            note: "夏の終わりに ×1", total: 1200, picked: false
        )
    ]

    private static func seedReservations(into day: EventDay, context: ModelContext) {
        for seed in reservationSeeds {
            let reservation = Reservation(
                name: seed.name,
                handle: seed.handle,
                contact: seed.kind,
                note: seed.note,
                total: seed.total,
                pickedUp: seed.picked
            )
            reservation.day = day
            context.insert(reservation)
        }
    }

    private static func seedPastEvents(context: ModelContext) {
        let comitia149 = Event(
            name: "コミティア149",
            venue: "東京ビッグサイト",
            booth: "え-08a",
            colorHex: "#5A8DEE",
            isPastEvent: true
        )
        comitia149.createdAt = makeDate(year: 2026, month: 2, day: 11)
        let comitia149Day = EventDay(date: makeDate(year: 2026, month: 2, day: 11), label: "完了")
        comitia149.days = [comitia149Day]
        context.insert(comitia149)

        let comiket106 = Event(
            name: "コミックマーケット106",
            venue: "東京ビッグサイト",
            booth: "東-A11b",
            colorHex: "#34C759",
            isPastEvent: true
        )
        comiket106.createdAt = makeDate(year: 2025, month: 12, day: 30)
        let comiket106Day = EventDay(date: makeDate(year: 2025, month: 12, day: 30), label: "完了")
        comiket106.days = [comiket106Day]
        context.insert(comiket106)
    }

    private static func makeDate(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    private static func parseTime(_ raw: String, on date: Date) -> Date {
        let parts = raw.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return date }
        return Calendar.current.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: date) ?? date
    }
}
