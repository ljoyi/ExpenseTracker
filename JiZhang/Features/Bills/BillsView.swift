import SwiftUI

@MainActor
struct BillsView: View {
    @State private var viewModel: BillsViewModel
    @State private var isShowingPeriodPicker = false
    @State private var isShowingStatistics = false

    init(
        environment: AppEnvironment,
        refreshToken: Int
    ) {
        _viewModel = State(
            initialValue: BillsViewModel(environment: environment)
        )
        self.refreshToken = refreshToken
    }

    let refreshToken: Int

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                topBar

                ScrollView {
                    LazyVStack(spacing: DesignTokens.Spacing.large) {
                        LedgerCardView(
                            summary: viewModel.summary,
                            periodMode: viewModel.environment.ledgerPeriod.mode,
                            onTap: {
                                isShowingStatistics = true
                            }
                        )

                        recordsSection
                    }
                    .padding(.horizontal, DesignTokens.Spacing.large)
                    .padding(.bottom, DesignTokens.Spacing.xLarge)
                }
                .background(Color(uiColor: .systemGroupedBackground))
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
            .overlay {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    ProgressView()
                }
            }
            .alert(
                "账单加载失败",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            viewModel.errorMessage = nil
                        }
                    }
                )
            ) {
                Button("重试") {
                    viewModel.load()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                viewModel.load()
            }
            .sheet(isPresented: $isShowingPeriodPicker) {
                PeriodSelectionSheet(
                    selection: viewModel.environment.ledgerPeriod
                ) { selection in
                    viewModel.selectPeriod(selection)
                }
                .presentationDragIndicator(.visible)
            }
            .navigationDestination(isPresented: $isShowingStatistics) {
                StatisticsView(environment: viewModel.environment)
            }
            .onChange(of: refreshToken) {
                viewModel.load()
            }
        }
    }

    private var periodLabel: some View {
        Button {
            isShowingPeriodPicker = true
        } label: {
            HStack(spacing: DesignTokens.Spacing.xSmall) {
                Text(viewModel.periodTitle)
                    .font(.headline)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, DesignTokens.Spacing.medium)
            .padding(.vertical, DesignTokens.Spacing.small)
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("账本周期")
        .accessibilityValue(viewModel.periodTitle)
    }

    private var topBar: some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            periodLabel

            Spacer()

            NavigationLink {
                CalendarLedgerView(
                    environment: viewModel.environment
                )
            } label: {
                Image(systemName: "calendar")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(
                        Color(uiColor: .secondarySystemGroupedBackground),
                        in: Circle()
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("账单日历")
        }
        .padding(.horizontal, DesignTokens.Spacing.large)
        .padding(.vertical, DesignTokens.Spacing.small)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var recordsSection: some View {
        if viewModel.groups.isEmpty {
            EmptyStateView(
                title: "暂无账单",
                systemImage: "tray",
                message: "点击下方按钮记录第一笔"
            )
            .frame(minHeight: 220)
            .frame(maxWidth: .infinity)
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
            )
        } else {
            ForEach(viewModel.groups) { group in
                DayTransactionCard(
                    group: group,
                    environment: viewModel.environment,
                    onChanged: viewModel.load
                )
            }
        }
    }

}
