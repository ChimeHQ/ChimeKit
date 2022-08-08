import Foundation

//import ExtensionInterface
//import LineTracker

@objc(CodingTextRange)
public final class CodingTextRange: NSObject {
    public let value: TextRange

    public init(_ value: TextRange) {
        self.value = value
    }

}

extension CodingTextRange: NSSecureCoding {
    public static var supportsSecureCoding: Bool {
        return true
    }

    public func encode(with coder: NSCoder) {
        switch value {
        case .range(let range):
            coder.encode(1, forKey: "case")
            coder.encode(range.location, forKey: "location")
            coder.encode(range.length, forKey: "length")
        case .lineRelativeRange(let relativeRange):
            coder.encode(2, forKey: "case")

            coder.encode(relativeRange.lowerBound.line, forKey: "start_line")
            coder.encode(relativeRange.lowerBound.offset, forKey: "start_offset")

            coder.encode(relativeRange.upperBound.line, forKey: "end_line")
            coder.encode(relativeRange.upperBound.offset, forKey: "end_offset")
        }
    }

    public convenience init?(coder: NSCoder) {
        switch coder.decodeInteger(forKey: "case") {
        case 1:
            let range = NSRange(location: coder.decodeInteger(forKey: "location"),
                                length: coder.decodeInteger(forKey: "length"))

            self.init(.range(range))
        case 2:
            let start = LineRelativeTextPosition(line: coder.decodeInteger(forKey: "start_line"),
                                                 offset: coder.decodeInteger(forKey: "start_offset"))

            let end = LineRelativeTextPosition(line: coder.decodeInteger(forKey: "end_line"),
                                               offset: coder.decodeInteger(forKey: "end_offset"))

            self.init(.lineRelativeRange(start..<end))
        default:
            return nil
        }
    }
}
