import Foundation
import SwiftData

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var kindRaw: String
    var amountMinorUnits: Int64
    var occurredAt: Date
    var note: String?
    var createdAt: Date
    var updatedAt: Date

    var ledger: Ledger?
    var category: Category?

    init(
        id: UUID = UUID(),
        kind: TransactionKind,
        amountMinorUnits: Int64,
        occurredAt: Date,
        note: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.amountMinorUnits = amountMinorUnits
        self.occurredAt = occurredAt
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var kind: TransactionKind? {
        TransactionKind(rawValue: kindRaw)
    }
}
