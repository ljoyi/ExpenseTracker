import SwiftUI

struct AmountKeypad: View {
    let onDigit: (String) -> Void
    let onDecimalPoint: () -> Void
    let onOperator: (Character) -> Void
    let onDelete: () -> Void
    let onClear: () -> Void
    let canSave: Bool
    let onSave: () -> Void

    private let rows = [
        ["1", "2", "3", "delete"],
        ["4", "5", "6", "-"],
        ["7", "8", "9", "+"],
        ["clear", "0", ".", "save"]
    ]

    var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 7) {
            ForEach(rows, id: \.self) { row in
                GridRow {
                    ForEach(row, id: \.self) { key in
                        keyButton(for: key)
                    }
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.medium)
        .padding(.vertical, DesignTokens.Spacing.xSmall)
    }

    @ViewBuilder
    private func keyButton(for key: String) -> some View {
        Button {
            switch key {
            case "delete":
                onDelete()
            case "clear":
                onClear()
            case ".":
                onDecimalPoint()
            case "-", "+":
                onOperator(Character(key))
            case "save":
                onSave()
            default:
                onDigit(key)
            }
        } label: {
            Group {
                switch key {
                case "delete":
                    Image(systemName: "delete.left")
                case "clear":
                    Text("清除")
                case "save":
                    Text("保存")
                default:
                    Text(key)
                }
            }
            .font(.headline)
            .monospacedDigit()
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .foregroundStyle(foregroundColor(for: key))
            .background(
                Color.white.opacity(0.92),
                in: RoundedRectangle(
                    cornerRadius: 8,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 8,
                    style: .continuous
                )
                .stroke(Color.white.opacity(0.65), lineWidth: 0.8)
            }
            .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(key == "save" && !canSave)
        .opacity(key == "save" && !canSave ? 0.45 : 1)
        .accessibilityLabel(accessibilityLabel(for: key))
    }

    private func foregroundColor(for key: String) -> Color {
        switch key {
        case "save":
            .accentColor
        case "+", "-":
            .accentColor
        default:
            Color.black.opacity(0.78)
        }
    }

    private func accessibilityLabel(for key: String) -> String {
        switch key {
        case "delete":
            "删除"
        case "clear":
            "清除"
        case "save":
            "保存"
        default:
            key
        }
    }
}
