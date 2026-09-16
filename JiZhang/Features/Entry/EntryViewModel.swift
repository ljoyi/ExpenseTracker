import Foundation
import Observation

@MainActor
@Observable
final class EntryViewModel {
    var kind: TransactionKind = .expense
    var amountText = ""
    var selectedCategoryID: UUID?
    var occurredAt = Date()
    var categories: [Category] = []
    var isSaving = false
    var errorMessage: String?
    private var hasEditedAmount = false

    private let environment: AppEnvironment
    private let transactionID: UUID?

    init(
        environment: AppEnvironment,
        transaction: TransactionSnapshot? = nil
    ) {
        self.environment = environment
        self.transactionID = transaction?.id

        if let transaction {
            self.hasEditedAmount = true
            self.kind = transaction.kind
            self.amountText = MoneyAmount.display(
                minorUnits: transaction.amountMinorUnits
            )
            self.selectedCategoryID = transaction.categoryID
            self.occurredAt = transaction.occurredAt
        }
    }

    var isEditing: Bool {
        transactionID != nil
    }

    var amountMinorUnits: Int64? {
        MoneyAmount.evaluateExpression(amountText)
    }

    var displayAmount: String {
        if amountText.isEmpty {
            return hasEditedAmount ? "0" : "0.00"
        }

        return amountText
    }

    var canSave: Bool {
        amountMinorUnits != nil
            && selectedCategoryID != nil
            && !isSaving
    }

    func loadCategories() {
        do {
            categories = try environment.categoryService.list(kind: kind)
            if selectedCategoryID == nil {
                selectedCategoryID = categories.first?.id
            }
        } catch {
            categories = []
            errorMessage = message(for: error)
        }
    }

    func selectKind(_ newKind: TransactionKind) {
        guard kind != newKind else {
            return
        }

        kind = newKind
        selectedCategoryID = nil
        loadCategories()
    }

    func selectCategory(_ categoryID: UUID) {
        selectedCategoryID = categoryID
    }

    func appendDigit(_ digit: String) {
        hasEditedAmount = true
        var base = amountText
        let currentOperand = String(
            amountText.split(
                whereSeparator: { $0 == "+" || $0 == "-" }
            ).last ?? ""
        )

        if currentOperand == "0" {
            base.removeLast()
        }

        let candidate = base + digit
        guard isPotentiallyValidAmount(candidate) else {
            return
        }

        amountText = candidate
    }

    func appendDecimalPoint() {
        hasEditedAmount = true
        let currentOperand = String(
            amountText.split(
                whereSeparator: { $0 == "+" || $0 == "-" }
            ).last ?? ""
        )

        guard !currentOperand.contains(".") else {
            return
        }

        if currentOperand.isEmpty {
            amountText += "0."
        } else {
            amountText += "."
        }
    }

    func appendOperator(_ operation: Character) {
        guard !amountText.isEmpty,
              let last = amountText.last,
              last != "+",
              last != "-",
              last != "."
        else {
            return
        }

        hasEditedAmount = true
        amountText.append(operation)
    }

    func clearAmount() {
        hasEditedAmount = true
        amountText = ""
    }

    func deleteLastCharacter() {
        guard !amountText.isEmpty else {
            return
        }

        hasEditedAmount = true
        amountText.removeLast()
    }

    func save() -> Bool {
        guard let amountMinorUnits else {
            errorMessage = ServiceError.invalidAmount.errorDescription
            return false
        }

        guard let selectedCategoryID else {
            errorMessage = ServiceError.categoryRequired.errorDescription
            return false
        }

        isSaving = true
        defer {
            isSaving = false
        }

        do {
            if let transactionID {
                _ = try environment.transactionService.update(
                    transactionID: transactionID,
                    patch: TransactionPatch(
                        kind: kind,
                        amountMinorUnits: amountMinorUnits,
                        categoryID: selectedCategoryID,
                        occurredAt: occurredAt
                    )
                )
            } else {
                _ = try environment.transactionService.create(
                    TransactionDraft(
                        kind: kind,
                        amountMinorUnits: amountMinorUnits,
                        categoryID: selectedCategoryID,
                        occurredAt: occurredAt
                    )
                )
            }
            return true
        } catch {
            errorMessage = message(for: error)
            return false
        }
    }

    private func isPotentiallyValidAmount(_ text: String) -> Bool {
        guard !text.isEmpty,
              let first = text.first,
              first != "+",
              first != "-"
        else {
            return text.isEmpty
        }

        let tokens = text.split(
            omittingEmptySubsequences: false,
            whereSeparator: { $0 == "+" || $0 == "-" }
        )

        if let last = text.last, last == "+" || last == "-" {
            let completedTokens = tokens.dropLast()
            guard !completedTokens.isEmpty else {
                return false
            }
        }

        for token in tokens where !token.isEmpty {
            guard isValidOperand(String(token)) else {
                return false
            }
        }

        return true
    }

    private func isValidOperand(_ operand: String) -> Bool {
        let parts = operand.split(
            separator: ".",
            omittingEmptySubsequences: false
        )
        guard parts.count <= 2 else {
            return false
        }

        guard parts[0].allSatisfy(\.isNumber), parts[0].count <= 8 else {
            return false
        }

        if parts.count == 2 {
            return parts[1].allSatisfy(\.isNumber) && parts[1].count <= 2
        }

        return true
    }

    private func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? "操作失败，请重试"
    }
}
