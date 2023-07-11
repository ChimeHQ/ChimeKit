import Foundation
import ChimeKit
import ProcessServiceContainer
import ChimeSwift

@main
final class SwiftStandaloneExtension: ChimeExtension {
    private let localExtension: StandaloneExtension<SwiftExtension>

    required init() {
        ServiceContainer.bootstrap()

        self.localExtension = StandaloneExtension(extensionProvider: { host in
            SwiftExtension(host: host, processHostServiceName: ServiceContainer.name)
        })
    }

    func acceptHostConnection(_ host: HostProtocol) throws {
        try localExtension.acceptHostConnection(host)
    }
}

extension SwiftStandaloneExtension {
    var configuration: ExtensionConfiguration {
        get throws { try localExtension.configuration }
    }

    var applicationService: ApplicationService {
        get throws { try localExtension.applicationService }
    }
}
