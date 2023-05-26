import XCTest
import ChimeExtensionInterface

final class ExtensionConfigurationTests: XCTestCase {
	func testIncludesDirectoryWithDocumentFilterMatch() throws {
		let config = ExtensionConfiguration(documentFilter: [.fileName("abc")],
											directoryContentFilter: Set())

		let projectPath = NSTemporaryDirectory() + "/config_test_dir"
		let projectURL = try XCTUnwrap(URL(fileURLWithPath: projectPath, isDirectory: true))

		try? FileManager.default.removeItem(at: projectURL)
		try FileManager.default.createDirectory(at: projectURL, withIntermediateDirectories: true)

		XCTAssertFalse(try config.isDirectoryIncluded(at: projectURL))

		let fileURL = projectURL.appendingPathComponent("abc")

		try Data().write(to: fileURL)

		XCTAssertTrue(try config.isDirectoryIncluded(at: projectURL))
	}

	func testIncludesDirectoryWithAllMatch() throws {
		let config = ExtensionConfiguration(documentFilter: nil,
											directoryContentFilter: nil)

		let projectPath = NSTemporaryDirectory() + "/config_test_dir"
		let projectURL = try XCTUnwrap(URL(fileURLWithPath: projectPath, isDirectory: true))

		try? FileManager.default.removeItem(at: projectURL)
		try FileManager.default.createDirectory(at: projectURL, withIntermediateDirectories: true)

		XCTAssertTrue(try config.isDirectoryIncluded(at: projectURL))
	}
}
