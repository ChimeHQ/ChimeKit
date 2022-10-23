import Foundation
import ChimeKit
import ProcessServiceContainer
import ChimeSwift

@main
final class SwiftStandaloneExtension: ChimeExtension {
    private var chimeExt: SwiftExtension?

    required init() {
        ServiceContainer.bootstrap()
    }

    func acceptHostConnection(_ host: HostProtocol) throws {
    }
}
