import Charts
import SwiftUI

@MainActor
struct StatisticsView: View {
    let environment: AppEnvironment
    @State private var viewModel: StatisticsViewModel
    @State private var isShowingPeriodPicker = false

    init(environment: AppEnvironment) {
        self.environment = environment
        _viewModel = State(
            initialValue: StatisticsViewModel(environment: environment)
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.large) {
                periodButton
                StatisticsSummaryCard(summary: viewModel.summary)
                kindPicker
                breakdownSection
            }
            .padding(DesignTokens.Spacing.large)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .alert(
            "统计加载失败",
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
            viewModel.applyLedgerPeriod(environment.ledgerPeriod)
        }
        .onAppear {
            viewModel.applyLedgerPeriod(environment.ledgerPeriod)
        }
        .onChange(of: environment.ledgerPeriod) { _, selection in
            viewModel.applyLedgerPeriod(selection)
        }
        .sheet(isPresented: $isShowingPeriodPicker) {
            StatisticsPeriodPickerView(
                selectedPeriod: viewModel.period,
                customStart: viewModel.customStart,
                customEnd: viewModel.customEnd
            ) { period, start, end in
                if period == .custom {
                    viewModel.updateCustomRange(start: start, end: end)
                } else {
                    viewModel.selectPeriod(period)
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var periodButton: some View {
        Button {
            isShowingPeriodPicker = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                    Text(viewModel.periodName)
                        .font(.headline)
                    Text(viewModel.rangeLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(DesignTokens.Spacing.large)
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("统计周期")
        .accessibilityValue(viewModel.periodName)
    }

    private var kindPicker: some View {
        Picker(
            "统计类型",
            selection: Binding(
                get: { viewModel.kind },
                set: { viewModel.changeKind($0) }
            )
        ) {
            Text("支出")
                .tag(TransactionKind.expense)
            Text("收入")
                .tag(TransactionKind.income)
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var breakdownSection: some View {
        if viewModel.breakdown.hasData {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
                Text("分类占比")
                    .font(.headline)

                Chart(viewModel.breakdown.items) { item in
                    SectorMark(
                        angle: .value(
                            "金额",
                            Double(item.amountMinorUnits)
                        ),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(Color(hex: item.colorHex))
                }
                .chartLegend(.hidden)
                .frame(height: 220)
                .accessibilityLabel("分类占比饼图")

                ForEach(viewModel.breakdown.items) { item in
                    if let range = viewModel.range {
                        NavigationLink {
                            CategoryTransactionsView(
                                categoryID: item.categoryID,
                                categoryName: item.categoryName,
                                range: range,
                                kind: viewModel.kind,
                                environment: viewModel.environment
                            )
                        } label: {
                            CategoryBreakdownRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(DesignTokens.Spacing.large)
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
            )
        } else {
            EmptyStateView(
                title: viewModel.kind == .expense
                    ? "本周期暂无支出"
                    : "本周期暂无收入",
                systemImage: "chart.pie",
                message: "记录账单后即可查看分类占比"
            )
            .frame(minHeight: 260)
            .frame(maxWidth: .infinity)
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
            )
        }
    }
}

private struct StatisticsSummaryCard: View {
    let summary: StatisticsSummary

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: DesignTokens.Spacing.medium),
                GridItem(.flexible(), spacing: DesignTokens.Spacing.medium)
            ],
            spacing: DesignTokens.Spacing.medium
        ) {
            metric(
                title: "收入",
                amount: summary.totalIncomeMinorUnits,
                color: DesignTokens.ColorToken.income
            )
            metric(
                title: "支出",
                amount: summary.totalExpenseMinorUnits,
                color: DesignTokens.ColorToken.expense
            )
            metric(
                title: "结余",
                amount: summary.balanceMinorUnits,
                color: summary.balanceMinorUnits < 0
                    ? DesignTokens.ColorToken.expense
                    : DesignTokens.ColorToken.income
            )

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                Text("日均支出")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(
                    summary.dailyAverageExpense.formatted(
                        .currency(code: "CNY")
                            .precision(.fractionLength(2))
                            .locale(Locale(identifier: "zh_CN"))
                    )
                )
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignTokens.Spacing.medium)
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
            )
        }
    }

    private func metric(
        title: String,
        amount: Int64,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(MoneyAmount.display(minorUnits: amount))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.medium)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
        )
    }
}

private struct CategoryBreakdownRow: View {
    let item: CategoryBreakdownItem

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            Image(systemName: item.iconName)
                .foregroundStyle(Color(hex: item.colorHex))
                .frame(width: 32, height: 32)
                .background(
                    Color(hex: item.colorHex).opacity(0.12),
                    in: Circle()
                )

            Text(item.categoryName)

            Spacer()

            VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xSmall) {
                Text(MoneyAmount.display(minorUnits: item.amountMinorUnits))
                    .monospacedDigit()
                Text(
                    item.share.formatted(
                        .number.precision(.fractionLength(1))
                    ) + "%"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.categoryName)
        .accessibilityHint("查看该分类的账单")
    }
}

private struct StatisticsPeriodPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var period: StatisticsPeriod
    @State private var customStart: Date
    @State private var customEnd: Date

    let onSelect: (StatisticsPeriod, Date, Date) -> Void

    init(
        selectedPeriod: StatisticsPeriod,
        customStart: Date,
        customEnd: Date,
        onSelect: @escaping (StatisticsPeriod, Date, Date) -> Void
    ) {
        _period = State(initialValue: selectedPeriod)
        _customStart = State(initialValue: customStart)
        _customEnd = State(initialValue: customEnd)
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(StatisticsPeriod.allCases, id: \.self) { period in
                        Button {
                            self.period = period
                        } label: {
                            HStack {
                                Text(period.displayName)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if self.period == period {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                }

                if period == .custom {
                    Section("自定义日期") {
                        DatePicker(
                            "开始日期",
                            selection: $customStart,
                            displayedComponents: .date
                        )
                        DatePicker(
                            "结束日期",
                            selection: $customEnd,
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle("统计周期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        onSelect(period, customStart, customEnd)
                        dismiss()
                    }
                    .disabled(period == .custom && customStart > customEnd)
                }
            }
        }
    }
}
