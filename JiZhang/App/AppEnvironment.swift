import Foundation
import Observation
import SwiftData

enum BootstrapState: Equatable {
    case idle
    case preparing
    case ready
    case failed(String)
}

@MainActor
@Observable
final class AppEnvironment {
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    let ledgerService: LedgerService
    let categoryService: CategoryService
    let transactionService: TransactionService
    let calendarService: CalendarService
    let statisticsService: StatisticsService

    var ledgerPeriod = LedgerPeriodSelection.current()

    private let bootstrapService: AppBootstrapService
    private(set) var bootstrapState: BootstrapState = .idle

    init(modelContainer: ModelContainer) {
        let context = ModelContext(modelContainer)
        let calendarService = CalendarService()
        let categoryService = CategoryService(context: context)
        let transactionService = TransactionService(context: context)

        self.modelContainer = modelContainer
        self.modelContext = context
        self.ledgerService = LedgerService(context: context)
        self.categoryService = categoryService
        self.transactionService = transactionService
        self.calendarService = calendarService
        self.statisticsService = StatisticsService(
            transactionService: transactionService,
            categoryService: categoryService,
            calendarService: calendarService
        )
        self.bootstrapService = AppBootstrapService(context: context)
    }

    func start(force: Bool = false) {
        if !force {
            switch bootstrapState {
            case .idle, .failed:
                break
            case .preparing, .ready:
                return
            }
        }

        bootstrapState = .preparing

        do {
            _ = try bootstrapService.prepare()
            bootstrapState = .ready
        } catch {
            bootstrapState = .failed(
                (error as? LocalizedError)?.errorDescription ?? "应用初始化失败"
            )
        }
    }
}
