import Foundation

//import ExtensionInterface

@objc(CodingTextChange)
public final class CodingTextChange: NSObject {
    public let value: TextChange

    public init(_ value: TextChange) {
        self.value = value
    }
}

extension CodingTextChange: NSSecureCoding {
    public static var supportsSecureCoding: Bool {
        return true
    }

    public func encode(with coder: NSCoder) {
        coder.encode(value.string, forKey: "string")
        coder.encode(value.textRange, forKey: "range")
    }

    public convenience init?(coder: NSCoder) {
        guard
            let string = coder.decodeObject(of: NSString.self, forKey: "string") as String?,
            let range = coder.decodeObject(of: CodingTextRange.self, forKey: "range")
        else {
            return nil
        }

        let value = TextChange(string: string, textRange: range.value)

        self.init(value)
    }
}

