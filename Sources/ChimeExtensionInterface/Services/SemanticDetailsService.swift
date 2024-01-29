import Foundation

public struct SemanticDetails {
    public let textRange: TextRange
    public let synopsis: String?
    public let declaration: String?
    public let documentation: String?
    public let containsMarkdown: Bool

    public init(textRange: TextRange, synopsis: String? = nil, declaration: String? = nil, documentation: String? = nil, containsMarkdown: Bool = false) {
        self.textRange = textRange
        self.synopsis = synopsis
        self.declaration = declaration
        self.documentation = documentation
        self.containsMarkdown = containsMarkdown
    }

    public var onlyDocumentation: Bool {
        if let synopsis = synopsis, synopsis.isEmpty == false {
            return false
        }

        if let declaration = declaration, declaration.isEmpty == false {
            return false
        }

        return true
    }
}

extension SemanticDetails: Hashable {}

extension SemanticDetails: Codable {}

extension SemanticDetails: Sendable {}

public protocol SemanticDetailsService {
	@MainActor
    func semanticDetails(at position: CombinedTextPosition) async throws -> SemanticDetails?
}
