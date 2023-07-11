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
