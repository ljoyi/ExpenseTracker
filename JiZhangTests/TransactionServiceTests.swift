import SwiftData
import XCTest
@testable import JiZhang

@MainActor
final class TransactionServiceTests: XCTestCase {
    func testCreatePersistsTransaction() throws {
        let fixture = try makeFixture()
        let categoryID = try fixture.categoryService
            .list(kind: .expense)
            .first!
            .id
        let occurredAt = fixture.now.addingTimeInterval(-60)

        let snapshot = try fixture.transactionService.create(
            TransactionDraft(
                kind: .expense,
                amountMinorUnits: 1_234,
                categoryID: categoryID,
                occurredAt: occurredAt
            )
        )

        XCTAssertEqual(snapshot.amountMinorUnits, 1_234)
        XCTAssertEqual(snapshot.categoryID, categoryID)

        let dayRange = try fixture.calendarService.dayRange(
            containing: fixture.now
        )
        let transactions = try fixture.transactionService.query(range: dayRange)
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions.first?.id, snapshot.id)
    }

    func testUpdateChangesAmount() throws {
        let fixture = try makeFixture()
        let categoryID = try fixture.categoryService
            .list(kind: .expense)
            .first!
            .id
        let snapshot = try fixture.transactionService.create(
            TransactionDraft(
                kind: .expense,
                amountMinorUnits: 1_000,
                categoryID: categoryID,
                occurredAt: fixture.now.addingTimeInterval(-60)
            )
        )

        let updated = try fixture.transactionService.update(
            transactionID: snapshot.id,
            patch: TransactionPatch(amountMinorUnits: 2_500)
        )

        XCTAssertEqual(updated.amountMinorUnits, 2_500)
        XCTAssertEqual(updated.categoryID, categoryID)
        XCTAssertGreaterThanOrEqual(updated.updatedAt, snapshot.updatedAt)
    }

    func testDeleteIsIdempotent() throws {
        let fixture = try makeFixture()
        let categoryID = try fixture.categoryService
            .list(kind: .expense)
            .first!
            .id
        let snapshot = try fixture.transactionService.create(
            TransactionDraft(
                kind: .expense,
                amountMinorUnits: 500,
                categoryID: categoryID,
                occurredAt: fixture.now.addingTimeInterval(-60)
            )
        )

        let firstDelete = try fixture.transactionService.delete(
            transactionID: snapshot.id
        )
        let secondDelete = try fixture.transactionService.delete(
            transactionID: snapshot.id
        )

        XCTAssertTrue(firstDelete.deletedExistingRecord)
        XCTAssertFalse(secondDelete.deletedExistingRecord)
        XCTAssertThrowsError(
            try fixture.transactionService.get(transactionID: snapshot.id)
        )
    }

    func testCreateAllowsFutureOccurrence() throws {
        let fixture = try makeFixture()
        let categoryID = try fixture.categoryService
            .list(kind: .expense)
            .first!
            .id
        let futureDate = fixture.now.addingTimeInterval(86_400)

        let snapshot = try fixture.transactionService.create(
            TransactionDraft(
                kind: .expense,
                amountMinorUnits: 800,
                categoryID: categoryID,
                occurredAt: futureDate
            )
        )

        XCTAssertEqual(snapshot.occurredAt, futureDate)
    }

    private func makeFixture() throws -> TransactionServiceFixture {
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

        return TransactionServiceFixture(
            context: context,
            categoryService: categoryService,
            transactionService: transactionService,
            calendarService: calendarService,
            now: fixedNow
        )
    }
}

@MainActor
private struct TransactionServiceFixture {
    let context: ModelContext
    let categoryService: CategoryService
    let transactionService: TransactionService
    let calendarService: CalendarService
    let now: Date
}
