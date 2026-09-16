import Foundation
import SwiftData

@MainActor
final class CategoryService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func list(kind: TransactionKind) throws -> [Category] {
        let rawValue = kind.rawValue
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { category in
                category.kindRaw == rawValue
            },
            sortBy: [
                SortDescriptor(\Category.sortOrder),
                SortDescriptor(\Category.name)
            ]
        )

        return try context.fetch(descriptor)
    }

    func listAll() throws -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            sortBy: [
                SortDescriptor(\Category.kindRaw),
                SortDescriptor(\Category.sortOrder),
                SortDescriptor(\Category.name)
            ]
        )

        return try context.fetch(descriptor)
    }

    func get(id: UUID) throws -> Category {
        var descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { category in
                category.id == id
            }
        )
        descriptor.fetchLimit = 1

        guard let category = try context.fetch(descriptor).first else {
            throw ServiceError.categoryNotFound
        }

        return category
    }

    func validate(id: UUID?, kind: TransactionKind) throws -> Category {
        guard let id else {
            throw ServiceError.categoryRequired
        }

        let category = try get(id: id)
        guard category.kindRaw == kind.rawValue else {
            throw ServiceError.categoryKindMismatch
        }

        return category
    }
}
