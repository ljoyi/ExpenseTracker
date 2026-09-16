import Foundation
import Observation

@MainActor
@Observable
final class BillsViewModel {
    let environment: AppEnvironment

    private(set) var items: [TransactionDisplayItem] = []
    private(set) var groups: [DayTransactionGroup] = []
    private(set) var summary = StatisticsSummary(
        totalIncomeMinorUnits: 0,
        totalExpenseMinorUnits: 0,
        balanceMinorUnits: 0,
        dailyAverageExpense: 0,
        elapsedDays: 0
    )
    private(set) var isLoading = false
    var errorMessage: String?

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    var periodTitle: String {
        environment.ledgerPeriod.title
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
            let range = try environment.ledgerPeriod.dateRange(
                calendarService: environment.calendarService,
                earliestTransactionDate: earliest,
                latestTransactionDate: latest
            )
            let snapshots = try environment.transactionService.query(
                range: range
            )

            items = try makeDisplayItems(
                snapshots: snapshots,
                categoryService: environment.categoryService
            )
            groups = makeDayGroups(items: items)
            summary = try environment.statisticsService.summary(range: range)
            errorMessage = nil
        } catch {
            errorMessage = message(for: error)
        }
    }

    func selectPeriod(_ selection: LedgerPeriodSelection) {
        environment.ledgerPeriod = selection
        load()
    }

    private func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? "账单加载失败，请重试"
    }
}
