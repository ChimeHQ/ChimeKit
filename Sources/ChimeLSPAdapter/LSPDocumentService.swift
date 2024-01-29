import Foundation
import OSLog

import ChimeExtensionInterface
import LanguageServerProtocol
import Queue

@MainActor
final class LSPDocumentService {
	private let serverHostInterface: LSPHostServerInterface
	private let logger = Logger(subsystem: "com.chimehq.ChimeKit", category: "LSPDocumentService")
	private var tokenRepresentation: TokenRepresentation?

	let context: DocumentContext
	
	init(serverHostInterface: LSPHostServerInterface, context: DocumentContext) {
		self.serverHostInterface = serverHostInterface
		self.context = context
	}
		
	var textDocumentItem: TextDocumentItem {
		get async throws {
			let uri = try context.uri

			guard
				let languageId = context.languageIdentifier
			else {
				throw LSPServiceError.languageNotDefined
			}
			
			let pair = try await serverHostInterface.host.textContent(for: context.id)

			return TextDocumentItem(uri: uri,
									languageId: languageId,
									version: pair.1,
									text: pair.0)
		}
	}

	var uri: DocumentUri? {
		try? context.uri
	}

	var isOpenable: Bool {
		return context.url != nil && context.languageIdentifier != nil
	}

	func handleCapabilitiesChanged(_ capabilities: ServerCapabilities) {
		let legend = capabilities.semanticTokensProvider?.effectiveOptions.legend

		let wasAvailable = tokenRepresentation != nil

		self.tokenRepresentation = legend.map { TokenRepresentation(legend: $0) }

		let nowAvailable = tokenRepresentation != nil

		let id = context.id

		let strings = capabilities.completionProvider?.triggerCharacters ?? []
		let config = ServiceConfiguration(completionTriggers: Set(strings))

		serverHostInterface.enqueue { _, _, host in
			// if our token rep changes, we have to invalidate all existing tokens
			if wasAvailable != nowAvailable {
				host.invalidateTokens(for: id, in: .all)
			}

			host.serviceConfigurationChanged(for: id, to: config)
		}
	}
}

extension LSPDocumentService: DocumentService {
	func willApplyChange(_ change: CombinedTextChange) throws {
	}

	private func sendChangeEvents(_ events: [TextDocumentContentChangeEvent], to uri: DocumentUri, version: Int) async throws {
		let versionedId = VersionedTextDocumentIdentifier(uri: uri,
														  version: version)
		let params = DidChangeTextDocumentParams(textDocument: versionedId,
												 contentChanges: events)

		try await serverHostInterface.server.textDocumentDidChange(params)
	}

	func didApplyChange(_ change: CombinedTextChange) throws {
		let uri = try context.uri
		
		serverHostInterface.enqueue(barrier: true) { [context] (server, _, host) in
			let syncKind = await server.capabilities?.textDocumentSync?.effectiveOptions.change ?? .none

			switch syncKind {
			case .none:
				break
			case .full:
				let content = try await host.textContent(for: context.id, in: change.textRange)

				let changeEvent = TextDocumentContentChangeEvent(range: nil, rangeLength: nil, text: content.string)
				let version = content.version + 1

				try await self.sendChangeEvents([changeEvent], to: uri, version: version)
			case .incremental:
				let range = change.textRange.lspRange
				let length = change.textRange.range.length
				let version = change.textRange.version + 1

				let changeEvent = TextDocumentContentChangeEvent(range: range, rangeLength: length, text: change.string)

				try await self.sendChangeEvents([changeEvent], to: uri, version: version)
			}

			host.invalidateTokens(for: context.id, in: .all)
		}
	}

	func willSave() throws {
		let id = try context.textDocumentIdentifier

		serverHostInterface.enqueue(barrier: true) { server, _, _ in
			let params = WillSaveTextDocumentParams(textDocument: id, reason: .manual)

			try await server.textDocumentWillSave(params)
		}
	}

	func didSave() throws {
	}

	var completionService: (some CompletionService)? { return self }
	var formattingService: (some FormattingService)? { return self }
	var semanticDetailsService: (some SemanticDetailsService)? { return self }
	var defintionService: (some DefinitionService)?  { return self }
	var tokenService: (some TokenService)? { return self }
	var symbolService: (some SymbolQueryService)?  { return nil as SymbolQueryServicePlaceholder? }
}

extension LSPDocumentService: CompletionService {
	func completions(at position: CombinedTextPosition, trigger: CompletionTrigger) async throws -> [Completion] {
		let textDocId = try context.textDocumentIdentifier

		return try await serverHostInterface.operationValue { (server, transformers, _) in
			let location = position.location
			let lspContext = trigger.completionContext
			let lspPosition = position.lspPosition

			let params = CompletionParams(textDocument: textDocId, position: lspPosition, context: lspContext)

			do {
				let response = try await server.completion(params)
				

				let fallbackRange = TextRange.range(NSRange(location: location, length: 0))
				let transformer = transformers.completionTransformer
				
				return response?.items.compactMap({ transformer(fallbackRange, $0) }) ?? []
			} catch {
				throw error
			}
		}
	}
}

extension LSPDocumentService: FormattingService {
	func formatting(for ranges: [CombinedTextRange]) async throws -> [TextChange] {
		return try await serverHostInterface.operationValue { [context] server, transformers, _ in
			let textDocId = try context.textDocumentIdentifier

			let caps = await server.capabilities

			switch caps?.documentFormattingProvider {
			case .optionA(false), nil:
				throw LSPServiceError.unsupported
			case .optionA(true), .optionB:
				break
			}

			let configuration = context.configuration
			let options = FormattingOptions(tabSize: configuration.tabWidth,
											insertSpaces: configuration.indentIsSoft)
			let params = DocumentFormattingParams(textDocument: textDocId, options: options)

			let response = try await server.formatting(params)

			let transformer = transformers.textEditsTransformer

			return response.map({ transformer($0) }) ?? []
		}
	}

	func organizeImports() async throws -> [TextChange] {
		return try await serverHostInterface.operationValue { [context] server, transformers, _ in
			let textDocId = try context.textDocumentIdentifier

			let caps = await server.capabilities

			switch caps?.codeActionProvider {
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

			let response = try await server.codeAction(params)

			return transformers.organizeImportsTransformer(uri, response)
		}
	}
}

extension LSPDocumentService: SemanticDetailsService {
	func semanticDetails(at position: CombinedTextPosition) async throws -> SemanticDetails? {
		return try await serverHostInterface.operationValue { [context] server, transformers, _ in
			let textDocId = try context.textDocumentIdentifier
			let params = TextDocumentPositionParams(textDocument: textDocId, position: position.lspPosition)

			let response = try await server.hover(params)

			return transformers.hoverTransformer(position, response)
		}
	}
}

extension LSPDocumentService: DefinitionService {
	func definitions(at position: CombinedTextPosition) async throws -> [DefinitionLocation] {
		return try await serverHostInterface.operationValue { [context] server, transformers, _ in
			let textDocId = try context.textDocumentIdentifier
			let params = TextDocumentPositionParams(textDocument: textDocId, position: position.lspPosition)

			let definition = try await server.definition(params)

			return transformers.definitionTransformer(definition)
		}
	}
}

extension LSPDocumentService: TokenService {
	private func semanticTokenResponse(
		in range: CombinedTextRange,
		lastResultId: String?,
		server: LSPHostServerInterface.Server
	) async throws -> SemanticTokensDeltaResponse {
		let id = try context.textDocumentIdentifier
		let deltas = await server.capabilities?.semanticTokensProvider?.effectiveOptions.full?.deltaSupported ?? false

		if deltas, let lastId = lastResultId {
			let params = SemanticTokensDeltaParams(textDocument: id, previousResultId: lastId)

			return try await server.semanticTokensFullDelta(params)
		}

		let params = SemanticTokensParams(textDocument: id)

		// translate into a delta response
		return try await server.semanticTokensFull(params).map { .optionA($0) }
	}

	func tokens(in range: CombinedTextRange) async throws -> [ChimeExtensionInterface.Token] {
		guard let rep = tokenRepresentation else {
			return []
		}

		return try await serverHostInterface.operationValue { server, transformers, _ in
			let response = try await self.semanticTokenResponse(in: range, lastResultId: rep.lastResultId, server: server)

			_ = rep.applyResponse(response)

			let tokens = rep.decodeTokens(in: range.lspRange)

			let transformer = transformers.semanticTokenTransformer

			return tokens.map { transformer($0) }
		}
	}
}
