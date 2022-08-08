import Foundation

import UniformTypeIdentifiers

public typealias DocumentIdentity = UUID
public typealias DocumentContentIdentity = UUID

public struct DocumentContext: Codable, Hashable, Sendable {
    public let id: DocumentIdentity
    public let contentId: DocumentContentIdentity
    public let url: URL?
    public let uti: UTType
    public let configuration: DocumentConfiguration
    public let projectContext: ProjectContext?

    public init(id: DocumentIdentity,
                contentId: DocumentContentIdentity,
                url: URL?,
                uti: UTType,
                configuration: DocumentConfiguration,
                projectContext: ProjectContext?) {
        self.id = id
        self.contentId = contentId
        self.url = url
        self.uti = uti
        self.configuration = configuration
        self.projectContext = projectContext
    }

    public init() {
        self.init(id: UUID(),
                  contentId: UUID(),
                  url: nil,
                  uti: .plainText,
                  configuration: DocumentConfiguration(),
                  projectContext: nil)
    }

    public var enclosingProjectURL: URL? {
        return projectContext?.url ?? url?.deletingLastPathComponent()
    }
}

extension DocumentContext: CustomStringConvertible {
    public var description: String {
        let path = url?.absoluteString ?? "-"
        let rootUrl = projectContext?.url.absoluteString ?? "-"

        return "<Document: \(id) \(contentId) \(uti) \(path) \(rootUrl)>"
    }
}
