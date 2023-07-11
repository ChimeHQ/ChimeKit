import Foundation
import ChimeKit
import ProcessServiceContainer
import ChimeSwift

@main
final class SwiftStandaloneExtension: ChimeExtension {
    private let localExtension: StandaloneExtension<SwiftExtension>

    required init() {
        ServiceContainer.bootstrap()
    }

    func acceptHostConnection(_ host: HostProtocol) throws {
    }
}
