import Foundation

struct DateRange: Equatable, Sendable {
    let start: Date
    let end: Date

    init?(start: Date, end: Date) {
        guard start < end else {
            return nil
        }

        self.start = start
        self.end = end
    }

    func contains(_ date: Date) -> Bool {
        start <= date && date < end
    }
}

struct CalendarDay: Identifiable, Equatable, Sendable {
    let date: Date
    let isInDisplayedMonth: Bool

    var id: Date {
        date
    }
}
