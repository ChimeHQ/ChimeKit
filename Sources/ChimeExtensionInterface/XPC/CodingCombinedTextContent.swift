import Foundation

//import ExtensionInterface

@objc(CodingCombinedTextContent)
public final class CodingCombinedTextContent: NSObject {
    public let value: CombinedTextContent

    public init(_ value: CombinedTextContent) {
        self.value = value
    }
}

extension CodingCombinedTextContent: NSSecureCoding {
    public static var supportsSecureCoding: Bool {
        return true
    }

    public func encode(with coder: NSCoder) {
        coder.encode(value.string, forKey: "string")
        coder.encode(CodingCombinedTextRange(value.range), forKey: "range")
    }

    public convenience init?(coder: NSCoder) {
        guard
            let string = coder.decodeObject(of: NSString.self, forKey: "string") as String?,
            let range = coder.decodeObject(of: CodingCombinedTextRange.self, forKey: "range")
        else {
            return nil
        }

        let content = CombinedTextContent(string: string, range: range.value)

        self.init(content)
    }
}
