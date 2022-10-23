import Foundation
import ChimeKit
import ProcessServiceContainer

@main
final class SwiftStandaloneExtension: ChimeExtension {
    required init() {
        ServiceContainer.bootstrap()
    }

    func acceptHostConnection(_ host: HostProtocol) throws {
    }
}
