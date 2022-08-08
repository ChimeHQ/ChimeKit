import Foundation

//import ExtensionInterface
//import LineTracker

@objc(CodingCombinedTextRange)
public final class CodingCombinedTextRange: NSObject {
    public let value: CombinedTextRange

    public init(_ value: CombinedTextRange) {
        self.value = value
    }
}

extension CodingCombinedTextRange: NSSecureCoding {
    public static var supportsSecureCoding: Bool {
        return true
    }

    public func encode(with coder: NSCoder) {
        coder.encode(value.version, forKey: "version")
    }

    public convenience init?(coder: NSCoder) {
        let version = coder.decodeInteger(forKey: "version")

        let lineStart = LineRelativeTextPosition(line: coder.decodeInteger(forKey: "start_line"),
                                                 offset: coder.decodeInteger(forKey: "start_offset"))

        let lineEnd = LineRelativeTextPosition(line: coder.decodeInteger(forKey: "end_line"),
                                                 offset: coder.decodeInteger(forKey: "end_offset"))

        let limit = coder.decodeInteger(forKey: "limit")

        let textRange = CombinedTextRange(version: version,
                                           range: NSRange(0..<0),
                                           lineRelativeRange: lineStart..<lineEnd,
                                           limit: limit)
        self.init(textRange)
    }
}
