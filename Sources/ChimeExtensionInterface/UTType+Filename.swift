import Foundation
import UniformTypeIdentifiers

public extension UTType {
	/// Resolves a UTI by considering both an identifier name and the file's URL
	///
	/// This is needed for things like "Makefile", which do not use any of the standard
	/// UTI mechanisms for recognizing a file's type.
	static func resolveTypeName(_ name: String, url: URL) -> String {
		switch url.lastPathComponent.lowercased() {
		case "gemfile", "fastfile", "podfile", "rakefile":
			return UTType.rubyScript.identifier
		case "config":
			if url.absoluteString.hasSuffix(".ssh/config") {
				return UTType.sshConfigurationFile.identifier
			}
		default:
			break
		}

		return name
	}
	
	/// Resolves a UTType by considering both an identifier name and the file's URL
	///
	/// See `resolveTypeName(_:, url:)`
	static func resolveType(with name: String, url: URL) -> UTType? {
		let typeName = resolveTypeName(name, url: url)

		return UTType(typeName)
	}
}
