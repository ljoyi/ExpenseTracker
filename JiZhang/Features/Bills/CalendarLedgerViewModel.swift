import Foundation
import Observation

@MainActor
@Observable
final class CalendarLedgerViewModel {
    let environment: AppEnvironment

    var displayedMonth: Date
    var selectedDate: Date
    private(set) var days: [CalendarDay] = []
    private(set) var groups: [DayTransactionGroup] = []
    private(set) var monthSummary = StatisticsSummary(
        totalIncomeMinorUnits: 0,
        totalExpenseMinorUnits: 0,
        balanceMinorUnits: 0,
        dailyAverageExpense: 0,
        elapsedDays: 0
    )
    private(set) var isLoading = false
    var errorMessage: String?

    init(environment: AppEnvironment, initialMonth: Date = Date()) {
        self.environment = environment
        self.displayedMonth = initialMonth
        self.selectedDate = Date()
    }

    var monthTitle: String {
        let components = Calendar.current.dateComponents(
            [.year, .month],
            from: displayedMonth
        )
        return "\(components.year ?? 0)年\(components.month ?? 0)月"
    }

    var selectedGroup: DayTransactionGroup? {
        groups.first {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }
    }

    func group(for date: Date) -> DayTransactionGroup? {
        groups.first {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }

    func load() {
        isLoading = true
        defer {
            isLoading = false
        }

        do {
            let range = try environment.calendarService.monthRange(
                containing: displayedMonth
            )
            let snapshots = try environment.transactionService.query(
                range: range
            )
            let items = try makeDisplayItems(
                snapshots: snapshots,
                categoryService: environment.categoryService
            )

            groups = makeDayGroups(items: items)
            monthSummary = try environment.statisticsService.summary(
                range: range
            )
            days = try environment.calendarService.monthDays(
                containing: displayedMonth
            )

            if !Calendar.current.isDate(
                selectedDate,
                equalTo: displayedMonth,
                toGranularity: .month
            ) {
                selectedDate = isCurrentMonth
                    ? Date()
                    : range.start
            }
        } catch {
            errorMessage = message(for: error)
        }
    }

    func moveMonth(by value: Int) {
        guard let month = Calendar.current.date(
            byAdding: .month,
            value: value,
            to: displayedMonth
        ) else {
            return
        }

        displayedMonth = month
        selectedDate = isCurrentMonth ? Date() : startOfDisplayedMonth
        load()
    }

    func selectDate(_ date: Date) {
        selectedDate = date
    }

    func goToday() {
        displayedMonth = Date()
        selectedDate = Date()
        load()
    }

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(
            displayedMonth,
            equalTo: Date(),
            toGranularity: .month
        )
    }

    private var startOfDisplayedMonth: Date {
        (try? environment.calendarService
            .monthRange(containing: displayedMonth)
            .start) ?? displayedMonth
    }

    private func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? "日历加载失败，请重试"
    }
}
