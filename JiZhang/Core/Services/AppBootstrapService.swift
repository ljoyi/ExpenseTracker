import Foundation
import SwiftData

struct BootstrapResult: Equatable, Sendable {
    let ledgerID: UUID
    let insertedCategoryCount: Int
}

@MainActor
final class AppBootstrapService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func prepare() throws -> BootstrapResult {
        do {
            let ledger = try ensureLedger()
            let existingCategories = try context.fetch(FetchDescriptor<Category>())
            try migrateLegacyCategories(existingCategories)
            let currentCategories = try context.fetch(FetchDescriptor<Category>())
            let existingKeys = Set(
                currentCategories.map {
                    "\($0.kindRaw)|\($0.name)"
                }
            )

            var insertedCategoryCount = 0

            for seed in DefaultCategorySeed.all {
                let key = "\(seed.kind.rawValue)|\(seed.name)"
                guard !existingKeys.contains(key) else {
                    continue
                }

                let category = Category(
                    name: seed.name,
                    kind: seed.kind,
                    iconName: seed.iconName,
                    colorHex: seed.colorHex,
                    sortOrder: seed.sortOrder
                )
                context.insert(category)
                insertedCategoryCount += 1
            }

            if context.hasChanges {
                try context.save()
            }

            return BootstrapResult(
                ledgerID: ledger.id,
                insertedCategoryCount: insertedCategoryCount
            )
        } catch let error as ServiceError {
            context.rollback()
            throw error
        } catch {
            context.rollback()
            throw ServiceError.persistenceFailure
        }
    }

    private func ensureLedger() throws -> Ledger {
        let descriptor = FetchDescriptor<Ledger>(
            sortBy: [SortDescriptor(\Ledger.createdAt)]
        )

        if let ledger = try context.fetch(descriptor).first {
            return ledger
        }

        let ledger = Ledger(name: "我的账本")
        context.insert(ledger)
        return ledger
    }

    private func migrateLegacyCategories(
        _ categories: [Category]
    ) throws {
        let legacyRenames: [(old: String, kind: TransactionKind, new: String)] = [
            ("餐饮", .expense, "三餐"),
            ("购物", .expense, "日用品"),
            ("居住", .expense, "住房"),
            ("通讯", .expense, "话费网费"),
            ("其他", .expense, "其它"),
            ("奖金", .income, "外快"),
            ("兼职", .income, "外快"),
            ("理财", .income, "股票基金"),
            ("红包", .income, "收红包"),
            ("其他", .income, "其它")
        ]

        for legacy in legacyRenames {
            guard let source = categories.first(where: {
                $0.kindRaw == legacy.kind.rawValue
                    && $0.name == legacy.old
            }) else {
                continue
            }

            if source.name == legacy.new {
                continue
            }

            if let destination = categories.first(where: {
                $0.kindRaw == legacy.kind.rawValue
                    && $0.name == legacy.new
            }), destination.id != source.id {
                for transaction in source.transactions {
                    transaction.category = destination
                }
                context.delete(source)
                updateCategoryMetadata(
                    destination,
                    with: legacy.kind,
                    name: legacy.new
                )
            } else {
                source.name = legacy.new
                updateCategoryMetadata(
                    source,
                    with: legacy.kind,
                    name: legacy.new
                )
            }
        }
    }

    private func updateCategoryMetadata(
        _ category: Category,
        with kind: TransactionKind,
        name: String
    ) {
        guard let seed = DefaultCategorySeed.all.first(where: {
            $0.kind == kind && $0.name == name
        }) else {
            return
        }

        category.name = seed.name
        category.iconName = seed.iconName
        category.colorHex = seed.colorHex
        category.sortOrder = seed.sortOrder
        category.updatedAt = .now
    }
}
