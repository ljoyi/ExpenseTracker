import Foundation

enum StatisticsPeriod: String, CaseIterable, Codable, Sendable {
    case thisMonth
    case lastMonth
    case thisYear
    case lastYear
    case lastYearFromToday
    case all
    case custom

    var displayName: String {
        switch self {
        case .thisMonth:
            "本月"
        case .lastMonth:
            "上月"
        case .thisYear:
            "今年"
        case .lastYear:
            "去年"
        case .lastYearFromToday:
            "近一年"
        case .all:
            "全部"
        case .custom:
            "自定义日期"
        }
    }
}

struct StatisticsQuery: Equatable, Sendable {
    let range: DateRange
    let kind: TransactionKind?
    let categoryID: UUID?
}

struct StatisticsSummary: Equatable, Sendable {
    let totalIncomeMinorUnits: Int64
    let totalExpenseMinorUnits: Int64
    let balanceMinorUnits: Int64
    let dailyAverageExpense: Decimal
    let elapsedDays: Int
}

struct CategoryBreakdownItem: Identifiable, Equatable, Sendable {
    let categoryID: UUID
    let categoryName: String
    let iconName: String
    let colorHex: String
    let amountMinorUnits: Int64
    let share: Decimal

    var id: UUID {
        categoryID
    }
}

struct CategoryBreakdownResult: Equatable, Sendable {
    let kind: TransactionKind
    let totalMinorUnits: Int64
    let items: [CategoryBreakdownItem]

    var hasData: Bool {
        totalMinorUnits > 0 && !items.isEmpty
    }
}
