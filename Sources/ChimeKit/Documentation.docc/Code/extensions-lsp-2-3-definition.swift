import Foundation
import ChimeKit

public final class SwiftExtension {
    let host: any HostProtocol

    public init(host: any HostProtocol, processHostServiceName: String?) {
        self.host = host

        let filter = LSPService.contextFilter(for: [.swiftSource])
    }
}

extension SwiftExtension {
    private static func provideParams() throws -> Process.ExecutionParameters {
        return .init(path: "/usr/bin/sourcekit-lsp")
    }
}

extension SwiftExtension: ExtensionProtocol {
}
