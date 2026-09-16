import SwiftUI

@MainActor
struct TransactionDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let transactionID: UUID
    let environment: AppEnvironment
    let onChanged: (() -> Void)?

    @State private var snapshot: TransactionSnapshot?
    @State private var category: Category?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isShowingEdit = false
    @State private var isShowingDeleteConfirmation = false

    init(
        transactionID: UUID,
        environment: AppEnvironment,
        onChanged: (() -> Void)? = nil
    ) {
        self.transactionID = transactionID
        self.environment = environment
        self.onChanged = onChanged
    }

    var body: some View {
        Group {
            if let snapshot {
                detailContent(snapshot)
            } else if isLoading {
                ProgressView()
            } else {
                ContentUnavailableView {
                    Label("无法加载账单", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage ?? "该账单已不存在")
                } actions: {
                    Button("返回") {
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle("账单详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            if snapshot != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("修改") {
                        isShowingEdit = true
                    }
                    .disabled(isLoading)
                }
            }
        }
        .task {
            load()
        }
        .fullScreenCover(isPresented: $isShowingEdit) {
            if let snapshot {
                EntryView(
                    environment: environment,
                    transaction: snapshot
                ) {
                    load()
                    onChanged?()
                }
            }
        }
        .alert(
            "删除这笔账单？",
            isPresented: $isShowingDeleteConfirmation
        ) {
            Button("删除", role: .destructive) {
                deleteTransaction()
            }
            Button("取消", role: .cancel) {}
        } message: {
            if let snapshot {
                Text(
                    "\(category?.name ?? "未分类") "
                        + MoneyAmount.display(
                            minorUnits: snapshot.amountMinorUnits
                        )
                )
            }
        }
        .alert(
            "操作失败",
            isPresented: Binding(
                get: {
                    errorMessage != nil && snapshot != nil
                },
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

    private func detailContent(_ snapshot: TransactionSnapshot) -> some View {
        List {
            Section {
                VStack(spacing: DesignTokens.Spacing.small) {
                    Text(snapshot.kind.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    AmountText(
                        amountMinorUnits: snapshot.amountMinorUnits,
                        kind: snapshot.kind,
                        font: .system(size: 38, weight: .semibold)
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.xLarge)
            }

            Section {
                LabeledContent("分类", value: category?.name ?? "未分类")
                LabeledContent(
                    "时间",
                    value: snapshot.occurredAt.formatted(
                        date: .numeric,
                        time: .shortened
                    )
                )
                LabeledContent("类型", value: snapshot.kind.displayName)
            }

            Section {
                Button("删除账单", role: .destructive) {
                    isShowingDeleteConfirmation = true
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func load() {
        isLoading = true
        defer {
            isLoading = false
        }

        do {
            let snapshot = try environment.transactionService.get(
                transactionID: transactionID
            )
            self.snapshot = snapshot
            self.category = try environment.categoryService.get(
                id: snapshot.categoryID
            )
            self.errorMessage = nil
        } catch {
            self.snapshot = nil
            self.category = nil
            self.errorMessage = message(for: error)
        }
    }

    private func deleteTransaction() {
        do {
            _ = try environment.transactionService.delete(
                transactionID: transactionID
            )
            onChanged?()
            dismiss()
        } catch {
            errorMessage = message(for: error)
        }
    }

    private func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? "操作失败，请重试"
    }
}
