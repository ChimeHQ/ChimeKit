import Foundation

public struct DefinitionLocation: Codable, Hashable, Sendable {
    public let url: URL
    public let highlightRange: TextRange
    public let selectionRange: TextRange

    public init(url: URL, highlightRange: TextRange, selectionRange: TextRange) {
        self.url = url
        self.highlightRange = highlightRange
        self.selectionRange = selectionRange
    }
}

public protocol DefinitionService {
	@MainActor
    func definitions(at position: CombinedTextPosition) async throws -> [DefinitionLocation]
}
