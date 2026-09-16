import Foundation
import SwiftData

@MainActor
final class LedgerService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func current() throws -> LedgerSnapshot {
        let descriptor = FetchDescriptor<Ledger>(
            sortBy: [SortDescriptor(\Ledger.createdAt)]
        )

        guard let ledger = try context.fetch(descriptor).first else {
            throw ServiceError.notInitialized
        }

        return LedgerSnapshot(
            id: ledger.id,
            name: ledger.name,
            createdAt: ledger.createdAt,
            updatedAt: ledger.updatedAt
        )
    }

    func currentEntity() throws -> Ledger {
        let descriptor = FetchDescriptor<Ledger>(
            sortBy: [SortDescriptor(\Ledger.createdAt)]
        )

        guard let ledger = try context.fetch(descriptor).first else {
            throw ServiceError.notInitialized
        }

        return ledger
    }
}
