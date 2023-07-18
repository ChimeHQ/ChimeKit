import Foundation
import ChimeKit
import ChimeSwift

@main
final class SwiftStandaloneExtension: ChimeExtension {
    private let localExtension: StandaloneExtension<SwiftExtension>

    required init() {
    }

    func acceptHostConnection(_ host: HostProtocol) throws {
    }
}
