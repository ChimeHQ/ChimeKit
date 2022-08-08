import Foundation

//import ExtensionInterface

@objc(CodingProjectContext)
public final class CodingProjectContext: NSObject {
    public let value: ProjectContext

    public init(_ value: ProjectContext) {
        self.value = value
    }
}

extension CodingProjectContext: NSSecureCoding {
    public static var supportsSecureCoding: Bool {
        return true
    }

    public func encode(with coder: NSCoder) {
        coder.encode(value.id as NSUUID, forKey: "id")
        coder.encode(value.url as NSURL, forKey: "url")
    }

    public convenience init?(coder: NSCoder) {
        guard
            let id = coder.decodeObject(of: NSUUID.self, forKey: "id") as? UUID,
            let url = coder.decodeObject(of: NSURL.self, forKey: "url") as? URL
        else {
            return nil
        }

        let value = ProjectContext(id: id, url: url)

        self.init(value)
    }
}
