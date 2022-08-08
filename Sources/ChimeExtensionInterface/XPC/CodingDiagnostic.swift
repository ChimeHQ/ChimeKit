import Foundation

//import ExtensionInterface

@objc(CodingDiagnostic)
public final class CodingDiagnostic: NSObject {
    public let value: Diagnostic

    public init(_ value: Diagnostic) {
        self.value = value
    }
}

fileprivate extension Diagnostic.Kind {
    init?(_ codingValue: Int) {
        switch codingValue {
        case 1:
            self = .hint
        case 2:
            self = .information
        case 3:
            self = .warning
        case 4:
            self = .error
        default:
            return nil
        }
    }
    var codingValue: Int {
        switch self {
        case .hint:
            return 1
        case .information:
            return 2
        case .warning:
            return 3
        case .error:
            return 4
        }
    }
}

extension CodingDiagnostic: NSSecureCoding {
    public static var supportsSecureCoding: Bool {
        return true
    }

    public func encode(with coder: NSCoder) {
        coder.encode(CodingTextRange(value.range), forKey: "range")
        coder.encode(value.message, forKey: "message")
        coder.encode(value.kind.codingValue, forKey: "kind")

        assert(value.qualifiers.isEmpty)
        assert(value.relationships.isEmpty)
    }

    public convenience init?(coder: NSCoder) {
        guard
            let range = coder.decodeObject(of: CodingTextRange.self, forKey: "range"),
            let message = coder.decodeObject(of: NSString.self, forKey: "message") as String?,
            let kind = Diagnostic.Kind(coder.decodeInteger(forKey: "kind"))
        else {
            return nil
        }

        let value = Diagnostic(range: range.value,
                               message: message,
                               kind: kind,
                               relationships: [],
                               qualifiers: Set())

        self.init(value)
    }
}

