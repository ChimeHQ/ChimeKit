import Foundation

public struct ServiceConfiguration: Codable, Hashable, Sendable {
    public let completionTriggers: Set<String>

    public init(completionTriggers: Set<String> = Set()) {
        self.completionTriggers = completionTriggers
    }
}
