import SwiftUI

struct DateTimePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draftDate: Date
    @State private var displayedMonth: Date
    @State private var editor: Editor = .calendar

    @State private var draftYear: Int
    @State private var draftMonth: Int
    @State private var draftHour: Int
    @State private var draftMinute: Int

    let onConfirm: (Date) -> Void

    private enum Editor {
        case calendar
        case yearMonth
        case time
    }

    init(
        initialDate: Date,
        onConfirm: @escaping (Date) -> Void
    ) {
        let components = Calendar.current.dateComponents(
            [.year, .month, .hour, .minute],
            from: initialDate
        )
        _draftDate = State(initialValue: initialDate)
        _displayedMonth = State(initialValue: initialDate)
        _draftYear = State(initialValue: components.year ?? 2026)
        _draftMonth = State(initialValue: components.month ?? 1)
        _draftHour = State(initialValue: components.hour ?? 0)
        _draftMinute = State(initialValue: components.minute ?? 0)
        self.onConfirm = onConfirm
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            Group {
                switch editor {
                case .calendar:
                    calendarEditor
                case .yearMonth:
                    yearMonthEditor
                case .time:
                    timeEditor
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var header: some View {
        HStack {
            Button("取消") {
                handleCancel()
            }

            Spacer()

            Text("选择时间")
                .font(.headline)

            Spacer()

            Button("确认") {
                handleConfirm()
            }
            .fontWeight(.semibold)
        }
        .padding(DesignTokens.Spacing.large)
    }

    private var calendarEditor: some View {
        VStack(spacing: DesignTokens.Spacing.large) {
            HStack(spacing: DesignTokens.Spacing.xSmall) {
                Spacer()
                Button {
                    moveDisplayedMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                Button(displayedMonthTitle) {
                    editor = .yearMonth
                }
                .buttonStyle(.plain)
                Button {
                    moveDisplayedMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                Spacer()
            }
            .font(.headline)

            calendarGrid

            HStack(spacing: DesignTokens.Spacing.small) {
                quickDateButton("今天", offset: 0)
                quickDateButton("昨天", offset: -1)
                quickDateButton("前天", offset: -2)
            }

            Button {
                let components = Calendar.current.dateComponents(
                    [.hour, .minute],
                    from: draftDate
                )
                draftHour = components.hour ?? 0
                draftMinute = components.minute ?? 0
                editor = .time
            } label: {
                HStack {
                    Text("时间")
                    Spacer()
                    Text(timeText)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(DesignTokens.Spacing.medium)
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(DesignTokens.Spacing.large)
    }

    private var calendarGrid: some View {
        VStack(spacing: DesignTokens.Spacing.small) {
            LazyVGrid(columns: calendarColumns, spacing: 6) {
                ForEach(weekdayTitles, id: \.self) { title in
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: calendarColumns, spacing: 6) {
                ForEach(calendarDays) { day in
                    if day.isInDisplayedMonth {
                        dateCell(day.date)
                    } else {
                        Color.clear
                            .frame(height: 48)
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

    private func dateCell(_ date: Date) -> some View {
        let isSelected = Calendar.current.isDate(
            date,
            inSameDayAs: draftDate
        )

        return Button {
            preserveTime(from: draftDate, to: date)
            draftDate = combine(
                date: date,
                hour: draftHour,
                minute: draftMinute
            )
            editor = .time
        } label: {
            Text(date.formatted(.dateTime.day()))
                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                .frame(maxWidth: .infinity)
                .frame(height: 38)
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
                        : Color.black.opacity(0.06),
                    radius: isSelected ? 6 : 2,
                    y: 2
                )
        }
        .buttonStyle(.plain)
    }

    private var yearMonthEditor: some View {
        HStack(spacing: 0) {
            Picker("年", selection: $draftYear) {
                ForEach(yearRange, id: \.self) { year in
                    Text(String(year))
                        .tag(year)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)

            Picker("月", selection: $draftMonth) {
                ForEach(1...12, id: \.self) { month in
                    Text("\(month)月")
                        .tag(month)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
        }
        .padding(DesignTokens.Spacing.large)
    }

    private var timeEditor: some View {
        HStack(spacing: 0) {
            Picker("时", selection: $draftHour) {
                ForEach(0...23, id: \.self) { hour in
                    Text(String(format: "%02d", hour))
                        .tag(hour)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)

            Text(":")
                .font(.title2.weight(.semibold))

            Picker("分", selection: $draftMinute) {
                ForEach(0...59, id: \.self) { minute in
                    Text(String(format: "%02d", minute))
                        .tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
        }
        .padding(DesignTokens.Spacing.large)
    }

    private var calendarDays: [CalendarDay] {
        (try? CalendarService().monthDays(containing: displayedMonth)) ?? []
    }

    private var calendarColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 4),
            count: 7
        )
    }

    private var weekdayTitles: [String] {
        ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
    }

    private var yearRange: [Int] {
        Array(1990...(Calendar.current.component(.year, from: Date()) + 10))
    }

    private var displayedMonthTitle: String {
        let components = Calendar.current.dateComponents(
            [.year, .month],
            from: displayedMonth
        )
        return "\(components.year ?? 0)年\(components.month ?? 0)月"
    }

    private var timeText: String {
        String(format: "%02d:%02d", draftHour, draftMinute)
    }

    private func quickDateButton(
        _ title: String,
        offset: Int
    ) -> some View {
        Button(title) {
            guard let date = Calendar.current.date(
                byAdding: .day,
                value: offset,
                to: Date()
            ) else {
                return
            }

            preserveTime(from: draftDate, to: date)
            draftDate = combine(
                date: date,
                hour: draftHour,
                minute: draftMinute
            )
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
    }

    private func moveDisplayedMonth(by value: Int) {
        guard let date = Calendar.current.date(
            byAdding: .month,
            value: value,
            to: displayedMonth
        ) else {
            return
        }

        displayedMonth = date
        if !Calendar.current.isDate(
            draftDate,
            equalTo: date,
            toGranularity: .month
        ) {
            draftDate = combine(
                date: date,
                hour: draftHour,
                minute: draftMinute
            )
        }
    }

    private func handleCancel() {
        switch editor {
        case .calendar:
            dismiss()
        case .yearMonth, .time:
            editor = .calendar
        }
    }

    private func handleConfirm() {
        switch editor {
        case .calendar:
            onConfirm(draftDate)
            dismiss()
        case .yearMonth:
            guard let month = Calendar.current.date(
                from: DateComponents(
                    year: draftYear,
                    month: draftMonth,
                    day: 1
                )
            ) else {
                return
            }
            displayedMonth = month
            let day = min(
                Calendar.current.component(.day, from: draftDate),
                numberOfDays(in: month)
            )
            draftDate = combine(
                date: Calendar.current.date(
                    byAdding: .day,
                    value: day - 1,
                    to: month
                ) ?? month,
                hour: draftHour,
                minute: draftMinute
            )
            editor = .calendar
        case .time:
            draftDate = combine(
                date: draftDate,
                hour: draftHour,
                minute: draftMinute
            )
            onConfirm(draftDate)
            dismiss()
        }
    }

    private func preserveTime(from source: Date, to date: Date) {
        let components = Calendar.current.dateComponents(
            [.hour, .minute],
            from: source
        )
        draftHour = components.hour ?? 0
        draftMinute = components.minute ?? 0
    }

    private func combine(date: Date, hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: date
        )
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components) ?? date
    }

    private func numberOfDays(in month: Date) -> Int {
        Calendar.current.range(
            of: .day,
            in: .month,
            for: month
        )?.count ?? 28
    }
}
