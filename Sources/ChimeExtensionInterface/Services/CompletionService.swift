import Combine
import Foundation

public enum CompletionFragment: Codable, Hashable, Sendable {
    case text(String)
    case placeholder(label: String, content: String)
}

public struct Completion: Codable, Hashable, Sendable {
    public let displayString: String
    public let range: TextRange
    public let fragments: [CompletionFragment]

    public init(displayString: String, range: TextRange, fragments: [CompletionFragment]) {
        self.displayString = displayString
        self.range = range
        self.fragments = fragments
    }
}


public enum CompletionTrigger: Codable, Hashable, Sendable {
    case invoked
    case character(String)
}

public protocol CompletionService {
	@MainActor
    func completions(at position: CombinedTextPosition, trigger: CompletionTrigger) async throws -> [Completion]
}
