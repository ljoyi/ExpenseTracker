import Foundation

@MainActor
final class StatisticsService {
    private let transactionService: TransactionService
    private let categoryService: CategoryService
    private let calendarService: CalendarService

    init(
        transactionService: TransactionService,
        categoryService: CategoryService,
        calendarService: CalendarService
    ) {
        self.transactionService = transactionService
        self.categoryService = categoryService
        self.calendarService = calendarService
    }

    func summary(range: DateRange) throws -> StatisticsSummary {
        let transactions = try transactionService.query(range: range)
        var totalIncome: Int64 = 0
        var totalExpense: Int64 = 0

        for transaction in transactions {
            switch transaction.kind {
            case .expense:
                totalExpense += transaction.amountMinorUnits
            case .income:
                totalIncome += transaction.amountMinorUnits
            }
        }

        let elapsedDays = calendarService.elapsedDays(in: range)
        let dailyAverageExpense: Decimal
        if elapsedDays == 0 {
            dailyAverageExpense = 0
        } else {
            dailyAverageExpense = MoneyAmount.decimalValue(
                fromMinorUnits: totalExpense
            ) / Decimal(elapsedDays)
        }

        return StatisticsSummary(
            totalIncomeMinorUnits: totalIncome,
            totalExpenseMinorUnits: totalExpense,
            balanceMinorUnits: totalIncome - totalExpense,
            dailyAverageExpense: dailyAverageExpense,
            elapsedDays: elapsedDays
        )
    }

    func categoryBreakdown(
        range: DateRange,
        kind: TransactionKind
    ) throws -> CategoryBreakdownResult {
        let transactions = try transactionService.query(range: range, kind: kind)
        let total = transactions.reduce(into: Int64(0)) { result, transaction in
            result += transaction.amountMinorUnits
        }

        guard total > 0 else {
            return CategoryBreakdownResult(kind: kind, totalMinorUnits: 0, items: [])
        }

        var categoriesByID: [UUID: Category] = [:]
        for transaction in transactions {
            let categoryID = transaction.categoryID
            if categoriesByID[categoryID] == nil {
                let category = try categoryService.get(id: categoryID)
                categoriesByID[categoryID] = category
            }
        }

        let grouped = Dictionary(grouping: transactions, by: \.categoryID)
        let items = grouped.compactMap { categoryID, transactions -> CategoryBreakdownItem? in
            guard let category = categoriesByID[categoryID] else {
                return nil
            }

            let amount = transactions.reduce(into: Int64(0)) { result, transaction in
                result += transaction.amountMinorUnits
            }
            let share = Decimal(amount) / Decimal(total) * 100

            return CategoryBreakdownItem(
                categoryID: categoryID,
                categoryName: category.name,
                iconName: category.iconName,
                colorHex: category.colorHex,
                amountMinorUnits: amount,
                share: share
            )
        }
        .sorted(by: Self.sortBreakdownItems(categoriesByID: categoriesByID))

        return CategoryBreakdownResult(
            kind: kind,
            totalMinorUnits: total,
            items: items
        )
    }

    func categoryTransactions(
        range: DateRange,
        kind: TransactionKind,
        categoryID: UUID
    ) throws -> [TransactionSnapshot] {
        try transactionService.query(
            range: range,
            kind: kind,
            categoryID: categoryID
        )
    }

    private static func sortBreakdownItems(
        categoriesByID: [UUID: Category]
    ) -> (CategoryBreakdownItem, CategoryBreakdownItem) -> Bool {
        { lhs, rhs in
            if lhs.amountMinorUnits != rhs.amountMinorUnits {
                return lhs.amountMinorUnits > rhs.amountMinorUnits
            }

            let lhsOrder = categoriesByID[lhs.categoryID]?.sortOrder ?? .max
            let rhsOrder = categoriesByID[rhs.categoryID]?.sortOrder ?? .max
            if lhsOrder != rhsOrder {
                return lhsOrder < rhsOrder
            }

            if lhs.categoryName != rhs.categoryName {
                return lhs.categoryName.localizedCompare(rhs.categoryName) == .orderedAscending
            }

            return lhs.categoryID.uuidString < rhs.categoryID.uuidString
        }
    }
}
