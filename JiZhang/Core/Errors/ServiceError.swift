import Foundation

enum ServiceError: Error, Equatable, LocalizedError {
    case notInitialized
    case invalidAmount
    case categoryRequired
    case categoryNotFound
    case categoryKindMismatch
    case invalidDateRange
    case transactionNotFound
    case persistenceFailure
    case corruptData

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            "应用数据尚未初始化"
        case .invalidAmount:
            "请输入有效的金额"
        case .categoryRequired:
            "请选择分类"
        case .categoryNotFound:
            "所选分类不存在"
        case .categoryKindMismatch:
            "分类与收支类型不一致"
        case .invalidDateRange:
            "开始日期不能晚于结束日期"
        case .transactionNotFound:
            "该账单已不存在"
        case .persistenceFailure:
            "数据保存失败，请重试"
        case .corruptData:
            "本地数据无法读取"
        }
    }
}
