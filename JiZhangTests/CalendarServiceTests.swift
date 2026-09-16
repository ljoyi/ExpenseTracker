import XCTest
@testable import JiZhang

final class CalendarServiceTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.firstWeekday = 2
        return calendar
    }

    private var fixedNow: Date {
        calendar.date(
            from: DateComponents(
                year: 2026,
                month: 9,
                day: 10,
                hour: 15,
                minute: 30
            )
        )!
    }

    func testMonthRangeUsesNextMonthStartAsExclusiveEnd() throws {
        let service = CalendarService(
            calendar: calendar,
            nowProvider: { self.fixedNow }
        )

        let range = try service.monthRange(
            year: 2026,
            month: 9
        )
        let expectedStart = calendar.date(
            from: DateComponents(year: 2026, month: 9, day: 1)
        )!
        let expectedEnd = calendar.date(
            from: DateComponents(year: 2026, month: 10, day: 1)
        )!

        XCTAssertEqual(range.start, expectedStart)
        XCTAssertEqual(range.end, expectedEnd)
    }

    func testElapsedDaysIncludesTodayOnlyOnce() throws {
        let service = CalendarService(
            calendar: calendar,
            nowProvider: { self.fixedNow }
        )
        let range = try service.monthRange(
            year: 2026,
            month: 9
        )

        XCTAssertEqual(service.elapsedDays(in: range), 10)
    }

    func testCustomRangeUsesInclusiveUserDates() throws {
        let service = CalendarService(
            calendar: calendar,
            nowProvider: { self.fixedNow }
        )
        let start = calendar.date(
            from: DateComponents(year: 2026, month: 9, day: 1)
        )!
        let end = calendar.date(
            from: DateComponents(year: 2026, month: 9, day: 3)
        )!

        let range = try service.range(
            for: .custom,
            customStart: start,
            customEnd: end
        )
        let expectedEnd = calendar.date(
            from: DateComponents(year: 2026, month: 9, day: 4)
        )!

        XCTAssertEqual(range.end, expectedEnd)
    }

    func testMonthGridHasSixWeeksAndMondayStart() throws {
        var calendar = self.calendar
        calendar.firstWeekday = 2
        let service = CalendarService(
            calendar: calendar,
            nowProvider: { self.fixedNow }
        )

        let days = try service.monthDays(containing: fixedNow)

        XCTAssertEqual(days.count, 42)
        XCTAssertEqual(
            days.first?.date,
            calendar.date(
                from: DateComponents(year: 2026, month: 8, day: 31)
            )
        )
        XCTAssertEqual(days[1].date, calendar.date(
            from: DateComponents(year: 2026, month: 9, day: 1)
        ))
        XCTAssertTrue(days[1].isInDisplayedMonth)
        XCTAssertFalse(days[0].isInDisplayedMonth)
    }

    func testAllRangeIncludesFutureTransactions() throws {
        let service = CalendarService(
            calendar: calendar,
            nowProvider: { self.fixedNow }
        )
        let futureDate = calendar.date(
            byAdding: .day,
            value: 40,
            to: fixedNow
        )!

        let range = try service.allRange(
            earliestTransactionDate: fixedNow,
            latestTransactionDate: futureDate
        )

        XCTAssertTrue(range.contains(futureDate))
        XCTAssertGreaterThan(range.end, futureDate)
    }
}
