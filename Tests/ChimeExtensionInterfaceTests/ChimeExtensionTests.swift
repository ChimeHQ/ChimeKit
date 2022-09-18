import XCTest
@testable import ChimeExtensionInterface

@available(macOS 13.0, *)
final class ExampleNonUIExtension: ChimeExtension {
	func acceptHostConnection(_ host: HostProtocol) throws {
	}
}

final class MockHost: HostProtocol {
    func textContent(for documentId: DocumentIdentity, in range: ChimeExtensionInterface.TextRange) async throws -> CombinedTextContent {
        let posA = LineRelativeTextPosition(line: 0, offset: 0)
        let posB = LineRelativeTextPosition(line: 0, offset: 0)
        let relativeRange = posA..<posB
        let combinedRange = CombinedTextRange(version: 1,
                                              range: NSRange(location: 0, length: 0),
                                              lineRelativeRange: relativeRange,
                                              limit: 0)
        return CombinedTextContent(string: "", range: combinedRange)
    }

    func textContent(for documentId: DocumentIdentity) async throws -> (String, Int) {
        return ("", 1)
    }

    func textBounds(for documentId: DocumentIdentity, in ranges: [ChimeExtensionInterface.TextRange], version: Int) async throws -> [NSRect] {
        return []
    }

    func publishDiagnostics(_ diagnostics: [Diagnostic], for documentURL: URL, version: Int?) {
    }

    func invalidateTokens(for documentId: DocumentIdentity, in target: TextTarget) {
    }

    func documentServiceConfigurationChanged(for documentId: DocumentIdentity, to configuration: ServiceConfiguration) {
    }
}

@available(macOS 13.0, *)
final class ChimeExtensionTests: XCTestCase {
	func testNonUIExtension() throws {
        let ext = ExampleNonUIExtension()
        let host = MockHost()

        XCTAssertNoThrow(try ext.acceptHostConnection(host))
	}
}
