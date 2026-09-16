import Foundation

enum MoneyAmount {
    static let maximumMinorUnits: Int64 = 9_999_999_999

    static func parse(_ input: String) -> Int64? {
        guard let minorUnits = parseNonNegative(input), minorUnits > 0 else {
            return nil
        }

        return minorUnits
    }

    static func evaluateExpression(_ expression: String) -> Int64? {
        let trimmed = expression.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmed.isEmpty,
              let first = trimmed.first,
              first != "+",
              first != "-",
              let last = trimmed.last,
              last != "+",
              last != "-"
        else {
            return nil
        }

        var total: Int64 = 0
        var sign: Int64 = 1
        var current = ""

        for character in trimmed {
            if character == "+" || character == "-" {
                guard let value = parseNonNegative(current) else {
                    return nil
                }

                total += sign * value
                guard abs(total) <= maximumMinorUnits else {
                    return nil
                }

                sign = character == "+" ? 1 : -1
                current = ""
            } else {
                current.append(character)
            }
        }

        guard let value = parseNonNegative(current) else {
            return nil
        }

        total += sign * value
        guard total > 0, total <= maximumMinorUnits else {
            return nil
        }

        return total
    }

    private static func parseNonNegative(_ input: String) -> Int64? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let parts = trimmed.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2 else {
            return nil
        }

        let wholeText = parts[0].isEmpty ? "0" : String(parts[0])
        let fractionText = parts.count == 2 ? String(parts[1]) : ""

        guard wholeText.allSatisfy(\.isNumber),
              fractionText.allSatisfy(\.isNumber),
              fractionText.count <= 2,
              let whole = Int64(wholeText)
        else {
            return nil
        }

        let fraction: Int64
        switch fractionText.count {
        case 0:
            fraction = 0
        case 1:
            fraction = (Int64(fractionText) ?? 0) * 10
        case 2:
            fraction = Int64(fractionText) ?? 0
        default:
            return nil
        }

        guard whole <= maximumMinorUnits / 100 else {
            return nil
        }

        let minorUnits = whole * 100 + fraction
        guard minorUnits <= maximumMinorUnits else {
            return nil
        }

        return minorUnits
    }

    static func decimalValue(fromMinorUnits minorUnits: Int64) -> Decimal {
        Decimal(minorUnits) / 100
    }

    static func display(minorUnits: Int64) -> String {
        let sign = minorUnits < 0 ? "-" : ""
        let absoluteValue = abs(minorUnits)
        let whole = absoluteValue / 100
        let fraction = absoluteValue % 100
        return "\(sign)\(whole).\(String(format: "%02d", fraction))"
    }

    static func editText(minorUnits: Int64) -> String {
        let whole = minorUnits / 100
        let fraction = minorUnits % 100

        guard fraction != 0 else {
            return String(whole)
        }

        return "\(whole).\(String(format: "%02d", fraction))"
    }

    static func compactText(minorUnits: Int64) -> String {
        display(minorUnits: minorUnits)
    }

    static func signedDisplay(minorUnits: Int64, kind: TransactionKind) -> String {
        guard minorUnits != 0 else {
            return display(minorUnits: 0)
        }

        return kind.signedPrefix + display(minorUnits: minorUnits)
    }
}
