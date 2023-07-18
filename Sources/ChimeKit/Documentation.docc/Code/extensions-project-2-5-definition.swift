import Foundation
import ChimeKit

public final class SwiftExtension {
    let host: any HostProtocol

    public init(host: any HostProtocol) {
        self.host = host
    }
}

extension SwiftExtension: ExtensionProtocol {
    public var configuration: ExtensionConfiguration {
        get throws { throw ChimeExtensionError.unsupported }
    }

    public var applicationService: ApplicationService {
        get throws { throw ChimeExtensionError.unsupported }
    }
}
