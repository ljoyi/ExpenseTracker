import SwiftUI

struct LedgerCardView: View {
    let summary: StatisticsSummary
    let periodMode: LedgerPeriodMode
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Image("LedgerCardBackground")
                    .resizable()
                    .scaledToFill()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.05),
                        Color.black.opacity(0.32)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(alignment: .leading) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                        Text(balanceTitle)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.78))
                        Text(
                            MoneyAmount.display(
                                minorUnits: summary.balanceMinorUnits
                            )
                        )
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    }

                    Spacer()

                    HStack {
                        amountCell(
                            title: incomeTitle,
                            amount: summary.totalIncomeMinorUnits,
                            color: DesignTokens.ColorToken.income
                        )
                        Spacer()
                        amountCell(
                            title: expenseTitle,
                            amount: summary.totalExpenseMinorUnits,
                            color: DesignTokens.ColorToken.expense
                        )
                    }
                }
                .padding(DesignTokens.Spacing.xLarge)
            }
            .frame(height: 220)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
            )
            .shadow(color: .black.opacity(0.14), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("账本")
        .accessibilityValue(
            "结余 \(MoneyAmount.display(minorUnits: summary.balanceMinorUnits))"
        )
    }

    private func amountCell(
        title: String,
        amount: Int64,
        color: Color
    ) -> some View {
        HStack(spacing: DesignTokens.Spacing.xSmall) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.76))
            Text(MoneyAmount.display(minorUnits: amount))
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var balanceTitle: String {
        switch periodMode {
        case .month:
            "月结余"
        case .year:
            "年结余"
        case .all:
            "总结余"
        }
    }

    private var incomeTitle: String {
        switch periodMode {
        case .month:
            "月收入"
        case .year:
            "年收入"
        case .all:
            "总收入"
        }
    }

    private var expenseTitle: String {
        switch periodMode {
        case .month:
            "月支出"
        case .year:
            "年支出"
        case .all:
            "总支出"
        }
    }
}
