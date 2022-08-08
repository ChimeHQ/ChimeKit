import Foundation

public struct DocumentConfiguration: Codable, Hashable, Sendable {
    public let indentIsSoft: Bool
    public let indentSize: Int
    public let tabWidth: Int

    public init(indentIsSoft: Bool = false, indentSize: Int, tabWidth: Int) {
        self.indentIsSoft = indentIsSoft
        self.indentSize = indentSize
        self.tabWidth = tabWidth
    }

    public init(indentIsSoft: Bool = false, indentSize: Int = 4) {
        self.init(indentIsSoft: indentIsSoft, indentSize: indentSize, tabWidth: indentSize)
    }
}

public extension DocumentConfiguration {
    var indentationUnit: String {
        if indentIsSoft {
            return String(repeating: " ", count: indentSize)
        }

        return "\t"
    }
}
