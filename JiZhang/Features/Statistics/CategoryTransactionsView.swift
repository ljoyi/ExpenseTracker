import SwiftUI

@MainActor
struct CategoryTransactionsView: View {
    let categoryID: UUID
    let categoryName: String
    let range: DateRange
    let kind: TransactionKind
    let environment: AppEnvironment

    @State private var groups: [DayTransactionGroup] = []
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if groups.isEmpty {
                EmptyStateView(
                    title: "暂无账单",
                    systemImage: "list.bullet"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignTokens.Spacing.large) {
                        ForEach(groups) { group in
                            DayTransactionCard(
                                group: group,
                                environment: environment,
                                onChanged: load
                            )
                        }
                    }
                    .padding(DesignTokens.Spacing.large)
                }
            }
        }
        .navigationTitle(categoryName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            load()
        }
        .alert(
            "加载失败",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        errorMessage = nil
                    }
                }
            )
        ) {
            Button("好", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func load() {
        do {
            let snapshots = try environment.statisticsService
                .categoryTransactions(
                    range: range,
                    kind: kind,
                    categoryID: categoryID
                )
            let items = try makeDisplayItems(
                snapshots: snapshots,
                categoryService: environment.categoryService
            )
            groups = makeDayGroups(items: items)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "加载失败，请重试"
        }
    }
}
