import SwiftData
import XCTest
@testable import JiZhang

@MainActor
final class EntryViewModelTests: XCTestCase {
    func testTypingDisplaysInputOneStepAtATime() throws {
        let viewModel = try makeViewModel()

        XCTAssertEqual(viewModel.displayAmount, "0.00")

        viewModel.appendDigit("1")
        XCTAssertEqual(viewModel.displayAmount, "1")

        viewModel.appendDigit("2")
        XCTAssertEqual(viewModel.displayAmount, "12")

        viewModel.appendDecimalPoint()
        XCTAssertEqual(viewModel.displayAmount, "12.")

        viewModel.appendDigit("3")
        XCTAssertEqual(viewModel.displayAmount, "12.3")

        viewModel.appendDigit("4")
        XCTAssertEqual(viewModel.displayAmount, "12.34")
    }

    func testDeletingShowsEachIntermediateAmount() throws {
        let viewModel = try makeViewModel()

        viewModel.appendDigit("1")
        viewModel.appendDigit("2")
        viewModel.appendDecimalPoint()
        viewModel.appendDigit("3")
        viewModel.appendDigit("4")

        viewModel.deleteLastCharacter()
        XCTAssertEqual(viewModel.displayAmount, "12.3")

        viewModel.deleteLastCharacter()
        XCTAssertEqual(viewModel.displayAmount, "12.")

        viewModel.deleteLastCharacter()
        XCTAssertEqual(viewModel.displayAmount, "12")

        viewModel.deleteLastCharacter()
        XCTAssertEqual(viewModel.displayAmount, "1")

        viewModel.deleteLastCharacter()
        XCTAssertEqual(viewModel.displayAmount, "0")
    }

    func testClearSetsDisplayToZero() throws {
        let viewModel = try makeViewModel()
        viewModel.appendDigit("9")

        viewModel.clearAmount()

        XCTAssertEqual(viewModel.displayAmount, "0")
        XCTAssertNil(viewModel.amountMinorUnits)
    }

    private func makeViewModel() throws -> EntryViewModel {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = ModelContext(container)
        _ = try AppBootstrapService(context: context).prepare()
        let environment = AppEnvironment(modelContainer: container)
        return EntryViewModel(environment: environment)
    }
}
