import Foundation
import SwiftUI
import SwiftData

@main
struct JiZhangApp: App {
    private let modelContainer: ModelContainer
    @State private var environment: AppEnvironment

    @MainActor
    init() {
        do {
            let isUITesting = ProcessInfo.processInfo.arguments
                .contains("-ui-testing")
            let modelContainer = try ModelContainerFactory.make(
                inMemory: isUITesting
            )
            self.modelContainer = modelContainer
            _environment = State(
                initialValue: AppEnvironment(modelContainer: modelContainer)
            )
        } catch {
            fatalError("无法创建本地数据库：\(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .modelContainer(modelContainer)
        }
    }
}
