import SwiftUI

struct PeriodSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var mode: LedgerPeriodMode
    @State private var selectedYear: Int
    @State private var selectedMonth: Int

    let onSelect: (LedgerPeriodSelection) -> Void

    init(
        selection: LedgerPeriodSelection,
        onSelect: @escaping (LedgerPeriodSelection) -> Void
    ) {
        let now = Date()
        let year = Calendar.current.component(.year, from: now)
        let month = Calendar.current.component(.month, from: now)

        _mode = State(initialValue: selection.mode)
        _selectedYear = State(
            initialValue: selection.mode == .month
                ? selection.year
                : year
        )
        _selectedMonth = State(
            initialValue: selection.mode == .month
                ? selection.month
                : month
        )
        self.onSelect = onSelect
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xLarge) {
                Text("选择周期")
                    .font(.title2.weight(.bold))

                modeSection

                switch mode {
                case .month:
                    monthSelection
                case .year:
                    yearSelection
                case .all:
                    allSelection
                }
            }
            .padding(DesignTokens.Spacing.large)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .presentationDetents([.height(480)])
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Text("显示方式")
                .font(.headline)

            HStack(spacing: DesignTokens.Spacing.small) {
                ForEach(LedgerPeriodMode.allCases, id: \.self) { mode in
                    Button {
                        self.mode = mode
                    } label: {
                        Label(mode.displayName, systemImage: iconName(for: mode))
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignTokens.Spacing.small)
                            .background(
                                self.mode == mode
                                    ? selectionBlue
                                    : Color.clear,
                                in: RoundedRectangle(
                                    cornerRadius: DesignTokens.Radius.control
                                )
                            )
                            .foregroundStyle(
                                self.mode == mode
                                    ? Color.white
                                    : Color.primary
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DesignTokens.Spacing.medium)
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
            )
        }
    }

    private var monthSelection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
            Text("选择月份")
                .font(.headline)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokens.Spacing.medium) {
                        ForEach(monthYearRange, id: \.self) { year in
                            Button {
                                selectedYear = year
                            } label: {
                                Text(String(year))
                                    .font(.headline)
                                    .frame(width: 78, height: 48)
                                    .background(
                                        selectedYear == year
                                            ? selectionBlue
                                            : Color(
                                                uiColor: .secondarySystemGroupedBackground
                                            ),
                                        in: RoundedRectangle(
                                            cornerRadius: DesignTokens.Radius.control
                                        )
                                    )
                                    .foregroundStyle(
                                        selectedYear == year
                                            ? Color.white
                                            : Color.primary
                                    )
                            }
                            .buttonStyle(.plain)
                            .id(year)
                        }
                    }
                    .padding(.horizontal, 1)
                }
                .onAppear {
                    proxy.scrollTo(selectedYear, anchor: .center)
                }
                .onChange(of: selectedYear) { _, year in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(year, anchor: .center)
                    }
                }
            }

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible()),
                    count: 4
                ),
                spacing: DesignTokens.Spacing.medium
            ) {
                ForEach(1...12, id: \.self) { month in
                    Button {
                        commit(
                            LedgerPeriodSelection(
                                mode: .month,
                                year: selectedYear,
                                month: month
                            )
                        )
                    } label: {
                        Text("\(month)月")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignTokens.Spacing.medium)
                            .background(
                                selectedMonth == month
                                    ? selectionBlue
                                    : Color(
                                        uiColor: .secondarySystemGroupedBackground
                                    ),
                                in: RoundedRectangle(
                                    cornerRadius: DesignTokens.Radius.control
                                )
                            )
                            .foregroundStyle(
                                selectedMonth == month
                                    ? Color.white
                                    : Color.primary
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var yearSelection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
            Text("选择年份")
                .font(.headline)

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible()),
                    count: 4
                ),
                spacing: DesignTokens.Spacing.medium
            ) {
                ForEach(recentYearRange, id: \.self) { year in
                    Button {
                        commit(
                            LedgerPeriodSelection(
                                mode: .year,
                                year: year,
                                month: Calendar.current.component(
                                    .month,
                                    from: Date()
                                )
                            )
                        )
                    } label: {
                        Text(String(year))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignTokens.Spacing.medium)
                            .background(
                                year == currentYear
                                    ? selectionBlue
                                    : Color(
                                        uiColor: .secondarySystemGroupedBackground
                                    ),
                                in: RoundedRectangle(
                                    cornerRadius: DesignTokens.Radius.control
                                )
                            )
                            .foregroundStyle(
                                year == currentYear
                                    ? Color.white
                                    : Color.primary
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var allSelection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
            Text("在首页加载当前账本下所有时间范围内的数据")
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(DesignTokens.Spacing.large)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                )

            Image("LedgerCardBackground")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 132)
                .clipShape(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                )
                .clipped()
                .accessibilityHidden(true)

            Button("确认") {
                commit(
                    LedgerPeriodSelection(
                        mode: .all,
                        year: currentYear,
                        month: Calendar.current.component(
                            .month,
                            from: Date()
                        )
                    )
                )
            }
            .buttonStyle(.plain)
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                selectionBlue,
                in: RoundedRectangle(
                    cornerRadius: DesignTokens.Radius.control
                )
            )
        }
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    private var monthYearRange: [Int] {
        Array(1990...(currentYear + 10))
    }

    private var recentYearRange: [Int] {
        let start = currentYear - 8
        return Array(start...(start + 15))
            .sorted()
    }

    private func commit(_ selection: LedgerPeriodSelection) {
        onSelect(selection)
        dismiss()
    }

    private func iconName(for mode: LedgerPeriodMode) -> String {
        switch mode {
        case .month:
            "calendar"
        case .year:
            "calendar.badge.clock"
        case .all:
            "infinity"
        }
    }

    private var selectionBlue: Color {
        Color(
            red: 79.0 / 255.0,
            green: 150.0 / 255.0,
            blue: 247.0 / 255.0
        )
    }
}
