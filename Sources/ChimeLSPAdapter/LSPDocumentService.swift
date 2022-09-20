import Combine
import Foundation
import os.log

import ChimeExtensionInterface
import LanguageServerProtocol

enum LSPDocumentServiceError: Error {
    case noURI
}

final class LSPDocumentService {
	typealias ContextFilter = (DocumentContext) async -> Bool

    private let log: OSLog
    private let server: Server
    let context: DocumentContext
	let contextFilter: ContextFilter
    private let host: HostProtocol
    let transformers: LSPTransformers
    var serverCapabilities: ServerCapabilities? {
        didSet {
            handleCapabilitiesChanged()
        }
    }
    private var tokenRepresentation: SemanticTokenRepresentation? {
        didSet {
            if oldValue == nil && tokenRepresentation == nil {
                return
            }

            invalidateTokens(in: .all)
        }
    }
    private let textChangeSubject = PassthroughSubject<Void, Never>()
    private var subscriptions = Set<AnyCancellable>()

    init(server: Server,
		 host: HostProtocol,
		 context: DocumentContext,
		 transformers: LSPTransformers,
		 contextFilter: @escaping ContextFilter) {
        self.server = server
        self.host = host
        self.context = context
        self.transformers = transformers
		self.contextFilter = contextFilter

        self.log = OSLog(subsystem: "com.chimehq.ChimeKit", category: "DocumentLSPConnection")

        textChangeSubject
            .debounce(for: .seconds(0.8), scheduler: DispatchQueue.global())
            .sink { [weak self] in
                self?.invalidateTokens(in: .all)
            }.store(in: &subscriptions)
    }

    var uri: DocumentUri? {
        return context.url?.absoluteString
    }

    private var textDocumentIdentifier: TextDocumentIdentifier {
        get throws {
            guard let uri = uri else {
                throw LSPServiceError.documentURLInvalid(context)
            }

            return TextDocumentIdentifier(uri: uri)
        }
    }

    private var documentSyncKind: TextDocumentSyncKind {
        return serverCapabilities?.textDocumentSync?.effectiveOptions.change ?? .none
    }

    var textDocumentItem: TextDocumentItem {
        get async throws {
            guard
                let uri = uri,
                let languageId = context.languageIdentifier
            else {
                throw LSPDocumentServiceError.noURI
            }

            let pair = try await host.textContent(for: context.id)

            return TextDocumentItem(uri: uri,
                                    languageId: languageId,
                                    version: pair.1,
                                    text: pair.0)
        }
    }

    func openIfNeeded() async throws {
		guard await contextFilter(context) else { return }

        let item = try await textDocumentItem

        let params = DidOpenTextDocumentParams(textDocument: item)

        try await server.didOpenTextDocument(params: params)
    }

    func close() async throws {
		guard await contextFilter(context) else { return }

        guard let uri = uri else {
            throw LSPDocumentServiceError.noURI
        }

        let params = DidCloseTextDocumentParams(uri: uri)

        try await server.didCloseTextDocument(params: params)
    }

    private func sendChangeEvents(_ events: [TextDocumentContentChangeEvent], version: Int) async throws {
        guard let uri = uri else { fatalError() }

        let versionedId = VersionedTextDocumentIdentifier(uri: uri,
                                                          version: version)
        let params = DidChangeTextDocumentParams(textDocument: versionedId,
                                                 contentChanges: events)

        try await server.didChangeTextDocument(params: params)

        textChangeSubject.send()
    }

    private func invalidateTokens(in target: TextTarget) {
        host.invalidateTokens(for: context.id, in: target)
    }

    private func handleCapabilitiesChanged() {
        let legend = serverCapabilities?.semanticTokensProvider?.effectiveOptions.legend
        let textDocId = try? textDocumentIdentifier

        if let legend, let textDocId {
            self.tokenRepresentation = SemanticTokenRepresentation(legend: legend, textDocument: textDocId, server: server)
        } else {
            self.tokenRepresentation = nil
        }

        let strings = serverCapabilities?.completionProvider?.triggerCharacters ?? []

        let config = ServiceConfiguration(completionTriggers: Set(strings))

        host.documentServiceConfigurationChanged(for: context.id, to: config)
    }
}

extension LSPDocumentService: DocumentService {
    func willApplyChange(_ change: CombinedTextChange) async throws {
    }

    func didApplyChange(_ change: CombinedTextChange) async throws {
        guard uri != nil else { return }
		guard await contextFilter(context) else { return }

        switch documentSyncKind {
        case .none:
            break
        case .full:
            let content = try await host.textContent(for: context.id, in: change.textRange)

            let changeEvent = TextDocumentContentChangeEvent(range: nil, rangeLength: nil, text: content.string)
            let version = content.version + 1

            try await sendChangeEvents([changeEvent], version: version)
        case .incremental:
            let range = change.textRange.lspRange
            let length = change.textRange.range.length
            let version = change.textRange.version + 1
            
            let changeEvent = TextDocumentContentChangeEvent(range: range, rangeLength: length, text: change.string)

            try await sendChangeEvents([changeEvent], version: version)
        }
    }

    func willSave() async throws {
		guard await contextFilter(context) else { return }

        let textDocId = try textDocumentIdentifier

        let params = WillSaveTextDocumentParams(textDocument: textDocId, reason: .manual)

        try await server.willSaveTextDocument(params: params)
    }

    func didSave() async throws {
		guard await contextFilter(context) else { return }

        let textDocId = try textDocumentIdentifier

        let params = DidSaveTextDocumentParams(textDocument: textDocId)

        try await server.didSaveTextDocument(params: params)
    }

    var completionService: CompletionService? {
        get async throws { return self }
    }

    var formattingService: FormattingService? {
        get async throws { return self }
    }

    var semanticDetailsService: SemanticDetailsService? {
        get async throws { return self }
    }

    var defintionService: DefinitionService? {
        get async throws { return self }
    }

    var tokenService: TokenService? {
        get async throws { return self }
    }
}

extension LSPDocumentService: CompletionService {
    func completions(at position: CombinedTextPosition, trigger: CompletionTrigger) async throws -> [Completion] {
		guard await contextFilter(context) else { return [] }

        let textDocId = try textDocumentIdentifier
        let location = position.location
        let lspContext = trigger.completionContext
        let lspPosition = position.lspPosition

        let params = CompletionParams(textDocument: textDocId, position: lspPosition, context: lspContext)

        let response = try await server.completion(params: params)

        let fallbackRange = TextRange.range(NSRange(location: location, length: 0))
        let transformer = transformers.completionTransformer

        return response?.items.compactMap({ transformer(fallbackRange, $0) }) ?? []
    }
}

extension LSPDocumentService: FormattingService {
    func formatting(for ranges: [CombinedTextRange]) async throws -> [TextChange] {
		guard await contextFilter(context) else { return [] }

        let textDocId = try textDocumentIdentifier

        switch serverCapabilities?.documentFormattingProvider {
        case .optionA(false), nil:
            throw LSPServiceError.unsupported
        case .optionA(true), .optionB:
            break
        }

        let configuration = context.configuration

        let options = FormattingOptions(tabSize: configuration.tabWidth,
                                        insertSpaces: configuration.indentIsSoft)
        let params = DocumentFormattingParams(textDocument: textDocId, options: options)

        let response = try await server.formatting(params: params)

        let transformer = transformers.textEditsTransformer

        return response.map({ transformer($0) }) ?? []
    }

    func organizeImports() async throws -> [TextChange] {
		guard await contextFilter(context) else { return [] }

        let textDocId = try textDocumentIdentifier

        switch serverCapabilities?.codeActionProvider {
        case .optionA(false), nil:
            throw LSPServiceError.unsupported
        case .optionA(true):
            break
        case .optionB(let options):
            if options.codeActionKinds?.contains(CodeActionKind.SourceOrganizeImports) == true {
                break
            }

            throw LSPServiceError.unsupported
        }

        let uri = textDocId.uri
        let context = CodeActionContext(diagnostics: [], only: [.SourceOrganizeImports])
        let range = LSPRange(start: Position(line: 1, character: 0),
                             end: Position(line: 1, character: 0))
        let params = CodeActionParams(textDocument: textDocId, range: range, context: context)

        let response = try await server.codeAction(params: params)

        return transformers.organizeImportsTransformer(uri, response)
    }
}

extension LSPDocumentService: SemanticDetailsService {
    func semanticDetails(at position: CombinedTextPosition) async throws -> SemanticDetails? {
		guard await contextFilter(context) else { return nil }

        let textDocId = try textDocumentIdentifier
        let params = TextDocumentPositionParams(textDocument: textDocId, position: position.lspPosition)

        let response = try await server.hover(params: params)

        return transformers.hoverTransformer(position, response)
    }
}

extension LSPDocumentService: DefinitionService {
    func definitions(at position: CombinedTextPosition) async throws -> [DefinitionLocation] {
		guard await contextFilter(context) else { return [] }

        let textDocId = try textDocumentIdentifier

        let params = TextDocumentPositionParams(textDocument: textDocId, position: position.lspPosition)

        let definition = try await server.definition(params: params)

        return transformers.definitionTransformer(definition)
    }
}

extension LSPDocumentService: TokenService {
    func tokens(in range: CombinedTextRange) async throws -> [ChimeExtensionInterface.Token] {
		guard await contextFilter(context) else { return [] }

        guard let rep = tokenRepresentation else {
            return []
        }

        let deltas = serverCapabilities?.semanticTokensProvider?.effectiveOptions.full.deltaSupported ?? false
        let response = try await rep.tokens(in: range.lspRange, supportsDeltas: deltas)

        let transformer = transformers.semanticTokenTransformer

        return response.map({ transformer($0) })
    }
}
