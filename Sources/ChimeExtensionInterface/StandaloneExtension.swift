import Foundation

public final class StandaloneExtension<Extension: ExtensionProtocol> {
	public typealias ExtensionProvider = (HostProtocol) throws -> Extension

	private let extensionProvider: ExtensionProvider
	private var wrappedExtension: Extension?

	public init(extensionProvider: @escaping ExtensionProvider) {
		self.extensionProvider = extensionProvider
	}

	public func acceptHostConnection(_ host: HostProtocol) throws {
		self.wrappedExtension = try extensionProvider(host)
	}
}

extension StandaloneExtension: ExtensionProtocol {
	public var configuration: ExtensionConfiguration {
		get throws {
			guard let wrappedExtension else { throw ChimeExtensionError.noHostConnection }

			return try wrappedExtension.configuration
		}
	}

	public var applicationService: some ApplicationService {
		get throws {
			guard let wrappedExtension else { throw ChimeExtensionError.noHostConnection }
			
			return try wrappedExtension.applicationService
		}
	}
}
