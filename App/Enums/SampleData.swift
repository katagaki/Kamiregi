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
    static func populate(context: ModelContext) {
        seedComiket108(context: context)
        seedHappyMarket(context: context)
        seedComitia156(context: context)
        try? context.save()
    }

    // MARK: コミックマーケット108

    private static func seedComiket108(context: ModelContext) {
        let event = Event(
            name: "コミックマーケット108",
            venue: "東京ビッグサイト",
            booth: "東-ア21b",
            colorHex: "#FF5A4E"
        )
        context.insert(event)

        let firstDate = makeDate(year: 2026, month: 8, day: 15)
        let secondDate = makeDate(year: 2026, month: 8, day: 16)
        let day1 = EventDay(date: firstDate, label: "1日目 · 8月15日")
        let day2 = EventDay(date: secondDate, label: "2日目 · 8月16日")
        event.days = [day1, day2]

        let items: [ItemSeed] = [
            ItemSeed(name: "夏の終わりに", sub: "B5新刊・100頁", price: 1200, stock: 60, sold: 18),
            ItemSeed(name: "残響レコード", sub: "B5新刊・80頁", price: 1000, stock: 45, sold: 14),
            ItemSeed(name: "海猫荘の夜", sub: "A5既刊・64頁", price: 800, stock: 26, sold: 8),
            ItemSeed(name: "アクリルキーホルダー", sub: "4種 / 各", price: 600, stock: 82, sold: 22),
            ItemSeed(name: "缶バッジセット", sub: "3個セット", price: 500, stock: 24, sold: 24),
            ItemSeed(name: "ポストカード4種", sub: "4枚セット", price: 400, stock: 34, sold: 6),
            ItemSeed(name: "ステッカー", sub: "1枚", price: 200, stock: 100, sold: 12),
            ItemSeed(name: "おまけ無配", sub: "ペーパー", price: 0, stock: 80, sold: 30)
        ]
        seedItems(items, into: event, days: [day1, day2], context: context)

        let transactions: [TransactionSeed] = [
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
        seedTransactions(transactions, into: day1, on: firstDate, context: context)

        let reservations: [ReservationSeed] = [
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
        seedReservations(reservations, into: day1, context: context)
    }

    // MARK: ハッピーマーケット (架空イベント)

    private static func seedHappyMarket(context: ModelContext) {
        let event = Event(
            name: "ハッピーマーケット",
            venue: "池袋サンシャインシティ",
            booth: "H-05",
            colorHex: "#34C759"
        )
        context.insert(event)

        let date = makeDate(year: 2026, month: 7, day: 12)
        let day = EventDay(date: date, label: "開催日 · 7月12日")
        event.days = [day]

        let items: [ItemSeed] = [
            ItemSeed(name: "ハッピーアンソロジー", sub: "B5新刊・120頁", price: 1500, stock: 40, sold: 9),
            ItemSeed(name: "ミニ色紙", sub: "手描き・1枚", price: 800, stock: 15, sold: 5),
            ItemSeed(name: "アクリルスタンド", sub: "2種 / 各", price: 1000, stock: 30, sold: 7),
            ItemSeed(name: "マスキングテープ", sub: "2種 / 各", price: 450, stock: 50, sold: 10),
            ItemSeed(name: "ラバーストラップ", sub: "1個", price: 600, stock: 35, sold: 8),
            ItemSeed(name: "ノベルティ缶バッジ", sub: "無配", price: 0, stock: 60, sold: 20)
        ]
        seedItems(items, into: event, days: [day], context: context)

        let transactions: [TransactionSeed] = [
            TransactionSeed(time: "10:08", total: 1500, paid: 2000, lines: [
                TransactionLineSeed(itemName: "ハッピーアンソロジー", qty: 1, unitPrice: 1500)
            ]),
            TransactionSeed(time: "10:26", total: 2500, paid: 2500, lines: [
                TransactionLineSeed(itemName: "ハッピーアンソロジー", qty: 1, unitPrice: 1500),
                TransactionLineSeed(itemName: "アクリルスタンド", qty: 1, unitPrice: 1000)
            ]),
            TransactionSeed(time: "10:59", total: 1050, paid: 1100, lines: [
                TransactionLineSeed(itemName: "マスキングテープ", qty: 1, unitPrice: 450),
                TransactionLineSeed(itemName: "ラバーストラップ", qty: 1, unitPrice: 600)
            ]),
            TransactionSeed(time: "11:31", total: 800, paid: 1000, lines: [
                TransactionLineSeed(itemName: "ミニ色紙", qty: 1, unitPrice: 800)
            ]),
            TransactionSeed(time: "12:14", total: 3300, paid: 3500, lines: [
                TransactionLineSeed(itemName: "ハッピーアンソロジー", qty: 1, unitPrice: 1500),
                TransactionLineSeed(itemName: "アクリルスタンド", qty: 1, unitPrice: 1000),
                TransactionLineSeed(itemName: "ミニ色紙", qty: 1, unitPrice: 800)
            ]),
            TransactionSeed(time: "13:45", total: 900, paid: 1000, lines: [
                TransactionLineSeed(itemName: "マスキングテープ", qty: 2, unitPrice: 450)
            ])
        ]
        seedTransactions(transactions, into: day, on: date, context: context)
    }

    // MARK: COMITIA156

    private static func seedComitia156(context: ModelContext) {
        let event = Event(
            name: "COMITIA156",
            venue: "東京ビッグサイト",
            booth: "そ-12a",
            colorHex: "#5A8DEE",
            isPastEvent: true
        )
        event.createdAt = makeDate(year: 2026, month: 5, day: 5)
        context.insert(event)

        let date = makeDate(year: 2026, month: 5, day: 5)
        let day = EventDay(date: date, label: "開催日 · 5月5日")
        event.days = [day]

        let items: [ItemSeed] = [
            ItemSeed(name: "ことばの庭", sub: "B5新刊・92頁", price: 1100, stock: 50, sold: 41),
            ItemSeed(name: "雨上がりの街", sub: "A5既刊・56頁", price: 700, stock: 30, sold: 22),
            ItemSeed(name: "ラフスケッチ集", sub: "A4コピー本", price: 500, stock: 40, sold: 35),
            ItemSeed(name: "クリアしおり", sub: "2種 / 各", price: 300, stock: 60, sold: 44),
            ItemSeed(name: "ポストカード", sub: "3枚セット", price: 400, stock: 50, sold: 28)
        ]
        seedItems(items, into: event, days: [day], context: context)

        let transactions: [TransactionSeed] = [
            TransactionSeed(time: "10:05", total: 1100, paid: 1500, lines: [
                TransactionLineSeed(itemName: "ことばの庭", qty: 1, unitPrice: 1100)
            ]),
            TransactionSeed(time: "10:40", total: 1800, paid: 2000, lines: [
                TransactionLineSeed(itemName: "ことばの庭", qty: 1, unitPrice: 1100),
                TransactionLineSeed(itemName: "雨上がりの街", qty: 1, unitPrice: 700)
            ]),
            TransactionSeed(time: "11:15", total: 800, paid: 800, lines: [
                TransactionLineSeed(itemName: "ラフスケッチ集", qty: 1, unitPrice: 500),
                TransactionLineSeed(itemName: "クリアしおり", qty: 1, unitPrice: 300)
            ]),
            TransactionSeed(time: "12:02", total: 2200, paid: 2500, lines: [
                TransactionLineSeed(itemName: "ことばの庭", qty: 2, unitPrice: 1100)
            ]),
            TransactionSeed(time: "13:30", total: 1400, paid: 1500, lines: [
                TransactionLineSeed(itemName: "雨上がりの街", qty: 1, unitPrice: 700),
                TransactionLineSeed(itemName: "クリアしおり", qty: 1, unitPrice: 300),
                TransactionLineSeed(itemName: "ポストカード", qty: 1, unitPrice: 400)
            ])
        ]
        seedTransactions(transactions, into: day, on: date, context: context)
    }

    // MARK: Helpers

    private static func seedItems(_ seeds: [ItemSeed], into event: Event, days: [EventDay], context: ModelContext) {
        for (idx, seed) in seeds.enumerated() {
            let item = InventoryItem(
                name: seed.name,
                sub: seed.sub,
                price: seed.price,
                sortIndex: idx
            )
            item.regionRect = gridRegion(at: idx, count: seeds.count)
            event.items.append(item)

            for (dayIdx, day) in days.enumerated() {
                let stock = dayIdx == 0
                    ? DailyStock(initial: seed.stock, sold: seed.sold)
                    : DailyStock(initial: max(20, seed.stock / 2), sold: 0)
                stock.item = item
                stock.day = day
                context.insert(stock)
            }
        }
    }

    private static func gridRegion(at index: Int, count: Int) -> CGRect {
        let columns = 2
        let rows = max(1, (count + columns - 1) / columns)
        let cellWidth = 0.88 / Double(columns)
        let cellHeight = 0.86 / Double(rows)
        let col = index % columns
        let row = index / columns
        return CGRect(
            x: 0.06 + Double(col) * (cellWidth + 0.02),
            y: 0.06 + Double(row) * (cellHeight + 0.02),
            width: cellWidth - 0.02,
            height: cellHeight - 0.02
        )
    }

    private static func seedTransactions(_ seeds: [TransactionSeed], into day: EventDay, on date: Date, context: ModelContext) {
        for (idx, seed) in seeds.enumerated() {
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

    private static func seedReservations(_ seeds: [ReservationSeed], into day: EventDay, context: ModelContext) {
        for seed in seeds {
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

    private static func makeDate(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    private static func parseTime(_ raw: String, on date: Date) -> Date {
        let parts = raw.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return date }
        return Calendar.current.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: date) ?? date
    }
}
