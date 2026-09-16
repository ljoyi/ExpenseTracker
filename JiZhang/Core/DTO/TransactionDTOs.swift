import Foundation

struct TransactionDraft: Equatable, Sendable {
    let kind: TransactionKind
    let amountMinorUnits: Int64
    let categoryID: UUID
    let occurredAt: Date
}

struct TransactionPatch: Equatable, Sendable {
    var kind: TransactionKind?
    var amountMinorUnits: Int64?
    var categoryID: UUID?
    var occurredAt: Date?
}

struct TransactionSnapshot: Identifiable, Equatable, Sendable {
    let id: UUID
    let kind: TransactionKind
    let amountMinorUnits: Int64
    let categoryID: UUID
    let occurredAt: Date
    let createdAt: Date
    let updatedAt: Date
}

struct LedgerSnapshot: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let createdAt: Date
    let updatedAt: Date
}

struct DeleteResult: Equatable, Sendable {
    let deletedExistingRecord: Bool
}
