import Foundation
import ChimeKit
import ChimeSwift

@main
final class SwiftStandaloneExtension: ChimeExtension {
    private let localExtension: StandaloneExtension<SwiftExtension>

    required init() {
        self.localExtension = StandaloneExtension(extensionProvider: { SwiftExtension(host: $0) })
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
