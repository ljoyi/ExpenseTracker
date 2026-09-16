import Foundation

enum LedgerPeriodMode: String, CaseIterable, Codable, Sendable {
    case month
    case year
    case all

    var displayName: String {
        switch self {
        case .month:
            "按月"
        case .year:
            "按年"
        case .all:
            "全部"
        }
    }
}

struct LedgerPeriodSelection: Equatable, Sendable {
    var mode: LedgerPeriodMode
    var year: Int
    var month: Int

    static func current(calendar: Calendar = .current, now: Date = Date()) -> LedgerPeriodSelection {
        let components = calendar.dateComponents([.year, .month], from: now)
        return LedgerPeriodSelection(
            mode: .month,
            year: components.year ?? 2026,
            month: components.month ?? 1
        )
    }

    var title: String {
        switch mode {
        case .month:
            "\(year)年\(month)月"
        case .year:
            "\(year)年"
        case .all:
            "全部"
        }
    }

    func dateRange(
        calendarService: CalendarService,
        earliestTransactionDate: Date?,
        latestTransactionDate: Date?
    ) throws -> DateRange {
        switch mode {
        case .month:
            return try calendarService.monthRange(
                year: year,
                month: month
            )
        case .year:
            return try calendarService.yearRange(year: year)
        case .all:
            return try calendarService.allRange(
                earliestTransactionDate: earliestTransactionDate,
                latestTransactionDate: latestTransactionDate
            )
        }
    }
}
