import Foundation
import SwiftData

@MainActor
final class TransactionService {
    private let context: ModelContext
    private let categoryService: CategoryService
    private let ledgerService: LedgerService
    private let nowProvider: () -> Date

    init(
        context: ModelContext,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.context = context
        self.categoryService = CategoryService(context: context)
        self.ledgerService = LedgerService(context: context)
        self.nowProvider = nowProvider
    }

    func create(_ draft: TransactionDraft) throws -> TransactionSnapshot {
        guard draft.amountMinorUnits > 0,
              draft.amountMinorUnits <= MoneyAmount.maximumMinorUnits
        else {
            throw ServiceError.invalidAmount
        }

        let category = try categoryService.validate(id: draft.categoryID, kind: draft.kind)
        let ledger = try ledgerService.currentEntity()
        let transaction = Transaction(
            kind: draft.kind,
            amountMinorUnits: draft.amountMinorUnits,
            occurredAt: draft.occurredAt,
            createdAt: nowProvider(),
            updatedAt: nowProvider()
        )
        transaction.ledger = ledger
        transaction.category = category
        context.insert(transaction)

        do {
            try context.save()
            return try snapshot(for: transaction)
        } catch {
            context.rollback()
            throw ServiceError.persistenceFailure
        }
    }

    func update(
        transactionID: UUID,
        patch: TransactionPatch
    ) throws -> TransactionSnapshot {
        let transaction = try getEntity(id: transactionID)

        guard let currentKind = transaction.kind else {
            throw ServiceError.corruptData
        }

        let finalKind = patch.kind ?? currentKind
        let finalAmount = patch.amountMinorUnits ?? transaction.amountMinorUnits
        let finalDate = patch.occurredAt ?? transaction.occurredAt
        let finalCategoryID = patch.categoryID ?? transaction.category?.id

        guard finalAmount > 0, finalAmount <= MoneyAmount.maximumMinorUnits else {
            throw ServiceError.invalidAmount
        }

        let category = try categoryService.validate(id: finalCategoryID, kind: finalKind)

        transaction.kindRaw = finalKind.rawValue
        transaction.amountMinorUnits = finalAmount
        transaction.occurredAt = finalDate
        transaction.category = category
        transaction.updatedAt = nowProvider()

        do {
            try context.save()
            return try snapshot(for: transaction)
        } catch {
            context.rollback()
            throw ServiceError.persistenceFailure
        }
    }

    func delete(transactionID: UUID) throws -> DeleteResult {
        var descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { transaction in
                transaction.id == transactionID
            }
        )
        descriptor.fetchLimit = 1

        guard let transaction = try context.fetch(descriptor).first else {
            return DeleteResult(deletedExistingRecord: false)
        }

        context.delete(transaction)

        do {
            try context.save()
            return DeleteResult(deletedExistingRecord: true)
        } catch {
            context.rollback()
            throw ServiceError.persistenceFailure
        }
    }

    func get(transactionID: UUID) throws -> TransactionSnapshot {
        try snapshot(for: getEntity(id: transactionID))
    }

    func query(
        range: DateRange,
        kind: TransactionKind? = nil,
        categoryID: UUID? = nil
    ) throws -> [TransactionSnapshot] {
        let start = range.start
        let end = range.end
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { transaction in
                transaction.occurredAt >= start && transaction.occurredAt < end
            }
        )

        let transactions = try context.fetch(descriptor)
            .filter { transaction in
                guard let transactionKind = transaction.kind else {
                    return false
                }

                if let kind, transactionKind != kind {
                    return false
                }

                if let categoryID, transaction.category?.id != categoryID {
                    return false
                }

                return true
            }
            .sorted(by: Self.sortTransactions)

        return try transactions.map(snapshot)
    }

    func earliestOccurredAt() throws -> Date? {
        var descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\Transaction.occurredAt)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.occurredAt
    }

    func latestOccurredAt() throws -> Date? {
        var descriptor = FetchDescriptor<Transaction>(
            sortBy: [
                SortDescriptor(\Transaction.occurredAt, order: .reverse)
            ]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.occurredAt
    }

    private func getEntity(id: UUID) throws -> Transaction {
        var descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { transaction in
                transaction.id == id
            }
        )
        descriptor.fetchLimit = 1

        guard let transaction = try context.fetch(descriptor).first else {
            throw ServiceError.transactionNotFound
        }

        return transaction
    }

    private func snapshot(for transaction: Transaction) throws -> TransactionSnapshot {
        guard let kind = transaction.kind,
              let categoryID = transaction.category?.id
        else {
            throw ServiceError.corruptData
        }

        return TransactionSnapshot(
            id: transaction.id,
            kind: kind,
            amountMinorUnits: transaction.amountMinorUnits,
            categoryID: categoryID,
            occurredAt: transaction.occurredAt,
            createdAt: transaction.createdAt,
            updatedAt: transaction.updatedAt
        )
    }

    private static func sortTransactions(
        _ lhs: Transaction,
        _ rhs: Transaction
    ) -> Bool {
        if lhs.occurredAt != rhs.occurredAt {
            return lhs.occurredAt > rhs.occurredAt
        }

        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt > rhs.createdAt
        }

        return lhs.id.uuidString < rhs.id.uuidString
    }
}
