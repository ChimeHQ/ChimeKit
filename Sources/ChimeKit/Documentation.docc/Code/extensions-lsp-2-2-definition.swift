import Foundation
import ChimeKit

public final class SwiftExtension {
    let host: any HostProtocol

    public init(host: any HostProtocol) {
        self.host = host
    }
}

extension SwiftExtension {
    private static func provideParams() throws -> Process.ExecutionParameters {
        return .init(path: "/usr/bin/sourcekit-lsp")
    }
}

public extension SwiftExtension: ExtensionProtocol {
}
