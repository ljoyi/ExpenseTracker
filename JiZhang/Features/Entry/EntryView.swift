import SwiftUI

@MainActor
struct EntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Namespace private var typeSelectionNamespace
    @State private var viewModel: EntryViewModel
    @State private var isShowingDatePicker = false

    private let onSaved: (() -> Void)?

    private let categoryColumns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    init(
        environment: AppEnvironment,
        transaction: TransactionSnapshot? = nil,
        onSaved: (() -> Void)? = nil
    ) {
        _viewModel = State(
            initialValue: EntryViewModel(
                environment: environment,
                transaction: transaction
            )
        )
        self.onSaved = onSaved
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            categorySection
            fixedBottomPanel
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .sheet(isPresented: $isShowingDatePicker) {
            DateTimePickerSheet(initialDate: viewModel.occurredAt) { date in
                viewModel.occurredAt = date
            }
            .presentationDetents([.large])
        }
        .alert(
            "无法保存",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.errorMessage = nil
                    }
                }
            )
        ) {
            Button("好", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            viewModel.loadCategories()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 16)
                .onEnded { value in
                    if value.startLocation.x < 24,
                       value.translation.width > 80 {
                        dismiss()
                    }
                }
        )
    }

    private var topBar: some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .liquidGlass(cornerRadius: 20)
            .accessibilityLabel("关闭")

            HStack(spacing: 4) {
                ForEach(TransactionKind.allCases, id: \.self) { kind in
                    Button {
                        withAnimation(
                            .spring(response: 0.32, dampingFraction: 0.82)
                        ) {
                            viewModel.selectKind(kind)
                        }
                    } label: {
                        ZStack {
                            if viewModel.kind == kind {
                                RoundedRectangle(
                                    cornerRadius: 17,
                                    style: .continuous
                                )
                                .fill(color(for: kind).opacity(0.16))
                                .matchedGeometryEffect(
                                    id: "type-selection",
                                    in: typeSelectionNamespace
                                )
                            }

                            Text(kind.displayName)
                                .font(.headline)
                                .foregroundStyle(
                                    viewModel.kind == kind
                                        ? color(for: kind)
                                        : Color.secondary
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .liquidGlass(cornerRadius: 20)
        }
        .padding(.horizontal, DesignTokens.Spacing.large)
        .padding(.top, DesignTokens.Spacing.small)
    }

    private var amountDisplay: some View {
        Text(viewModel.displayAmount)
            .font(.system(size: 34, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.55)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, DesignTokens.Spacing.large)
            .padding(.vertical, DesignTokens.Spacing.medium)
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(
                    columns: categoryColumns,
                    spacing: 6
                ) {
                    ForEach(viewModel.categories, id: \.id) { category in
                        categoryButton(category)
                    }
                }
                .padding(.bottom, DesignTokens.Spacing.xSmall)
                .id(viewModel.kind)
                .transition(.opacity)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, DesignTokens.Spacing.large)
        .padding(.top, DesignTokens.Spacing.xLarge + DesignTokens.Spacing.xSmall)
        .frame(maxHeight: .infinity, alignment: .top)
        .animation(.easeInOut(duration: 0.2), value: viewModel.kind)
    }

    private func categoryButton(_ category: Category) -> some View {
        let isSelected = viewModel.selectedCategoryID == category.id

        return Button {
            viewModel.selectCategory(category.id)
        } label: {
            VStack(spacing: DesignTokens.Spacing.xSmall) {
                Image(systemName: category.iconName)
                    .font(.title3)
                    .foregroundStyle(
                        isSelected
                            ? Color.white
                            : Color(hex: category.colorHex)
                    )
                    .frame(width: 38, height: 38)
                    .background(
                        isSelected
                            ? selectedColor
                            : Color(hex: category.colorHex).opacity(0.14),
                        in: Circle()
                    )
                    .overlay {
                        Circle()
                            .stroke(
                                isSelected ? selectedColor : Color.clear,
                                lineWidth: 2
                            )
                    }

                Text(category.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var dateSection: some View {
        Button {
            isShowingDatePicker = true
        } label: {
            HStack {
                Label("时间", systemImage: "calendar")
                Spacer()
                Text(
                    viewModel.occurredAt.formatted(
                        date: .numeric,
                        time: .shortened
                    )
                )
                .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, DesignTokens.Spacing.medium)
            .frame(height: 42)
            .liquidGlass(cornerRadius: DesignTokens.Radius.control)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, DesignTokens.Spacing.large)
        .padding(.vertical, DesignTokens.Spacing.small)
    }

    private var keypad: some View {
        AmountKeypad(
            onDigit: viewModel.appendDigit,
            onDecimalPoint: viewModel.appendDecimalPoint,
            onOperator: viewModel.appendOperator,
            onDelete: viewModel.deleteLastCharacter,
            onClear: viewModel.clearAmount,
            canSave: viewModel.canSave,
            onSave: save
        )
    }

    private var fixedBottomPanel: some View {
        VStack(spacing: 0) {
            amountDisplay
            dateSection
            keypad
                .padding(.vertical, DesignTokens.Spacing.small)
                .background(
                    Color(uiColor: .tertiarySystemGroupedBackground)
                )
        }
    }

    private var selectedColor: Color {
        color(for: viewModel.kind)
    }

    private func color(for kind: TransactionKind) -> Color {
        switch kind {
        case .expense:
            DesignTokens.ColorToken.expense
        case .income:
            DesignTokens.ColorToken.income
        }
    }

    private func save() {
        if viewModel.save() {
            onSaved?()
            dismiss()
        }
    }
}

private extension View {
    func liquidGlass(cornerRadius: CGFloat) -> some View {
        background(
            .ultraThinMaterial,
            in: RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )
            .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
    }
}
