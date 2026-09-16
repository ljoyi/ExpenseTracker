import SwiftUI

struct DayTransactionCard: View {
    enum HeaderContent {
        case date
        case balance
    }

    let group: DayTransactionGroup
    let environment: AppEnvironment
    let onChanged: () -> Void
    let headerContent: HeaderContent

    init(
        group: DayTransactionGroup,
        environment: AppEnvironment,
        onChanged: @escaping () -> Void,
        headerContent: HeaderContent = .date
    ) {
        self.group = group
        self.environment = environment
        self.onChanged = onChanged
        self.headerContent = headerContent
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                headerTitle
                    .font(.headline)

                Spacer()

                HStack(spacing: DesignTokens.Spacing.small) {
                    if group.incomeMinorUnits != 0 {
                        summaryText(
                            title: "收",
                            amount: group.incomeMinorUnits,
                            kind: .income
                        )
                    }
                    if group.expenseMinorUnits != 0 {
                        summaryText(
                            title: "支",
                            amount: group.expenseMinorUnits,
                            kind: .expense
                        )
                    }
                }
                .font(.caption)
            }
            .padding(DesignTokens.Spacing.medium)

            Divider()

            ForEach(group.items) { item in
                NavigationLink {
                    TransactionDetailView(
                        transactionID: item.id,
                        environment: environment,
                        onChanged: onChanged
                    )
                } label: {
                    HStack(alignment: .center, spacing: DesignTokens.Spacing.medium) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("· \(item.categoryName)")
                            Text(
                                item.snapshot.occurredAt.formatted(
                                    date: .omitted,
                                    time: .shortened
                                )
                            )
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(signedAmount(for: item.snapshot))
                            .monospacedDigit()
                            .foregroundStyle(color(for: item.snapshot.kind))
                    }
                    .padding(.horizontal, DesignTokens.Spacing.medium)
                    .padding(.vertical, DesignTokens.Spacing.small)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if item.id != group.items.last?.id {
                    Divider()
                        .padding(.leading, DesignTokens.Spacing.medium)
                }
            }
        }
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
        )
    }

    private func summaryText(
        title: String,
        amount: Int64,
        kind: TransactionKind
    ) -> some View {
        HStack(spacing: 2) {
            Text("\(title)：")
                .foregroundStyle(.secondary)
            Text(compactSignedAmount(amount: amount, kind: kind))
                .foregroundStyle(color(for: kind))
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private var headerTitle: some View {
        switch headerContent {
        case .date:
            Text(dayTitle)
        case .balance:
            Text(
                "结余：\(MoneyAmount.display(minorUnits: group.balanceMinorUnits))"
            )
        }
    }

    private var dayTitle: String {
        let components = Calendar.current.dateComponents(
            [.month, .day, .weekday],
            from: group.date
        )
        let weekdays = [
            "周日",
            "周一",
            "周二",
            "周三",
            "周四",
            "周五",
            "周六"
        ]
        let month = components.month ?? 1
        let day = components.day ?? 1
        let weekdayIndex = (components.weekday ?? 1) - 1

        return String(
            format: "%02d-%02d %@",
            month,
            day,
            weekdays[weekdayIndex]
        )
    }

    private func signedAmount(for snapshot: TransactionSnapshot) -> String {
        compactSignedAmount(
            amount: snapshot.amountMinorUnits,
            kind: snapshot.kind
        )
    }

    private func compactSignedAmount(
        amount: Int64,
        kind: TransactionKind
    ) -> String {
        guard amount != 0 else {
            return "0"
        }

        return kind.signedPrefix + MoneyAmount.compactText(
            minorUnits: amount
        )
    }

    private func color(for kind: TransactionKind) -> Color {
        kind == .income
            ? DesignTokens.ColorToken.income
            : DesignTokens.ColorToken.expense
    }
}
