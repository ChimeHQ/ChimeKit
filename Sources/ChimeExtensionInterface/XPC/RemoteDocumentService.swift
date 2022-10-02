import Foundation

import ConcurrencyPlus

actor RemoteDocumentService {
	private let connection: NSXPCConnection
    private(set) var context: DocumentContext

    private lazy var xpcContext: XPCDocumentContext = {
        try! JSONEncoder().encode(context)
    }()

    init(connection: NSXPCConnection, context: DocumentContext) {
        self.connection = connection
        self.context = context
    }

	private func withContinuation<T>(function: String = #function, _ body: (ExtensionXPCProtocol, CheckedContinuation<T, Error>) -> Void) async throws -> T {
		return try await connection.withContinuation(body)
	}

	private func withService(function: String = #function, _ body: (ExtensionXPCProtocol) -> Void) async throws {
		try await connection.withService(body)
	}
}

extension RemoteDocumentService: DocumentService {
    public func willApplyChange(_ change: CombinedTextChange) async throws {
        let xpcChange = try JSONEncoder().encode(change)

		try await withService({ service in
			service.willApplyChange(with: xpcContext, xpcChange: xpcChange)
		})
    }

    public func didApplyChange(_ change: CombinedTextChange) async throws {
        let xpcChange = try JSONEncoder().encode(change)

		try await withService({ service in
			service.didApplyChange(with: xpcContext, xpcChange: xpcChange)
		})
    }

    public func willSave() async throws {
		try await withContinuation({ service, continuation in
			service.willSave(with: xpcContext, completionHandler: continuation.resumingHandler)
		})
    }

    public func didSave() async throws {
		try await withContinuation({ service, continuation in
			service.didSave(with: xpcContext, completionHandler: continuation.resumingHandler)
        })
    }

    public var completionService: CompletionService? {
        get async throws { return self }
    }

    public var formattingService: FormattingService? {
        get async throws { return self }
    }

    public var semanticDetailsService: SemanticDetailsService? {
        get async throws { return self }
    }

    public var defintionService: DefinitionService? {
        get async throws { return self }
    }

    public var tokenService: TokenService? {
        get async throws { return self }
    }

    public var symbolService: SymbolQueryService? {
        get async throws { return self }
    }
}

extension RemoteDocumentService: CompletionService {
    public func completions(at position: CombinedTextPosition, trigger: CompletionTrigger) async throws -> [Completion] {
        let xpcPosition = try JSONEncoder().encode(position)
        let xpcTrigger = try JSONEncoder().encode(trigger)

		return try await withContinuation({ service, continuation in
			service.completions(for: xpcContext, at: xpcPosition, xpcTrigger: xpcTrigger, completionHandler: continuation.resumingHandler)
        })
    }
}

extension RemoteDocumentService: FormattingService {
    public func formatting(for ranges: [CombinedTextRange]) async throws -> [TextChange] {
		let xpcRanges = try JSONEncoder().encode(ranges)

		return try await withContinuation({ service, continuation in
			service.formatting(for: xpcContext, for: xpcRanges, completionHandler: continuation.resumingHandler)
		})
    }

    public func organizeImports() async throws -> [TextChange] {
		return try await withContinuation({ service, continuation in
			service.organizeImports(for: xpcContext, completionHandler: continuation.resumingHandler)
		})
    }
}

extension RemoteDocumentService: SemanticDetailsService {
    public func semanticDetails(at position: CombinedTextPosition) async throws -> SemanticDetails? {
		let xpcPosition = try JSONEncoder().encode(position)

		return try await withContinuation({ service, continuation in
			service.semanticDetails(for: xpcContext, at: xpcPosition, completionHandler: continuation.resumingHandler)
		})
    }
}

extension RemoteDocumentService: DefinitionService {
    public func definitions(at position: CombinedTextPosition) async throws -> [DefinitionLocation] {
        let xpcPosition = try JSONEncoder().encode(position)

		return try await withContinuation({ service, continuation in
			service.findDefinition(for: xpcContext, at: xpcPosition, completionHandler: continuation.resumingHandler)
        })
    }
}

extension RemoteDocumentService: TokenService {
    public func tokens(in range: CombinedTextRange) async throws -> [Token] {
        let xpcRange = try JSONEncoder().encode(range)

		return try await withContinuation({ service, continuation in
			service.tokens(for: xpcContext, in: xpcRange, completionHandler: continuation.resumingHandler)
        })
    }
}

extension RemoteDocumentService: SymbolQueryService {
    public func symbols(matching query: String) async throws -> [Symbol] {
        return []
    }
}
