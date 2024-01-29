import Foundation

public struct Symbol: Codable, Hashable, Sendable {
    public enum Kind: Codable, Hashable, Sendable, CaseIterable {
        case function
        case method
        case module
    }

    public let name: String
    public let containerName: String?
    public let kind: Kind
    public let url: URL
    public let range: TextRange?

    public init(name: String, containerName: String? = nil, kind: Symbol.Kind, url: URL, range: TextRange? = nil) {
        self.name = name
        self.containerName = containerName
        self.kind = kind
        self.url = url
        self.range = range
    }
}

public protocol SymbolQueryService {
	@MainActor
    func symbols(matching query: String) async throws -> [Symbol]
}
