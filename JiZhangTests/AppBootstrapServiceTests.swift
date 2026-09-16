import SwiftData
import XCTest
@testable import JiZhang

@MainActor
final class AppBootstrapServiceTests: XCTestCase {
    func testBootstrapCreatesLedgerAndCategoriesOnce() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = ModelContext(container)
        let service = AppBootstrapService(context: context)

        _ = try service.prepare()
        _ = try service.prepare()

        let ledgers = try context.fetch(FetchDescriptor<JiZhang.Ledger>())
        let categories = try context.fetch(FetchDescriptor<JiZhang.Category>())

        XCTAssertEqual(ledgers.count, 1)
        XCTAssertEqual(ledgers.first?.name, "我的账本")
        XCTAssertEqual(categories.count, 28)
        XCTAssertEqual(
            categories.filter { $0.kindRaw == TransactionKind.expense.rawValue }.count,
            22
        )
        XCTAssertEqual(
            categories.filter { $0.kindRaw == TransactionKind.income.rawValue }.count,
            6
        )
        XCTAssertTrue(categories.contains { $0.name == "三餐" })
        XCTAssertTrue(categories.contains { $0.name == "股票基金" })
    }

    func testLegacyCategoryNamesAreMigrated() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = ModelContext(container)
        context.insert(
            Category(
                name: "餐饮",
                kind: .expense,
                iconName: "fork.knife",
                colorHex: "#E76F51",
                sortOrder: 10
            )
        )
        context.insert(
            Category(
                name: "奖金",
                kind: .income,
                iconName: "gift.fill",
                colorHex: "#F4A261",
                sortOrder: 20
            )
        )
        try context.save()

        _ = try AppBootstrapService(context: context).prepare()

        let categories = try context.fetch(FetchDescriptor<JiZhang.Category>())
        XCTAssertTrue(categories.contains { $0.name == "三餐" })
        XCTAssertTrue(categories.contains { $0.name == "外快" })
        XCTAssertFalse(categories.contains { $0.name == "餐饮" })
        XCTAssertFalse(categories.contains { $0.name == "奖金" })
    }
}
