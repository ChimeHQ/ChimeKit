import Foundation

public final class ExportedSceneHost<Host: ExtensionSceneHostProtocol>: ExtensionSceneHostXPCProtocol {
    let host: Host

    public init(_ host: Host) {
        self.host = host
    }

    func textBounds(xpcRanges: XPCArray<XPCTextRange>, version: Int, reply: @escaping (XPCArray<NSRect>?, Error?) -> Void) {
		do {
			let rects = try JSONEncoder().encode([] as [NSRect])

			reply(rects, nil)
		} catch {
			reply(nil, error)
		}
    }
}
