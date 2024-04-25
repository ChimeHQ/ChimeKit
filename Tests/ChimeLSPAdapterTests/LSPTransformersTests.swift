import XCTest

import LanguageServerProtocol
@testable import ChimeLSPAdapter
import ChimeExtensionInterface

final class LSPTransformersTests: XCTestCase {
    func testCompletionRangeFallback() throws {
        let transformer = LSPTransformers.standardCompletionTransformer

		let lspCompletion = CompletionItem(label: "", insertText: "abc")

        let fallback = ChimeExtensionInterface.TextRange.range(NSRange(location: 10, length: 10))
        let completion = try XCTUnwrap(transformer(fallback, lspCompletion))

        XCTAssertEqual(completion.range, fallback)
    }

    func testCompletionWithNoText() throws {
        let transformer = LSPTransformers.standardCompletionTransformer

        let lspCompletion = CompletionItem(label: "")

        let fallback = ChimeExtensionInterface.TextRange.range(NSRange(location: 10, length: 10))

        XCTAssertNil(transformer(fallback, lspCompletion))
    }

	func testMergeAdditionalEditsBeforeRange() throws {
		let transformer = LSPTransformers.standardCompletionTransformer

		let editRange = LSPRange(startPair: (6, 7), endPair: (6, 10))
		let additionalEditRange = LSPRange(startPair: (6, 1), endPair: (6, 7))
		let lspCompletion = CompletionItem(
			label: "",
			insertText: nil,
			textEdit: .optionA(TextEdit(range: editRange, newText: "stuff = append(stuff, $0)")),
			additionalTextEdits: [
				TextEdit(range: additionalEditRange, newText: "")
			]
		)

		let fallback = ChimeExtensionInterface.TextRange.range(NSRange(0..<0))
		let completion = try XCTUnwrap(transformer(fallback, lspCompletion))

		let mergedRange = ChimeExtensionInterface.TextRange.lineRelativeRange(
			LineRelativeTextPosition(line: 6, offset: 1)..<LineRelativeTextPosition(line: 6, offset: 10)
		)

		XCTAssertEqual(completion.range, mergedRange)
	}
}
