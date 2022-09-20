import Foundation
import ChimeKit
import ChimeSwift

@main
final class SwiftStandaloneExtension: ChimeExtension {
    private var chimeExt: SwiftExtension?

    required init() {
    }

    func acceptHostConnection(_ host: HostProtocol) throws {
        self.chimeExt = SwiftExtension(host: host)
    }
}
