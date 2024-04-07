import XCTest

import ChimeExtensionInterface
#if canImport(ProcessEnv)
import ProcessEnv
#endif

@available(macOS 13.0, *)
final class ExampleNonUIExtension: ChimeExtension {
	func acceptHostConnection(_ host: HostProtocol) throws {
	}

	var configuration: ExtensionConfiguration { ExtensionConfiguration() }
	var applicationService: some ApplicationService { return self }
}

extension ExampleNonUIExtension: ApplicationService {
	func didOpenProject(with context: ProjectContext) throws {
	}
	
	func willCloseProject(with context: ProjectContext) throws {
	}
	
	func didOpenDocument(with context: DocumentContext) throws {
	}
	
	func didChangeDocumentContext(from oldContext: DocumentContext, to newContext: DocumentContext) throws {
	}
	
	func willCloseDocument(with context: DocumentContext) throws {
	}
	
	func documentService(for context: DocumentContext) throws -> (some DocumentService)? {
		DocumentServicePlaceholder?.none
	}
	
	func symbolService(for context: ProjectContext) throws -> (some SymbolQueryService)? {
		SymbolQueryServicePlaceholder?.none
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

    func textBounds(for documentId: DocumentIdentity, in ranges: [ChimeExtensionInterface.TextRange], version: Int) async throws -> [CGRect] {
        return []
    }

    func publishDiagnostics(_ diagnostics: [Diagnostic], for documentURL: URL, version: Int?) {
    }

    func invalidateTokens(for documentId: DocumentIdentity, in target: TextTarget) {
    }

	func serviceConfigurationChanged(for documentId: DocumentIdentity, to configuration: ServiceConfiguration) {
	}

	func launchProcess(with parameters: Process.ExecutionParameters, inUserShell: Bool) async throws -> LaunchedProcess {
		throw ChimeExtensionError.unsupported
	}

	func captureUserEnvironment() async throws -> [String : String] {
		throw ChimeExtensionError.unsupported
	}
}

@available(macOS 13.0, *)
final class ChimeExtensionTests: XCTestCase {

	@MainActor
	func testNonUIExtension() throws {
        let ext = ExampleNonUIExtension()
        let host = MockHost()

        XCTAssertNoThrow(try ext.acceptHostConnection(host))
	}
}
