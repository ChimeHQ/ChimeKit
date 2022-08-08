import Foundation

public struct Token: Codable, Hashable, Sendable {
    public let name: String
    public let textRange: TextRange

    public init(name: String, textRange: TextRange) {
        self.name = name
        self.textRange = textRange
    }
}

public protocol TokenService {
    func tokens(in range: CombinedTextRange) async throws -> [Token]
}
