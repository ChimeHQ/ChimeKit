import Foundation
import UniformTypeIdentifiers

/// Describe a type of document.
///
/// This is needed because UTIs cannot quite sufficiently describe
/// all possible interesting document types. An example is Rust's "Cargo.toml".
public enum DocumentType: Codable, Hashable, Sendable {
	case uti(UTType)
	case fileName(String)
}

/// Static configuration for a Chime extension.
public struct ExtensionConfiguration: Codable, Hashable, Sendable {
	/// Describes the documents that this extension operates on.
	///
	/// Empty means no documents, nil means all. This is an optimization hint
	/// to the system. Filtered document events can will be relayed so that
	/// the extension can see the true state of a project.
	public var documentFilter: Set<DocumentType>?

	/// Describes the project directory contents that this extension operates on.
	///
	/// Empty means no documents, nil means all. This is an optimization hint
	/// to the system. You should still be prepared to handle filtered events, so
	/// that the system can present the true state of a project.
	public var directoryContentFilter: Set<DocumentType>?

	public init(documentFilter: Set<DocumentType>? = nil, directoryContentFilter: Set<DocumentType>? = nil) {
		self.documentFilter = documentFilter
		self.directoryContentFilter = directoryContentFilter
	}
}

public extension ExtensionConfiguration {
	/// Check if a DocumentContext is being filtered
	func isDocumentIncluded(_ context: DocumentContext) -> Bool {
		guard let set = documentFilter else { return true }

		for docType in set {
			switch docType {
			case .fileName(let name):
				if context.url?.lastPathComponent == name {
					return true
				}
			case .uti(let utType):
				if context.uti.conforms(to: utType) {
					return true
				}
			}
		}

		return false
	}

	/// Check if a directory is being filtered
	func isDirectoryIncluded(at url: URL) throws -> Bool {
		guard let set = directoryContentFilter else { return true }

		let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.contentTypeKey])

		for url in contents {
			let resourceValues = try url.resourceValues(forKeys: [.contentTypeKey])

			for docType in set {
				switch docType {
				case .fileName(let name):
					if url.lastPathComponent == name {
						return true
					}
				case .uti(let utType):
					guard let uti = resourceValues.contentType else { continue }

					let resolved = UTType.resolveType(with: uti.identifier, url: url) ?? uti
					
					if resolved.conforms(to: utType) {
						return true
					}
				}
			}
		}

		return false
	}
}
