import SwiftData

enum ModelContainerFactory {
    @MainActor
    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(AppSchemaV1.models)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
}
