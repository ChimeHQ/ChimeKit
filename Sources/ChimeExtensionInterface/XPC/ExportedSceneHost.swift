import Foundation

//import ExtensionInterface

public final class ExportedSceneHost<Host: ExtensionSceneHostProtocol>: ExtensionSceneHostXPCProtocol {
    let host: Host

    public init(_ host: Host) {
        self.host = host
    }

    func textBounds(xpcRanges: XPCArray<XPCTextRange>, version: Int, reply: @escaping (XPCArray<NSRect>?, Error?) -> Void) {
        reply(nil, XPCBridgeError.unsupported)
    }
}
