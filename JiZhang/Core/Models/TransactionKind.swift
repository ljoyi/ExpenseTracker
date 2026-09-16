import Foundation

enum TransactionKind: String, CaseIterable, Codable, Sendable {
    case expense
    case income

    var displayName: String {
        switch self {
        case .expense:
            "支出"
        case .income:
            "收入"
        }
    }

    var signedPrefix: String {
        switch self {
        case .expense:
            "-"
        case .income:
            "+"
        }
    }
}
