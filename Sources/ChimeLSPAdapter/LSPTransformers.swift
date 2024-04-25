import Foundation

import ChimeExtensionInterface
import LanguageServerProtocol

import struct ChimeExtensionInterface.Diagnostic
import enum ChimeExtensionInterface.TextRange
import struct ChimeExtensionInterface.Token

public typealias CompletionTransformer = (TextRange, CompletionItem) -> Completion?
public typealias TextEditTransformer = (TextEdit) -> TextChange
public typealias TextEditsTransformer = ([TextEdit]) -> [TextChange]
public typealias OrganizeImportsTransformer = (DocumentUri, CodeActionResponse) -> [TextChange]
public typealias DiagnosticTransformer = (LanguageServerProtocol.Diagnostic) -> Diagnostic
public typealias HoverTransformer = (CombinedTextPosition, HoverResponse) -> SemanticDetails?
public typealias DefinitionTransformer = (DefinitionResponse) -> [DefinitionLocation]
public typealias WorkspaceSymbolTransformer = (WorkspaceSymbol) -> Symbol
public typealias SymbolInformationTransformer = (SymbolInformation) -> Symbol
public typealias SemanticTokenTransformer = (LanguageServerProtocol.Token) -> Token

/// A collection of functions that transform LSP result objects.
public struct LSPTransformers {
    public let completionTransformer: CompletionTransformer
    public let textEditTransformer: TextEditTransformer
    public let diagnosticTransformer: DiagnosticTransformer
    public let hoverTransformer: HoverTransformer
    public let definitionTransformer: DefinitionTransformer
    public let symbolInformationTransformer: SymbolInformationTransformer
    public let semanticTokenTransformer: SemanticTokenTransformer

	public init(
		completionTransformer: @escaping CompletionTransformer = LSPTransformers.standardCompletionTransformer,
		textEditTransformer: @escaping TextEditTransformer = LSPTransformers.standardTextEditTransformer,
		diagnosticTransformer: @escaping DiagnosticTransformer = LSPTransformers.standardDiagnosticTransformer,
		hoverTransformer: @escaping HoverTransformer = LSPTransformers.standardHoverTransformer,
		definitionTransformer: @escaping DefinitionTransformer = LSPTransformers.standardDefinitionTransformer,
		symbolInformationTransformer: @escaping SymbolInformationTransformer = LSPTransformers.standardSymbolInformationTransformer,
		semanticTokenTransformer: @escaping SemanticTokenTransformer = LSPTransformers.standardSemanticTokenTransformer
	) {
        self.completionTransformer = completionTransformer
        self.textEditTransformer = textEditTransformer
        self.diagnosticTransformer = diagnosticTransformer
        self.hoverTransformer = hoverTransformer
        self.definitionTransformer = definitionTransformer
        self.symbolInformationTransformer = symbolInformationTransformer
        self.semanticTokenTransformer = semanticTokenTransformer
    }
}

extension LSPTransformers {
    public var textEditsTransformer: TextEditsTransformer {
        return { edits in
            let applicableEdits = TextEdit.makeApplicable(edits)

            return applicableEdits.map(textEditTransformer)
        }
    }

    public var organizeImportsTransformer: OrganizeImportsTransformer {
        return { uri, response in
            let actions = (response ?? []).compactMap { twoType -> CodeAction? in
                switch twoType {
                case .optionB(let action):
                    return action
                default:
                    return nil
                }
            }

            let organizeImportActions = actions.filter({ $0.kind == CodeActionKind.SourceOrganizeImports })
            let workspaceEdits = organizeImportActions.compactMap({ $0.edit })

            let docChanges = workspaceEdits.compactMap({ $0.documentChanges }).flatMap({ $0 })
            let documentEdits = docChanges.compactMap({ (change) -> TextDocumentEdit? in
                if case let .textDocumentEdit(edit) = change {
                    return edit
                }

                return nil
            })

            let plainEdits = workspaceEdits.compactMap({ $0.changes?[uri] }).flatMap({ $0 })

            let edits = plainEdits + documentEdits.flatMap({ $0.edits })

            return textEditsTransformer(edits)
        }
    }

    public var workspaceSymbolResponseTransformer: (WorkspaceSymbolResponse) -> [Symbol] {
        return { response in
            switch response {
            case nil:
                return []
            case .optionA(let symbolInformationArray):
                return symbolInformationArray.map({ symbolInformationTransformer($0) })
            case .optionB:
                return []
            }
        }
    }
}

extension LSPTransformers {
    public static let standardCompletionTransformer: CompletionTransformer = { fallbackRange, item in
		// This is a little bit of a hack to keep things working. Teally needs to be revisited.
		let edit = item.textEdit.map { twoType in
			switch twoType {
			case let .optionA(textEdit):
				textEdit
			case let .optionB(insertReplaceEdit):
				TextEdit(range: insertReplaceEdit.replace, newText: insertReplaceEdit.newText)
			}
		}

        guard let text = edit?.newText ?? item.insertText else {
            return nil
        }

        let displayString: String

        if let detail = item.detail {
            displayString = "\(item.label) - \(detail)"
        } else {
            displayString = item.label
        }

		// this currently discards any additional edits that could not be applied, but at least it can handle some kinds
		let resolvedEditPair = edit?.merge(item.additionalTextEdits ?? [])

		let range = resolvedEditPair?.0.textRange ?? fallbackRange
        let fragments = Snippet(value: text).completionFragments

        return Completion(displayString: displayString, range: range, fragments: fragments)
    }
}

extension LSPTransformers {
    public static let standardTextEditTransformer: TextEditTransformer = { edit in
        let start = LineRelativeTextPosition(edit.range.start)
        let end = LineRelativeTextPosition(edit.range.end)
        let relativeRange = start..<end

        return TextChange(string: edit.newText, textRange: .lineRelativeRange(relativeRange))
    }
}

extension LSPTransformers {
    public static let standardDiagnosticTransformer: DiagnosticTransformer = { diagnostic in
        let relations = diagnostic.relatedInformation?.compactMap({ (relatedInfo) -> Diagnostic.Relation? in
            guard let url = URL(string: relatedInfo.location.uri) else {
                return nil
            }

            let range = LineRelativeTextRange(relatedInfo.location.range)
            let message = relatedInfo.message

            return Diagnostic.Relation(message: message, url: url, range: .lineRelativeRange(range))
        }) ?? []

        let range = LineRelativeTextRange(diagnostic.range)

        let kind: Diagnostic.Kind

        switch diagnostic.severity {
        case .error?: kind = .error
        case .warning?: kind = .warning
        case .information?, nil: kind = .information
        case .hint?: kind = .hint
        }

        var qualifiers = Set<Diagnostic.Qualifier>()

        if diagnostic.tags?.contains(.unnecessary) ?? false {
            qualifiers.insert(.unnecessary)
        }

        if diagnostic.tags?.contains(.deprecated) ?? false {
            qualifiers.insert(.deprecated)
        }

        let diagnostic = Diagnostic(range: .lineRelativeRange(range),
                                                       message: diagnostic.message,
                                                       kind: kind,
                                                       relationships: relations,
                                                       qualifiers: qualifiers)

        return diagnostic
    }
}

extension LSPTransformers {
    public static let standardHoverTransformer: HoverTransformer = { position, response in
        guard let response = response else { return nil }

//        let textRange: ExtensionInterface.TextRange
        let textRange: TextRange

        if let range = response.range {
            textRange = .lineRelativeRange(LineRelativeTextRange(range))
        } else {
            textRange = .range(NSRange(location: position.location, length: 0))
        }

        switch response.contents {
        case .optionA(.optionA(let string)):
            return SemanticDetails(textRange: textRange, documentation: string)
        case .optionA(.optionB(let pair)):
            return SemanticDetails(textRange: textRange, documentation: pair.value)
        case .optionB(let markedStrings):
            let value = markedStrings.first?.value

            return SemanticDetails(textRange: textRange, documentation: value, containsMarkdown: true)
        case .optionC(let content):
            return SemanticDetails(textRange: textRange, documentation: content.value, containsMarkdown: content.kind == .markdown)
        }
    }
}

extension LSPTransformers {
    public static let standardDefinitionTransformer: DefinitionTransformer = { response in
        switch response {
        case nil:
            return []
        case .optionA(let loc)?:
            guard let url = URL(string: loc.uri) else {
                assertionFailure()

                return []
            }

            let range = loc.range.textRange

            return [DefinitionLocation(url: url, highlightRange: range, selectionRange: range)]
        case .optionB(let locs)?:
            return locs.compactMap { (loc) -> DefinitionLocation? in
                guard let url = URL(string: loc.uri) else {
                    return nil
                }

                let range = loc.range.textRange

                return DefinitionLocation(url: url, highlightRange: range, selectionRange: range)
            }
        case .optionC(let links)?:
            return links.map { (link) -> DefinitionLocation in
                let url = URL(fileURLWithPath: link.targetUri, isDirectory: false)
                let highlightRange = link.targetRange.textRange
                let selectionRange = link.targetSelectionRange.textRange

                return DefinitionLocation(url: url, highlightRange: highlightRange, selectionRange: selectionRange)
            }
        }

    }
}

extension LSPTransformers {
    public static let standardSymbolInformationTransformer: SymbolInformationTransformer = { info in
        let kind: Symbol.Kind

        switch info.kind {
        case .method:
            kind = .method
        case .function:
            kind = .function
        default:
            kind = .function
        }

        let url = URL(string: info.location.uri)!
        let range = info.location.range.textRange

        return Symbol(name: info.name, containerName: info.containerName, kind: kind, url: url, range: range)
    }
}

extension LSPTransformers {
    public static let standardSemanticTokenTransformer: SemanticTokenTransformer = { token in
        let range = LineRelativeTextRange(token.range)

        return Token(name: token.tokenType, textRange: .lineRelativeRange(range))
    }
}
