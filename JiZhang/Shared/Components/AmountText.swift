import SwiftUI

struct AmountText: View {
    let amountMinorUnits: Int64
    let kind: TransactionKind?
    var font: Font = .body

    var body: some View {
        Text(displayText)
            .font(font)
            .monospacedDigit()
            .foregroundStyle(foregroundColor)
    }

    private var displayText: String {
        guard let kind else {
            return MoneyAmount.display(minorUnits: amountMinorUnits)
        }

        return MoneyAmount.signedDisplay(
            minorUnits: amountMinorUnits,
            kind: kind
        )
    }

    private var foregroundColor: Color {
        switch kind {
        case .expense:
            DesignTokens.ColorToken.expense
        case .income:
            DesignTokens.ColorToken.income
        case nil:
            .primary
        }
    }
}
