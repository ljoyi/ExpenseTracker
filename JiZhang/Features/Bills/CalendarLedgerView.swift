import SwiftUI

@MainActor
struct CalendarLedgerView: View {
    @State private var viewModel: CalendarLedgerViewModel

    init(environment: AppEnvironment) {
        _viewModel = State(
            initialValue: CalendarLedgerViewModel(
                environment: environment
            )
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.large) {
                calendarCard
                monthSummaryView
                selectedDateSection
            }
            .padding(DesignTokens.Spacing.large)
            .padding(.bottom, DesignTokens.Spacing.xLarge)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("账单日历")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("今天") {
                    viewModel.goToday()
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .alert(
            "日历加载失败",
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
    }

    private var monthNavigation: some View {
        HStack(spacing: DesignTokens.Spacing.xSmall) {
            Spacer()

            Button {
                viewModel.moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .accessibilityLabel("上个月")

            Text(viewModel.monthTitle)
                .font(.title3.weight(.semibold))

            Button {
                viewModel.moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .accessibilityLabel("下个月")

            Spacer()
        }
    }

    private var calendarCard: some View {
        VStack(spacing: DesignTokens.Spacing.small) {
            monthNavigation
                .padding(.bottom, DesignTokens.Spacing.xSmall)

            LazyVGrid(columns: calendarColumns, spacing: 6) {
                ForEach(weekdayTitles, id: \.self) { title in
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: calendarColumns, spacing: 6) {
                ForEach(viewModel.days) { day in
                    if day.isInDisplayedMonth {
                        dayCell(day)
                    } else {
                        Color.clear
                            .frame(height: 54)
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.medium)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
        )
    }

    private func dayCell(_ day: CalendarDay) -> some View {
        let isSelected = Calendar.current.isDate(
            day.date,
            inSameDayAs: viewModel.selectedDate
        )
        let group = viewModel.group(for: day.date)
        let expense = group?.expenseMinorUnits ?? 0
        let income = group?.incomeMinorUnits ?? 0

        return Button {
            viewModel.selectDate(day.date)
        } label: {
            VStack(spacing: 2) {
                Text(day.date.formatted(.dateTime.day()))
                    .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(.primary)

                if expense > 0 {
                    Text("-" + MoneyAmount.compactText(minorUnits: expense))
                        .foregroundStyle(DesignTokens.ColorToken.expense)
                        .font(.system(size: 8, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }

                if income > 0 {
                    Text("+" + MoneyAmount.compactText(minorUnits: income))
                        .foregroundStyle(DesignTokens.ColorToken.income)
                        .font(.system(size: 8, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54, alignment: .top)
            .padding(.vertical, 3)
            .background(
                Color(uiColor: .systemBackground),
                in: RoundedRectangle(cornerRadius: 6)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isSelected ? Color.accentColor : Color.clear,
                        lineWidth: 1.5
                    )
            }
            .shadow(
                color: isSelected
                    ? Color.accentColor.opacity(0.45)
                    : Color.black.opacity(0.08),
                radius: isSelected ? 6 : 3,
                y: 2
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            day.date.formatted(
                .dateTime.year().month().day()
            )
        )
    }

    private var monthSummaryView: some View {
        HStack {
            summaryItem(
                title: "月收入",
                amount: viewModel.monthSummary.totalIncomeMinorUnits,
                color: DesignTokens.ColorToken.income
            )
            Spacer()
            summaryItem(
                title: "月支出",
                amount: viewModel.monthSummary.totalExpenseMinorUnits,
                color: DesignTokens.ColorToken.expense
            )
            Spacer()
            summaryItem(
                title: "月结余",
                amount: viewModel.monthSummary.balanceMinorUnits,
                color: viewModel.monthSummary.balanceMinorUnits < 0
                    ? DesignTokens.ColorToken.expense
                    : DesignTokens.ColorToken.income
            )
        }
        .padding(DesignTokens.Spacing.medium)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
        )
    }

    private func summaryItem(
        title: String,
        amount: Int64,
        color: Color
    ) -> some View {
        HStack(spacing: DesignTokens.Spacing.xSmall) {
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
    }

    @ViewBuilder
    private var selectedDateSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Text(
                viewModel.selectedDate.formatted(
                    .dateTime
                        .month()
                        .day()
                        .weekday(.wide)
                        .locale(Locale(identifier: "zh_CN"))
                )
            )
            .font(.headline)

            if let group = viewModel.selectedGroup {
                DayTransactionCard(
                    group: group,
                    environment: viewModel.environment,
                    onChanged: viewModel.load
                )
            } else {
                EmptyStateView(
                    title: "当天没有账单",
                    systemImage: "calendar"
                )
                .frame(minHeight: 160)
                .frame(maxWidth: .infinity)
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                )
            }
        }
    }

    private var calendarColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 4),
            count: 7
        )
    }

    private var weekdayTitles: [String] {
        [
            "周一",
            "周二",
            "周三",
            "周四",
            "周五",
            "周六",
            "周日"
        ]
    }
}
