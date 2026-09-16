import XCTest

final class JiZhangUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunchesToBillsTab() {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["账单"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["我的"].exists)
        XCTAssertTrue(app.tabBars.buttons["记一笔"].exists)
    }

    func testCreatesExpenseFromEntryForm() {
        let app = makeApp()
        app.launch()

        createExpense(in: app)

        XCTAssertTrue(app.staticTexts["· 三餐"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["-12.34"].exists)

        app.buttons["账本"].tap()
        XCTAssertTrue(
            app.staticTexts["分类占比"].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.staticTexts["三餐"].exists)

        app.buttons["三餐"].tap()
        XCTAssertTrue(
            app.navigationBars["三餐"].waitForExistence(timeout: 3)
        )
        XCTAssertTrue(app.staticTexts["-12.34"].exists)
    }

    func testEditsAndDeletesExpense() {
        let app = makeApp()
        app.launch()

        createExpense(in: app)
        XCTAssertTrue(app.staticTexts["· 三餐"].waitForExistence(timeout: 5))

        app.staticTexts["· 三餐"].tap()
        XCTAssertTrue(
            app.navigationBars["账单详情"].waitForExistence(timeout: 3)
        )

        app.buttons["修改"].tap()
        XCTAssertTrue(app.buttons["支出"].waitForExistence(timeout: 3))

        for _ in 0..<5 {
            app.buttons["删除"].tap()
        }
        app.buttons["2"].tap()
        app.buttons["0"].tap()
        app.buttons["."].tap()
        app.buttons["0"].tap()
        app.buttons["0"].tap()
        app.buttons["保存"].tap()

        XCTAssertTrue(
            app.staticTexts["-20.00"].waitForExistence(timeout: 5)
        )

        app.buttons["删除账单"].tap()
        app.alerts.buttons["删除"].tap()

        XCTAssertTrue(
            app.staticTexts["暂无账单"].waitForExistence(timeout: 5)
        )
    }

    func testClosesDirtyEntryWithoutConfirmation() {
        let app = makeApp()
        app.launch()

        app.buttons["记一笔"].tap()
        app.buttons["1"].tap()
        app.buttons["关闭"].tap()

        XCTAssertTrue(app.buttons["记一笔"].waitForExistence(timeout: 2))
    }

    func testSwitchesLedgerPeriodToAll() {
        let app = makeApp()
        app.launch()

        app.buttons["账本周期"].tap()
        app.buttons["全部"].tap()
        app.buttons["确认"].tap()

        XCTAssertEqual(
            app.buttons["账本周期"].value as? String,
            "全部"
        )
    }

    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        return app
    }

    private func createExpense(in app: XCUIApplication) {
        app.buttons["记一笔"].tap()
        XCTAssertTrue(app.buttons["支出"].waitForExistence(timeout: 3))

        app.buttons["1"].tap()
        app.buttons["2"].tap()
        app.buttons["."].tap()
        app.buttons["3"].tap()
        app.buttons["4"].tap()
        app.buttons["三餐"].tap()
        app.buttons["保存"].tap()
    }
}
