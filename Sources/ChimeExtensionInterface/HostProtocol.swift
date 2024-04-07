import Foundation

#if canImport(ProcessEnv)
import ProcessEnv
#endif

/// Application-level functionality provided by Chime to extensions.
///
/// This protocol provides access to functionality of the Chime application.
public protocol HostProtocol {
    // this exists to avoid having to calculate a TextRange param
    // and especially the CombinedTextContent return value which can be
    // very expensive for the full document
	@MainActor
    func textContent(for documentId: DocumentIdentity) async throws -> (String, Int)

	@MainActor
    func textContent(for documentId: DocumentIdentity, in range: TextRange) async throws -> CombinedTextContent

	@MainActor
    func textBounds(for documentId: DocumentIdentity, in ranges: [TextRange], version: Int) async throws -> [CGRect]

	@MainActor
    func publishDiagnostics(_ diagnostics: [Diagnostic], for documentURL: URL, version: Int?)

	@MainActor
    func invalidateTokens(for documentId: DocumentIdentity, in target: TextTarget)

	/// Inform the host that configuration for the extension's services have changed.
	@MainActor
	func serviceConfigurationChanged(for documentId: DocumentIdentity, to configuration: ServiceConfiguration)

	@MainActor
	func launchProcess(with parameters: Process.ExecutionParameters, inUserShell: Bool) async throws -> LaunchedProcess

	@MainActor
	func captureUserEnvironment() async throws -> [String: String]
}

extension HostProtocol {
	@MainActor
	public func launchProcess(with parameters: Process.ExecutionParameters) async throws -> LaunchedProcess {
		try await launchProcess(with: parameters, inUserShell: false)
	}
}

public extension HostProtocol {
	@MainActor
    func textContent(for documentId: DocumentIdentity, in range: CombinedTextRange) async throws -> CombinedTextContent {
        return try await textContent(for: documentId, in: .range(range.range))
    }
}
