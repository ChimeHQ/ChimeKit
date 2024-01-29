import Foundation

public struct TokenServicePlaceholder: TokenService {
	public init() {}

	public func tokens(in range: CombinedTextRange) async throws -> [Token] {
		throw ChimeExtensionError.unsupported
	}
}

public struct CompletionServicePlaceholder: CompletionService {
	public init() {}

	public func completions(at position: CombinedTextPosition, trigger: CompletionTrigger) async throws -> [Completion] {
		throw ChimeExtensionError.unsupported
	}
}

public struct FormattingServicePlaceholder: FormattingService {
	public init() {}

	public func formatting(for ranges: [CombinedTextRange]) async throws -> [TextChange] {
		throw ChimeExtensionError.unsupported
	}
	
	public func organizeImports() async throws -> [TextChange] {
		throw ChimeExtensionError.unsupported
	}
}

public struct SemanticDetailsServicePlaceholder: SemanticDetailsService {
	public init() {}

	public func semanticDetails(at position: CombinedTextPosition) async throws -> SemanticDetails? {
		throw ChimeExtensionError.unsupported
	}
}

public struct DefinitionServicePlaceholder: DefinitionService {
	public init() {}

	public func definitions(at position: CombinedTextPosition) async throws -> [DefinitionLocation] {
		throw ChimeExtensionError.unsupported
	}
}

public struct SymbolQueryServicePlaceholder: SymbolQueryService {
	public init() {}

	public func symbols(matching query: String) async throws -> [Symbol] {
		throw ChimeExtensionError.unsupported
	}
}

public struct DocumentServicePlaceholder: DocumentService {
	public init() {}

	public func willApplyChange(_ change: CombinedTextChange) throws {
	}
	
	public func didApplyChange(_ change: CombinedTextChange) throws {
	}
	
	public func willSave() throws {
	}
	
	public func didSave() throws {
	}
	
	public var completionService: (some CompletionService)? { CompletionServicePlaceholder() }

	public var formattingService: (some FormattingService)? { FormattingServicePlaceholder() }

	public var semanticDetailsService: (some SemanticDetailsService)? { SemanticDetailsServicePlaceholder() }

	public var defintionService: (some DefinitionService)? { DefinitionServicePlaceholder() }

	public var tokenService: (some TokenService)? { TokenServicePlaceholder() }

	public var symbolService: (some SymbolQueryService)? { SymbolQueryServicePlaceholder() }
}

public struct ApplicationServicePlaceholder: ApplicationService {
	public init() {}

	public func didOpenProject(with context: ProjectContext) throws {
	}
	
	public func willCloseProject(with context: ProjectContext) throws {
	}
	
	public func didOpenDocument(with context: DocumentContext) throws {
	}
	
	public func didChangeDocumentContext(from oldContext: DocumentContext, to newContext: DocumentContext) throws {
	}
	
	public func willCloseDocument(with context: DocumentContext) throws {
	}
	
	public func documentService(for context: DocumentContext) throws -> (some DocumentService)? {
		DocumentServicePlaceholder()
	}
	
	public func symbolService(for context: ProjectContext) throws -> (some SymbolQueryService)? {
		SymbolQueryServicePlaceholder()
	}
}
