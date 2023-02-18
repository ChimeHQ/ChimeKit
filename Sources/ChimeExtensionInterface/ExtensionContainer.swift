import Foundation

public final class StandaloneExtension<Extension: ExtensionProtocol> {
	public typealias ExtensionProvider = (HostProtocol) throws -> Extension

	private let extensionProvider: ExtensionProvider
	private var wrappedExtension: Extension?

	public init(extensionProvider: @escaping ExtensionProvider) {
		self.extensionProvider = extensionProvider
	}

	public func acceptHostConnection(_ host: HostProtocol) throws {
		self.wrappedExtension = try extensionProvider(host)
	}
}

extension StandaloneExtension: ExtensionProtocol {
	public var configuration: ExtensionConfiguration {
		get async throws {
			guard let wrappedExtension else { throw ChimeExtensionError.noHostConnection }

			return try await wrappedExtension.configuration
		}
	}

	public func didOpenProject(with context: ProjectContext) async throws {
		guard let wrappedExtension else { throw ChimeExtensionError.noHostConnection }

		try await wrappedExtension.didOpenProject(with: context)
	}

	public func willCloseProject(with context: ProjectContext) async throws {
		guard let wrappedExtension else { throw ChimeExtensionError.noHostConnection }

		try await wrappedExtension.willCloseProject(with: context)
	}

	public func didOpenDocument(with context: DocumentContext) async throws -> URL? {
		guard let wrappedExtension else { throw ChimeExtensionError.noHostConnection }

		return try await wrappedExtension.didOpenDocument(with: context)
	}

	public func didChangeDocumentContext(from oldContext: DocumentContext, to newContext: DocumentContext) async throws {
		guard let wrappedExtension else { throw ChimeExtensionError.noHostConnection }

		try await wrappedExtension.didChangeDocumentContext(from: oldContext, to: newContext)
	}

	public func willCloseDocument(with context: DocumentContext) async throws {
		guard let wrappedExtension else { throw ChimeExtensionError.noHostConnection }

		try await wrappedExtension.willCloseDocument(with: context)
	}

	public func documentService(for context: DocumentContext) async throws -> DocumentService? {
		guard let wrappedExtension else { throw ChimeExtensionError.noHostConnection }

		return try await wrappedExtension.documentService(for: context)
	}

	public func symbolService(for context: ProjectContext) async throws -> SymbolQueryService? {
		guard let wrappedExtension else { throw ChimeExtensionError.noHostConnection }

		return try await wrappedExtension.symbolService(for: context)
	}
}
