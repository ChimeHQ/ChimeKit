import Foundation

public enum TextTarget: Codable, Hashable, Sendable {
    case all
    case set(IndexSet)
    case range(TextRange)
}
