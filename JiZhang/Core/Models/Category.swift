import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var kindRaw: String
    var iconName: String
    var colorHex: String
    var sortOrder: Int
    var isBuiltIn: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .deny, inverse: \Transaction.category)
    var transactions: [Transaction]

    init(
        id: UUID = UUID(),
        name: String,
        kind: TransactionKind,
        iconName: String,
        colorHex: String,
        sortOrder: Int,
        isBuiltIn: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.kindRaw = kind.rawValue
        self.iconName = iconName
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.transactions = []
    }

    var kind: TransactionKind? {
        TransactionKind(rawValue: kindRaw)
    }
}
