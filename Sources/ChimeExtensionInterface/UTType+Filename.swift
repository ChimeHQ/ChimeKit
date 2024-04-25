import Foundation
import UniformTypeIdentifiers

public extension UTType {
	/// Resolves a UTI by considering both an identifier name and the file's URL
	///
	/// This is needed for things like "Makefile", which do not use any of the standard
	/// UTI mechanisms for recognizing a file's type.
	@available(*, deprecated, message: "Use URL.resolvedContentType instead.")
	static func resolveTypeName(_ name: String, url: URL) -> String {
		(try? url.resolvedContentType)?.identifier ?? name
	}
	
	/// Resolves a UTType by considering both an identifier name and the file's URL
	///
	/// See `resolveTypeName(_:, url:)`
	@available(*, deprecated, message: "Use URL.resolvedContentType instead.")
	static func resolveType(with name: String, url: URL) -> UTType? {
		(try? url.resolvedContentType) ?? UTType(name)
	}
}

extension URL {
	/// Get the contentType as defined by `URLResourceKey.contentTypeKey`.
	public var contentType: UTType? {
		get throws {
			try resourceValues(forKeys: [.contentTypeKey]).contentType
		}
	}

	/// Resolve the content type UTI by taking into account the file's URL.
	///
	/// See `nameBasedContentType` for more details.
	public var resolvedContentType: UTType? {
		get throws {
			try nameBasedContentType ?? contentType
		}
	}

	/// Resolves a UTI by considering the file's URL
	///
	/// This is needed for things like "Makefile", which do not use any of the standard UTI mechanisms for recognizing a file's type.
	public var nameBasedContentType: UTType? {
		switch lastPathComponent.lowercased() {
		case "gemfile", "fastfile", "podfile", "rakefile":
			return UTType.rubyScript
		case "config":
			if absoluteString.hasSuffix(".ssh/config") {
				return UTType.sshConfigurationFile
			}
		case "dockerfile":
			return UTType.dockerfile
		default:
			break
		}

		return nil
	}
}
