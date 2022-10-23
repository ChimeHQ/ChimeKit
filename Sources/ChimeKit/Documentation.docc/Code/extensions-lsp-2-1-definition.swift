import Foundation
import ChimeKit

public final class SwiftExtension {
    let host: any HostProtocol

    public init(host: any HostProtocol, processHostServiceName: String?) {
        self.host = host
    }
}

extension SwiftExtension: ExtensionProtocol {
}
