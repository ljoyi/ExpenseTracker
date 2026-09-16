import Foundation

struct TransactionDisplayItem: Identifiable, Equatable {
    let snapshot: TransactionSnapshot
    let categoryName: String
    let iconName: String
    let colorHex: String

    var id: UUID {
        snapshot.id
    }
}

@MainActor
func makeDisplayItems(
    snapshots: [TransactionSnapshot],
    categoryService: CategoryService
) throws -> [TransactionDisplayItem] {
    let categories = try categoryService.listAll()
    let categoriesByID = Dictionary(
        uniqueKeysWithValues: categories.map { ($0.id, $0) }
    )

    return try snapshots.map { snapshot in
        guard let category = categoriesByID[snapshot.categoryID] else {
            throw ServiceError.corruptData
        }

        return TransactionDisplayItem(
            snapshot: snapshot,
            categoryName: category.name,
            iconName: category.iconName,
            colorHex: category.colorHex
        )
    }
}
