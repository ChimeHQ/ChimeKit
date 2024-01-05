import Foundation

import ChimeExtensionInterface
import LanguageServerProtocol

import enum ChimeExtensionInterface.TextRange

extension LineRelativeTextPosition {
    public var lspPosition: Position {
        return Position(line: line, character: offset)
    }

    public init(_ lspPosition: Position) {
        self.init(line: lspPosition.line, offset: lspPosition.character)
    }
}

extension CombinedTextPosition {
    public var lspPosition: Position {
        return relativePosition.lspPosition
    }
}

extension LineRelativeTextRange {
    public init(_ lspRange: LSPRange) {
        self = LineRelativeTextPosition(lspRange.start)..<LineRelativeTextPosition(lspRange.end)
    }

    public var lspRange: LSPRange {
        return LSPRange(start: lowerBound.lspPosition, end: upperBound.lspPosition)
    }
}

extension CombinedTextRange {
    public var lspRange: LSPRange {
        return lineRelativeRange.lspRange
    }
}

extension CompletionTrigger {
    var completionContext: CompletionContext {
        switch self {
        case .invoked:
            return CompletionContext(triggerKind: .invoked, triggerCharacter: nil)
        case .character(let value):
            return CompletionContext(triggerKind: .triggerCharacter, triggerCharacter: value)
        }
    }
}

extension Snippet {
    var completionFragments: [CompletionFragment] {
        elements.compactMap { element -> CompletionFragment? in
            switch element {
            case .text(let value):
                return .text(value)
            case .placeholder(_, let value):
                let (label, content) = Snippet.parsePlaceholderValue(value)

                return .placeholder(label: label, content: content)
            default:
                return nil
            }
        }
    }
}

extension TextEdit {
    public var textRange: TextRange {
        return .lineRelativeRange(LineRelativeTextRange(range))
    }

	/// Combine two TextEdit structures together, if they can be represented as a single edit.
	public func merge(_ other: TextEdit) -> TextEdit? {
		if range.start == other.range.end {
			return TextEdit(
				range: LSPRange(start: other.range.start, end: range.end),
				newText: other.newText + newText
			)
		}

		return nil
	}

	public func merge(_ others: [TextEdit]) -> (TextEdit, [TextEdit]) {
		var current: TextEdit? = self
		var list = others

		while let otherEdit = list.first {
			guard let newEdit = current?.merge(otherEdit) else {
				break
			}

			current = newEdit
			list.removeFirst()
		}

		return (current ?? self, list)
	}
}

extension LSPRange {
    public var textRange: TextRange {
        return .lineRelativeRange(LineRelativeTextRange(self))
    }
}

extension ThreeTypeOption where T == MarkedString, U == [MarkedString], V == MarkupContent {
    public var value: String? {
        switch self {
        case .optionA(let ms):
            return ms.value
        case .optionB(let msArray):
            return msArray.first?.value
        case .optionC(let content):
            return content.value
        }
    }
}

extension Hover {
    public var value: String? {
        return self.contents.value
    }
}
