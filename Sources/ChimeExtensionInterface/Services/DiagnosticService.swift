import Foundation

public struct Diagnostic: Hashable, Codable, Sendable {
    public enum Kind: Hashable, Codable, Sendable {
        case hint
        case information
        case warning
        case error
    }

    public struct Relation: Hashable, Codable, Sendable {
        public let message: String
        public let url: URL
        public let range: TextRange

        public init(message: String, url: URL, range: TextRange) {
            self.message = message
            self.url = url
            self.range = range
        }
    }

    public enum Qualifier: Hashable, Codable, Sendable {
        case deprecated
        case unnecessary
    }

    public let range: TextRange
    public let message: String
    public let kind: Kind
    public let relationships: [Relation]
    public let qualifiers: Set<Qualifier>

    public init(range: TextRange, message: String, kind: Kind, relationships: [Relation], qualifiers: Set<Qualifier>) {
        self.range = range
        self.message = message
        self.kind = kind
        self.relationships = relationships
        self.qualifiers = qualifiers
    }
}

public typealias DiagnosticsHandler = ([Diagnostic]) -> Void

public protocol DiagnosticsService {
    func setDiagnosticHandler(_ block: DiagnosticsHandler?)
}
