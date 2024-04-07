import Foundation

final class ExportedSceneHost<Host: ExtensionSceneHostProtocol>: ExtensionSceneHostXPCProtocol {
    let host: Host

    init(_ host: Host) {
        self.host = host
    }

	func textBounds(xpcRanges: XPCArray<XPCTextRange>, version: Int, reply: @escaping (XPCArray<CGRect>?, Error?) -> Void) {
		do {
			let rects = try JSONEncoder().encode([] as [CGRect])

			reply(rects, nil)
		} catch {
			reply(nil, error)
		}
    }
}
