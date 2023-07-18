import Foundation
import ChimeKit

public final class SwiftExtension {
    let host: any HostProtocol
    private let lspService: LSPService
    
    public init(host: any HostProtocol) {
        self.host = host
        
        self.lspService = LSPService(host: host,
                                     executionParamsProvider: SwiftExtension.provideParams)
    }
}

extension SwiftExtension {
    private static func provideParams() throws -> Process.ExecutionParameters {
        return .init(path: "/usr/bin/sourcekit-lsp")
    }
}

extension SwiftExtension: ExtensionProtocol {
    public var configuration: ExtensionConfiguration {
        get throws {
            ExtensionConfiguration(contentFilter: [.uti(.swiftSource)])
        }
    }
    
    public var applicationService: ApplicationService {
        get throws { try lspService.applicationService }
    }
}
