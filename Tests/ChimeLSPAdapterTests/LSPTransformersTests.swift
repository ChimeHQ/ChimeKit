import XCTest

import LanguageServerProtocol
@testable import ChimeLSPAdapter
import ChimeExtensionInterface

final class LSPTransformersTests: XCTestCase {
    func testCompletionRangeFallback() throws {
        let transformer = LSPTransformers.standardCompletionTransformer

        // this is annoying, but CompletionItem has no public init
        let json = """
{"label":"", "insertText": "abc"}
"""
        let data = try XCTUnwrap(json.data(using: .utf8))

        let lspCompletion = try JSONDecoder().decode(CompletionItem.self, from: data)

        let fallback = ChimeExtensionInterface.TextRange.range(NSRange(location: 10, length: 10))
        let completion = try XCTUnwrap(transformer(fallback, lspCompletion))

        XCTAssertEqual(completion.range, fallback)
    }

    func testCompletionWithNoText() throws {
        let transformer = LSPTransformers.standardCompletionTransformer

        let json = """
{"label":""}
"""
        let data = try XCTUnwrap(json.data(using: .utf8))

        let lspCompletion = try JSONDecoder().decode(CompletionItem.self, from: data)

        let fallback = ChimeExtensionInterface.TextRange.range(NSRange(location: 10, length: 10))

        XCTAssertNil(transformer(fallback, lspCompletion))
    }
}
