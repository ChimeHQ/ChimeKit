import Foundation

@_implementationOnly import ConcurrencyPlus
//import ExtensionInterface

public actor DocumentServiceXPCBridge {
    private let remoteObject: ExtensionXPCProtocol
    private(set) var context: DocumentContext

    private lazy var xpcContext: XPCDocumentContext = {
        try! JSONEncoder().encode(context)
    }()

    init(remoteObject: ExtensionXPCProtocol, context: DocumentContext) {
        self.remoteObject = remoteObject
        self.context = context
    }
}

extension DocumentServiceXPCBridge: DocumentService {
    public func willApplyChange(_ change: CombinedTextChange) async throws {
        let xpcChange = try JSONEncoder().encode(change)

        remoteObject.willApplyChange(with: xpcContext, xpcChange: xpcChange)
    }

    public func didApplyChange(_ change: CombinedTextChange) async throws {
        let xpcChange = try JSONEncoder().encode(change)

        remoteObject.didApplyChange(with: xpcContext, xpcChange: xpcChange)
    }

    public func willSave() async throws {
        try await withCancellingContinuation({ continuation in
            remoteObject.willSave(with: xpcContext) { error in
                continuation.resume(with: error)
            }
        })
    }

    public func didSave() async throws {
        try await withCancellingContinuation({ continuation in
            remoteObject.didSave(with: xpcContext) { error in
                continuation.resume(with: error)
            }
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

extension DocumentServiceXPCBridge: CompletionService {
    public func completions(at position: CombinedTextPosition, trigger: CompletionTrigger) async throws -> [Completion] {
        let xpcPosition = CodingCombinedTextPosition(position)
        let xpcTrigger: String?

        switch trigger {
        case .invoked:
            xpcTrigger = nil
        case .character(let string):
            xpcTrigger = string
        }

        return try await withCancellingContinuation({ (continuation: CancellingContinuation<[Completion]>) in
            remoteObject.completions(for: xpcContext, at: xpcPosition, xpcTrigger: xpcTrigger) { data, error in
                continuation.resume(with: data, error: error)
            }
        })
    }
}

extension DocumentServiceXPCBridge: FormattingService {
    public func formatting(for ranges: [CombinedTextRange]) async throws -> [TextChange] {
        throw XPCBridgeError.unsupported
    }

    public func organizeImports() async throws -> [TextChange] {
        throw XPCBridgeError.unsupported
    }
}

extension DocumentServiceXPCBridge: SemanticDetailsService {
    public func semanticDetails(at position: CombinedTextPosition) async throws -> SemanticDetails? {
        throw XPCBridgeError.unsupported
    }
}

extension DocumentServiceXPCBridge: DefinitionService {
    public func definitions(at position: CombinedTextPosition) async throws -> [DefinitionLocation] {
        let xpcPosition = CodingCombinedTextPosition(position)

        return try await withCancellingContinuation({ continuation in
            remoteObject.findDefinition(for: xpcContext, at: xpcPosition) { data, error in
                continuation.resume(with: data, error: error)
            }
        })
    }
}

extension DocumentServiceXPCBridge: TokenService {
    public func tokens(in range: CombinedTextRange) async throws -> [Token] {
        let xpcRange = CodingCombinedTextRange(range)

        return try await withCancellingContinuation({ continuation in
            remoteObject.tokens(for: xpcContext, in: xpcRange) { data, error in
                continuation.resume(with: data, error: error)
            }
        })
    }
}

extension DocumentServiceXPCBridge: SymbolQueryService {
    public func symbols(matching query: String) async throws -> [Symbol] {
        return []
    }
}
