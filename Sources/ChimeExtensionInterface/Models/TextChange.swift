import Foundation

public struct CombinedTextContent: Codable, Hashable, Sendable {
    public let string: String
    public let range: CombinedTextRange

    public init(string: String, range: CombinedTextRange) {
        self.range = range
        self.string = string
    }

    public var stringLength: Int {
        return string.utf16.count
    }

    public var version: Int {
        return range.version
    }
}

public struct CombinedTextChange: Codable, Hashable, Sendable {
    public let string: String
    public let textRange: CombinedTextRange

    public init(string: String, textRange: CombinedTextRange) {
        self.textRange = textRange
        self.string = string
    }
}

extension CombinedTextChange {
    public var delta: Int {
        return string.utf16.count - textRange.range.length
    }

    public var postApplyLimit: Int {
        return textRange.limit + delta
    }
}

public struct TextChange: Codable, Hashable, Sendable {
    public let string: String
    public let textRange: TextRange

    public init(string: String, textRange: TextRange) {
        self.string = string
        self.textRange = textRange
    }
}
