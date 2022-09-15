import XCTest
@testable import ChimeExtensionInterface

@available(macOS 13.0, *)
final class ExampleNonUIExtension: ChimeExtension {
	func acceptHostConnection(_ host: HostProtocol) throws {
	}

	var scene: some NewChimeExtensionScene { return UnsupportedScene.all }
}

final class ChimeExtensionTests: XCTestCase {
	func testNonUIExtension() {

	}
}
