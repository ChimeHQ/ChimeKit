import Foundation

public typealias ProjectIdentity = UUID

public struct ProjectContext: Codable, Hashable, Sendable {
    public let id: ProjectIdentity
    public let url: URL

    public init(id: ProjectIdentity = UUID(), url: URL) {
        self.id = id
        self.url = url
    }
}

public protocol ProjectContextual {
    var projectContext: ProjectContext { get async }
}
