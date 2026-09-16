import Foundation

struct DayTransactionGroup: Identifiable, Equatable {
    let date: Date
    let items: [TransactionDisplayItem]

    var id: Date {
        date
    }

    var incomeMinorUnits: Int64 {
        items
            .filter { $0.snapshot.kind == .income }
            .reduce(into: Int64(0)) { result, item in
                result += item.snapshot.amountMinorUnits
            }
    }

    var expenseMinorUnits: Int64 {
        items
            .filter { $0.snapshot.kind == .expense }
            .reduce(into: Int64(0)) { result, item in
                result += item.snapshot.amountMinorUnits
            }
    }

    var balanceMinorUnits: Int64 {
        incomeMinorUnits - expenseMinorUnits
    }
}

func makeDayGroups(
    items: [TransactionDisplayItem],
    calendar: Calendar = .current
) -> [DayTransactionGroup] {
    let grouped = Dictionary(grouping: items) { item in
        calendar.startOfDay(for: item.snapshot.occurredAt)
    }

    return grouped
        .map { date, items in
            DayTransactionGroup(
                date: date,
                items: items.sorted { lhs, rhs in
                    if lhs.snapshot.occurredAt != rhs.snapshot.occurredAt {
                        return lhs.snapshot.occurredAt > rhs.snapshot.occurredAt
                    }
                    return lhs.snapshot.createdAt > rhs.snapshot.createdAt
                }
            )
        }
        .sorted { $0.date > $1.date }
}
