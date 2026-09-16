import XCTest
@testable import JiZhang

final class MoneyAmountTests: XCTestCase {
    func testParsesStandardAmount() {
        XCTAssertEqual(MoneyAmount.parse("12.34"), 1_234)
    }

    func testParsesMinimumAmount() {
        XCTAssertEqual(MoneyAmount.parse("0.01"), 1)
    }

    func testParsesTrailingDecimalPoint() {
        XCTAssertEqual(MoneyAmount.parse("12."), 1_200)
    }

    func testRejectsMoreThanTwoFractionDigits() {
        XCTAssertNil(MoneyAmount.parse("1.234"))
    }

    func testRejectsNegativeAmount() {
        XCTAssertNil(MoneyAmount.parse("-1"))
    }

    func testRejectsZeroAmount() {
        XCTAssertNil(MoneyAmount.parse("0"))
    }

    func testRejectsThousandsSeparator() {
        XCTAssertNil(MoneyAmount.parse("99,999,999.99"))
    }

    func testParsesMaximumAmount() {
        XCTAssertEqual(MoneyAmount.parse("99999999.99"), 9_999_999_999)
    }

    func testEditTextPreservesCents() {
        XCTAssertEqual(MoneyAmount.editText(minorUnits: 1_234), "12.34")
        XCTAssertEqual(MoneyAmount.editText(minorUnits: 1_200), "12")
    }

    func testDisplayUsesTwoDecimalsWithoutCurrencySymbol() {
        XCTAssertEqual(MoneyAmount.display(minorUnits: 1_200), "12.00")
        XCTAssertEqual(MoneyAmount.display(minorUnits: 1_234), "12.34")
    }

    func testDisplayKeepsNegativeBalanceSign() {
        XCTAssertEqual(MoneyAmount.display(minorUnits: -98), "-0.98")
    }

    func testEvaluatesAddAndSubtractExpression() {
        XCTAssertEqual(
            MoneyAmount.evaluateExpression("10+5-3"),
            1_200
        )
    }

    func testEvaluatesDecimalExpression() {
        XCTAssertEqual(
            MoneyAmount.evaluateExpression("1.25+2.5"),
            375
        )
    }

    func testRejectsIncompleteExpression() {
        XCTAssertNil(MoneyAmount.evaluateExpression("10+"))
    }
}
