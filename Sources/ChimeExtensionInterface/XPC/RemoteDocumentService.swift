import Foundation

import Queue

@MainActor
struct RemoteDocumentService {
	private let queuedService: RemoteExtension.Service
    let context: DocumentContext
	private let xpcContext: XPCDocumentContext

	public private(set) var completionTriggers = Set<String>()

	init(queuedService: RemoteExtension.Service, context: DocumentContext) {
        self.queuedService = queuedService
        self.context = context
		self.xpcContext = try! JSONEncoder().encode(context)
    }
}

extension RemoteDocumentService: DocumentService {
    public func willApplyChange(_ change: CombinedTextChange) throws {
        let xpcChange = try JSONEncoder().encode(change)

		queuedService.addOperation(barrier: true) { service in
			service.willApplyChange(with: xpcContext, xpcChange: xpcChange)
		}
    }

    public func didApplyChange(_ change: CombinedTextChange) throws {
        let xpcChange = try JSONEncoder().encode(change)

		queuedService.addOperation(barrier: true) { service in
			service.didApplyChange(with: xpcContext, xpcChange: xpcChange)
		}
    }

    public func willSave() throws {
		queuedService.addOperation(barrier: true) { service in
			service.willSave(with: xpcContext, completionHandler: {
				if let error = $0 {
					print("willSave failure: \(error)")
				}
			})
		}
    }

    public func didSave() throws {
		queuedService.addOperation(barrier: true) { service in
			service.didSave(with: xpcContext)
		}
    }

    public var completionService: (some CompletionService)? {
        get throws { return self }
    }

    public var formattingService: (some FormattingService)? {
        get throws { return self }
    }

    public var semanticDetailsService: (some SemanticDetailsService)? {
        get throws { return self }
    }

    public var defintionService: (some DefinitionService)? {
        get throws { return self }
    }

    public var tokenService: (some TokenService)? {
        get throws { return self }
    }

    public var symbolService: (some SymbolQueryService)? {
        get throws { return self }
    }
}

extension RemoteDocumentService: CompletionService {
    public func completions(at position: CombinedTextPosition, trigger: CompletionTrigger) async throws -> [Completion] {
        let xpcPosition = try JSONEncoder().encode(position)
        let xpcTrigger = try JSONEncoder().encode(trigger)

		return try await queuedService.addDecodingOperation { service, handler in
			service.completions(for: xpcContext, at: xpcPosition, xpcTrigger: xpcTrigger, completionHandler: handler)
		}
    }
}

extension RemoteDocumentService: FormattingService {
    public func formatting(for ranges: [CombinedTextRange]) async throws -> [TextChange] {
		let xpcRanges = try JSONEncoder().encode(ranges)

		return try await queuedService.addDecodingOperation { service, handler in
			service.formatting(for: xpcContext, for: xpcRanges, completionHandler: handler)
		}
    }

    public func organizeImports() async throws -> [TextChange] {
		return try await queuedService.addDecodingOperation { service, handler in
			service.organizeImports(for: xpcContext, completionHandler: handler)
		}
    }
}

extension RemoteDocumentService: SemanticDetailsService {
    public func semanticDetails(at position: CombinedTextPosition) async throws -> SemanticDetails? {
		let xpcPosition = try JSONEncoder().encode(position)

		return try await queuedService.addDecodingOperation { service, handler in
			service.semanticDetails(for: xpcContext, at: xpcPosition, completionHandler: handler)
		}
    }
}

extension RemoteDocumentService: DefinitionService {
    public func definitions(at position: CombinedTextPosition) async throws -> [DefinitionLocation] {
        let xpcPosition = try JSONEncoder().encode(position)

		return try await queuedService.addDecodingOperation { service, handler in
			service.findDefinition(for: xpcContext, at: xpcPosition, completionHandler: handler)
		}
    }
}

extension RemoteDocumentService: TokenService {
    public func tokens(in range: CombinedTextRange) async throws -> [Token] {
        let xpcRange = try JSONEncoder().encode(range)

		return try await queuedService.addDecodingOperation { service, handler in
			service.tokens(for: xpcContext, in: xpcRange, completionHandler: handler)
		}
    }
}

extension RemoteDocumentService: SymbolQueryService {
    public func symbols(matching query: String) async throws -> [Symbol] {
        return []
    }
}
