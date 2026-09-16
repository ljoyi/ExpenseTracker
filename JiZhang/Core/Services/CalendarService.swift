import Foundation

struct CalendarService {
    static var defaultCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = .current
        calendar.firstWeekday = 2
        return calendar
    }

    private let calendar: Calendar
    private let nowProvider: () -> Date

    init(
        calendar: Calendar = CalendarService.defaultCalendar,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.calendar = calendar
        self.nowProvider = nowProvider
    }

    func monthRange(containing date: Date) throws -> DateRange {
        guard let interval = calendar.dateInterval(of: .month, for: date) else {
            throw ServiceError.invalidDateRange
        }

        guard let range = DateRange(start: interval.start, end: interval.end) else {
            throw ServiceError.invalidDateRange
        }

        return range
    }

    func monthRange(year: Int, month: Int) throws -> DateRange {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = 1

        guard let date = calendar.date(from: components) else {
            throw ServiceError.invalidDateRange
        }

        return try monthRange(containing: date)
    }

    func yearRange(year: Int) throws -> DateRange {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = 1
        components.day = 1

        guard let date = calendar.date(from: components) else {
            throw ServiceError.invalidDateRange
        }

        return try yearRange(containing: date)
    }

    func allRange(
        earliestTransactionDate: Date?,
        latestTransactionDate: Date? = nil
    ) throws -> DateRange {
        let startDate = earliestTransactionDate ?? nowProvider()
        let start = calendar.startOfDay(for: startDate)
        let today = calendar.startOfDay(for: nowProvider())
        let latestDate = latestTransactionDate.map {
            calendar.startOfDay(for: $0)
        } ?? today
        let lastDate = max(today, latestDate)

        guard let end = calendar.date(byAdding: .day, value: 1, to: lastDate),
              let range = DateRange(start: start, end: end)
        else {
            throw ServiceError.invalidDateRange
        }

        return range
    }

    func dayRange(containing date: Date) throws -> DateRange {
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start),
              let range = DateRange(start: start, end: end)
        else {
            throw ServiceError.invalidDateRange
        }

        return range
    }

    func range(
        for period: StatisticsPeriod,
        customStart: Date? = nil,
        customEnd: Date? = nil,
        earliestTransactionDate: Date? = nil,
        latestTransactionDate: Date? = nil
    ) throws -> DateRange {
        let now = nowProvider()

        switch period {
        case .thisMonth:
            return try monthRange(containing: now)
        case .lastMonth:
            guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: now) else {
                throw ServiceError.invalidDateRange
            }
            return try monthRange(containing: previousMonth)
        case .thisYear:
            return try yearRange(containing: now)
        case .lastYear:
            guard let previousYear = calendar.date(byAdding: .year, value: -1, to: now) else {
                throw ServiceError.invalidDateRange
            }
            return try yearRange(containing: previousYear)
        case .lastYearFromToday:
            let today = calendar.startOfDay(for: now)
            guard let start = calendar.date(byAdding: .year, value: -1, to: today),
                  let end = calendar.date(byAdding: .day, value: 1, to: today),
                  let range = DateRange(start: start, end: end)
            else {
                throw ServiceError.invalidDateRange
            }
            return range
        case .all:
            return try allRange(
                earliestTransactionDate: earliestTransactionDate,
                latestTransactionDate: latestTransactionDate
            )
        case .custom:
            guard let customStart, let customEnd else {
                throw ServiceError.invalidDateRange
            }

            let start = calendar.startOfDay(for: customStart)
            let endDay = calendar.startOfDay(for: customEnd)
            guard start <= endDay,
                  let end = calendar.date(byAdding: .day, value: 1, to: endDay),
                  let range = DateRange(start: start, end: end)
            else {
                throw ServiceError.invalidDateRange
            }
            return range
        }
    }

    func elapsedDays(in range: DateRange) -> Int {
        let today = calendar.startOfDay(for: nowProvider())
        guard let lastDayInRange = calendar.date(byAdding: .day, value: -1, to: range.end) else {
            return 0
        }

        let lastElapsedDay = min(lastDayInRange, today)
        guard lastElapsedDay >= range.start else {
            return 0
        }

        let components = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: range.start),
            to: lastElapsedDay
        )

        return (components.day ?? -1) + 1
    }

    func monthDays(containing date: Date) throws -> [CalendarDay] {
        let range = try monthRange(containing: date)
        let firstWeekday = calendar.firstWeekday
        let weekdayOfFirstDay = calendar.component(.weekday, from: range.start)
        let leadingDayCount = (weekdayOfFirstDay - firstWeekday + 7) % 7

        guard let gridStart = calendar.date(
            byAdding: .day,
            value: -leadingDayCount,
            to: range.start
        ) else {
            throw ServiceError.invalidDateRange
        }

        let monthComponents = calendar.dateComponents(
            [.year, .month],
            from: range.start
        )

        return try (0..<42).map { offset in
            guard let day = calendar.date(
                byAdding: .day,
                value: offset,
                to: gridStart
            ) else {
                throw ServiceError.invalidDateRange
            }

            let dayComponents = calendar.dateComponents(
                [.year, .month],
                from: day
            )

            return CalendarDay(
                date: day,
                isInDisplayedMonth: dayComponents.year == monthComponents.year
                    && dayComponents.month == monthComponents.month
            )
        }
    }

    private func yearRange(containing date: Date) throws -> DateRange {
        guard let interval = calendar.dateInterval(of: .year, for: date) else {
            throw ServiceError.invalidDateRange
        }

        guard let range = DateRange(start: interval.start, end: interval.end) else {
            throw ServiceError.invalidDateRange
        }

        return range
    }
}
