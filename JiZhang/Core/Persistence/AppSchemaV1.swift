import SwiftData

enum AppSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [
            Ledger.self,
            Category.self,
            Transaction.self
        ]
    }
}
