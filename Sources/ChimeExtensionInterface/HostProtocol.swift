import Foundation

/// Application-level functionality provided by Chime to extensions.
///
/// This protocol provides access to functionality of the Chime application.
public protocol HostProtocol {
    // this exists to avoid having to calculate a TextRange param
    // and especially the CombinedTextContent return value which can be
    // very expensive for the full document
    func textContent(for documentId: DocumentIdentity) async throws -> (String, Int)

    func textContent(for documentId: DocumentIdentity, in range: TextRange) async throws -> CombinedTextContent

    func textBounds(for documentId: DocumentIdentity, in ranges: [TextRange], version: Int) async throws -> [NSRect]

    func publishDiagnostics(_ diagnostics: [Diagnostic], for documentURL: URL, version: Int?)

    func invalidateTokens(for documentId: DocumentIdentity, in target: TextTarget)

	/// Inform the host that the sending extension's configuration has changed.
	func extensionConfigurationChanged(to configuration: ExtensionConfiguration)
    func documentServiceConfigurationChanged(for documentId: DocumentIdentity, to configuration: ServiceConfiguration)
}

public extension HostProtocol {
    func textContent(for documentId: DocumentIdentity, in range: CombinedTextRange) async throws -> CombinedTextContent {
        return try await textContent(for: documentId, in: .range(range.range))
    }
}
