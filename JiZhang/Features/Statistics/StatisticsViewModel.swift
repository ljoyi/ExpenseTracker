import Foundation
import Observation

@MainActor
@Observable
final class StatisticsViewModel {
    let environment: AppEnvironment

    var period: StatisticsPeriod = .thisMonth
    var kind: TransactionKind = .expense
    var customStart: Date
    var customEnd: Date
    private(set) var periodName = StatisticsPeriod.thisMonth.displayName
    private(set) var range: DateRange?
    private(set) var rangeLabel = ""
    private(set) var summary = StatisticsSummary(
        totalIncomeMinorUnits: 0,
        totalExpenseMinorUnits: 0,
        balanceMinorUnits: 0,
        dailyAverageExpense: 0,
        elapsedDays: 0
    )
    private(set) var breakdown = CategoryBreakdownResult(
        kind: .expense,
        totalMinorUnits: 0,
        items: []
    )
    private(set) var isLoading = false
    var errorMessage: String?

    init(environment: AppEnvironment) {
        let now = Date()
        self.environment = environment
        self.customStart = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: now)
        ) ?? now
        self.customEnd = now
    }

    func load() {
        isLoading = true
        defer {
            isLoading = false
        }

        do {
            let earliest = try environment.transactionService
                .earliestOccurredAt()
            let latest = try environment.transactionService
                .latestOccurredAt()
            let range = try environment.calendarService.range(
                for: period,
                customStart: customStart,
                customEnd: customEnd,
                earliestTransactionDate: earliest,
                latestTransactionDate: latest
            )

            self.range = range
            self.rangeLabel = makeRangeLabel(range)
            self.summary = try environment.statisticsService.summary(
                range: range
            )
            self.breakdown = try environment.statisticsService
                .categoryBreakdown(
                    range: range,
                    kind: kind
                )
            self.errorMessage = nil
        } catch {
            self.errorMessage = message(for: error)
        }
    }

    func changeKind(_ newKind: TransactionKind) {
        guard kind != newKind else {
            return
        }

        kind = newKind
        load()
    }

    func selectPeriod(_ period: StatisticsPeriod) {
        self.period = period
        self.periodName = period.displayName
        load()
    }

    func updateCustomRange(start: Date, end: Date) {
        customStart = start
        customEnd = end
        period = .custom
        periodName = StatisticsPeriod.custom.displayName
        load()
    }

    func applyLedgerPeriod(_ selection: LedgerPeriodSelection) {
        switch selection.mode {
        case .month:
            guard let start = Calendar.current.date(
                from: DateComponents(
                    year: selection.year,
                    month: selection.month,
                    day: 1
                )
            ), let nextMonth = Calendar.current.date(
                byAdding: .month,
                value: 1,
                to: start
            ), let end = Calendar.current.date(
                byAdding: .day,
                value: -1,
                to: nextMonth
            ) else {
                return
            }

            customStart = start
            customEnd = end
            period = .custom
        case .year:
            guard let start = Calendar.current.date(
                from: DateComponents(year: selection.year, month: 1, day: 1)
            ), let nextYear = Calendar.current.date(
                byAdding: .year,
                value: 1,
                to: start
            ), let end = Calendar.current.date(
                byAdding: .day,
                value: -1,
                to: nextYear
            ) else {
                return
            }

            customStart = start
            customEnd = end
            period = .custom
        case .all:
            period = .all
        }

        periodName = selection.title
        load()
    }

    func categoryTransactions(
        categoryID: UUID
    ) throws -> [TransactionDisplayItem] {
        guard let range else {
            throw ServiceError.invalidDateRange
        }

        let snapshots = try environment.statisticsService
            .categoryTransactions(
                range: range,
                kind: kind,
                categoryID: categoryID
            )

        return try makeDisplayItems(
            snapshots: snapshots,
            categoryService: environment.categoryService
        )
    }

    private func makeRangeLabel(_ range: DateRange) -> String {
        let inclusiveEnd = Calendar.current.date(
            byAdding: .second,
            value: -1,
            to: range.end
        ) ?? range.end

        return "\(range.start.formatted(date: .abbreviated, time: .omitted))"
            + " - "
            + "\(inclusiveEnd.formatted(date: .abbreviated, time: .omitted))"
    }

    private func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? "统计加载失败，请重试"
    }
}
