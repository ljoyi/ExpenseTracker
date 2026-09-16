import SwiftData
import XCTest
@testable import JiZhang

@MainActor
final class StatisticsServiceTests: XCTestCase {
    func testSummaryAndCategoryBreakdownMatchTransactions() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = ModelContext(container)
        _ = try AppBootstrapService(context: context).prepare()

        let fixedNow = Date()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let calendarService = CalendarService(
            calendar: calendar,
            nowProvider: { fixedNow }
        )
        let categoryService = CategoryService(context: context)
        let transactionService = TransactionService(
            context: context,
            nowProvider: { fixedNow }
        )
        let statisticsService = StatisticsService(
            transactionService: transactionService,
            categoryService: categoryService,
            calendarService: calendarService
        )

        let expenseCategoryID = try categoryService
            .list(kind: .expense)
            .first!
            .id
        let incomeCategoryID = try categoryService
            .list(kind: .income)
            .first!
            .id
        let occurredAt = fixedNow.addingTimeInterval(-60)

        _ = try transactionService.create(
            TransactionDraft(
                kind: .expense,
                amountMinorUnits: 7_500,
                categoryID: expenseCategoryID,
                occurredAt: occurredAt
            )
        )
        _ = try transactionService.create(
            TransactionDraft(
                kind: .income,
                amountMinorUnits: 10_000,
                categoryID: incomeCategoryID,
                occurredAt: occurredAt
            )
        )

        let range = try calendarService.dayRange(containing: fixedNow)
        let summary = try statisticsService.summary(range: range)
        let breakdown = try statisticsService.categoryBreakdown(
            range: range,
            kind: .expense
        )

        XCTAssertEqual(summary.totalExpenseMinorUnits, 7_500)
        XCTAssertEqual(summary.totalIncomeMinorUnits, 10_000)
        XCTAssertEqual(summary.balanceMinorUnits, 2_500)
        XCTAssertEqual(summary.elapsedDays, 1)
        XCTAssertEqual(summary.dailyAverageExpense, Decimal(75))
        XCTAssertEqual(breakdown.totalMinorUnits, 7_500)
        XCTAssertEqual(breakdown.items.count, 1)
        XCTAssertEqual(breakdown.items.first?.amountMinorUnits, 7_500)
        XCTAssertEqual(breakdown.items.first?.share, Decimal(100))
    }
}
