import Foundation

//import ExtensionInterface
//import LineTracker

@objc(CodingCombinedTextPosition)
public final class CodingCombinedTextPosition: NSObject {
    public let value: CombinedTextPosition

    public init(_ value: CombinedTextPosition) {
        self.value = value
    }
}

extension CodingCombinedTextPosition: NSSecureCoding {
    public static var supportsSecureCoding: Bool {
        return true
    }

    public func encode(with coder: NSCoder) {
        coder.encode(value.location, forKey: "location")
        coder.encode(value.relativePosition.line, forKey: "line")
        coder.encode(value.relativePosition.offset, forKey: "offset")
    }

    public convenience init?(coder: NSCoder) {
        let location = coder.decodeInteger(forKey: "location")
        let relativePosition = LineRelativeTextPosition(line: coder.decodeInteger(forKey: "line"),
                                                        offset: coder.decodeInteger(forKey: "offset"))

        let position = CombinedTextPosition(location: location, relativePosition: relativePosition)

        self.init(position)
    }
}
