import Foundation
import OSLog

import Queue

/// XPC -> Extension
@MainActor
final class ExportedExtension<Extension: ExtensionProtocol>: ExtensionXPCProtocol {
    private let bridgedObject: Extension
    private let logger = Logger(subsystem: "com.chimehq.ChimeKit", category: "ExportedExtension")
	private let queuedRelay: QueuedRelay
    private var documentServices = [DocumentIdentity: any DocumentService]()
	private let host: RemoteHost

	init(_ object: Extension, host: RemoteHost) {
        self.bridgedObject = object
		self.host = host
		self.queuedRelay = QueuedRelay(attributes: [.concurrent])
    }

	private var appService: some ApplicationService {
		get throws  {
			try bridgedObject.applicationService
		}
	}

	private func documentService(for xpcContext: XPCDocumentContext) throws -> (some DocumentService)? {
		let context = try JSONDecoder().decode(DocumentContext.self, from: xpcContext)
		return try appService.documentService(for: context)
	}

    private func resolveBookmarkData(_ bookmarkData: [Data]) {
        for data in bookmarkData {
            var stale: Bool = false

            do {
                let _ = try URL(resolvingBookmarkData: data,
                                  options: [.withoutUI],
                                  relativeTo: nil,
                                  bookmarkDataIsStale: &stale)
            } catch {
				logger.error("failed to resolve bookmark: \(error, privacy: .public)")
            }
        }
    }

	func configuration(completionHandler: @escaping XPCValueHandler<XPCExtensionConfiguration>) {
		queuedRelay.addEncodingOperation(with: completionHandler) {
			try self.bridgedObject.configuration
		}
	}

    func didOpenProject(with xpcContext: XPCProjectContext, bookmarkData: [Data]) {
		queuedRelay.addOperation(barrier: true) {
			let context = try JSONDecoder().decode(ProjectContext.self, from: xpcContext)

			self.resolveBookmarkData(bookmarkData)

			try self.appService.didOpenProject(with: context)
		}
    }

	func willCloseProject(with xpcContext: XPCProjectContext) {
		queuedRelay.addOperation(barrier: true) {
			let context = try JSONDecoder().decode(ProjectContext.self, from: xpcContext)

			try self.appService.willCloseProject(with: context)
		}
    }

    func didOpenDocument(with xpcContext: XPCDocumentContext, bookmarkData: [Data]) {
		queuedRelay.addOperation(barrier: true) {
			let context = try JSONDecoder().decode(DocumentContext.self, from: xpcContext)

			self.resolveBookmarkData(bookmarkData)

			try self.appService.didOpenDocument(with: context)
		}
    }

    func didChangeDocumentContext(from xpcOldContext: XPCDocumentContext, to xpcNewContext: XPCDocumentContext) {
		queuedRelay.addOperation(barrier: true) {
			let oldContext = try JSONDecoder().decode(DocumentContext.self, from: xpcOldContext)
			let newContext = try JSONDecoder().decode(DocumentContext.self, from: xpcNewContext)

			precondition(oldContext.id == newContext.id)

			try self.appService.didChangeDocumentContext(from: oldContext, to: newContext)
		}
    }

    func willCloseDocument(with xpcContext: XPCDocumentContext) {
		queuedRelay.addOperation(barrier: true) {
			let context = try JSONDecoder().decode(DocumentContext.self, from: xpcContext)

			try self.appService.willCloseDocument(with: context)
		}
    }

    func willApplyChange(with xpcContext: XPCDocumentContext, xpcChange: Data) {
		queuedRelay.addOperation(barrier: true) {
			let change = try JSONDecoder().decode(CombinedTextChange.self, from: xpcChange)

			try self.documentService(for: xpcContext)?.willApplyChange(change)
		}
    }

    func didApplyChange(with xpcContext: XPCDocumentContext, xpcChange: Data) {
		queuedRelay.addOperation(barrier: true) {
			let change = try JSONDecoder().decode(CombinedTextChange.self, from: xpcChange)

			try self.documentService(for: xpcContext)?.didApplyChange(change)
		}
    }

    func willSave(with xpcContext: XPCDocumentContext, completionHandler: @escaping XPCHandler) {
		queuedRelay.addErrorOperation(with: completionHandler) {
			let service = try self.documentService(for: xpcContext)
			
			try service?.willSave()
		}
    }

    func didSave(with xpcContext: XPCDocumentContext) {
		queuedRelay.addOperation {
			let service = try self.documentService(for: xpcContext)

			try service?.didSave()
		}
    }

	func launchedProcessTerminated(with id: UUID) {
		queuedRelay.addOperation(barrier: true) {
			try self.host.handleProcessTerminated(with: id)
		}
	}

	func symbols(forProject xpcContext: XPCProjectContext, matching query: String, completionHandler: @escaping XPCValueHandler<XPCArray<XPCSymbol>>) {
		queuedRelay.addEncodingOperation(with: completionHandler) {
			let context = try JSONDecoder().decode(ProjectContext.self, from: xpcContext)
			let service = try self.appService.symbolService(for: context)

			return try await service?.symbols(matching: query) ?? []
		}
    }

    func completions(for xpcContext: XPCDocumentContext, at xpcPosition: XPCCombinedTextPosition, xpcTrigger: XPCCompletionTrigger, completionHandler: @escaping XPCValueHandler<Data>) {
		queuedRelay.addEncodingOperation(with: completionHandler) {
			let service = try self.documentService(for: xpcContext)?.completionService
			let position = try JSONDecoder().decode(CombinedTextPosition.self, from: xpcPosition)
			let trigger = try JSONDecoder().decode(CompletionTrigger.self, from: xpcTrigger)

			return try await service?.completions(at: position, trigger: trigger) ?? []
		}
    }

    func formatting(for xpcContext: XPCDocumentContext, for xpcRanges: XPCArray<XPCCombinedTextRange>, completionHandler: @escaping XPCValueHandler<XPCArray<XPCTextChange>>) {
		queuedRelay.addEncodingOperation(with: completionHandler) {
			let service = try self.documentService(for: xpcContext)?.formattingService
			let ranges = try JSONDecoder().decode([CombinedTextRange].self, from: xpcRanges)

			return try await service?.formatting(for: ranges)
		}
    }

    func organizeImports(for xpcContext: XPCDocumentContext, completionHandler: @escaping XPCValueHandler<XPCArray<XPCTextChange>>) {
		queuedRelay.addEncodingOperation(with: completionHandler) {
			let service = try self.documentService(for: xpcContext)?.formattingService

			return try await service?.organizeImports()
		}
    }

    func semanticDetails(for xpcContext: XPCDocumentContext, at xpcPosition: XPCCombinedTextPosition, completionHandler: @escaping XPCValueHandler<XPCSemanticDetails>) {
		queuedRelay.addEncodingOperation(with: completionHandler) {
			let position = try JSONDecoder().decode(CombinedTextPosition.self, from: xpcPosition)
			let service = try self.documentService(for: xpcContext)?.semanticDetailsService

			return try await service?.semanticDetails(at: position)
		}
    }

    func findDefinition(for xpcContext: XPCDocumentContext, at xpcPosition: XPCCombinedTextPosition, completionHandler: @escaping XPCValueHandler<XPCArray<XPCDefinitionLocation>>) {
		queuedRelay.addEncodingOperation(with: completionHandler) {
			let position = try JSONDecoder().decode(CombinedTextPosition.self, from: xpcPosition)
			let service = try self.documentService(for: xpcContext)?.defintionService

			return try await service?.definitions(at: position) ?? []
		}
    }

    func tokens(for xpcContext: XPCDocumentContext, in xpcRange: XPCCombinedTextRange, completionHandler: @escaping XPCValueHandler<XPCArray<XPCToken>>) {
		queuedRelay.addEncodingOperation(with: completionHandler) {
			let range = try JSONDecoder().decode(CombinedTextRange.self, from: xpcRange)
			let service = try self.documentService(for: xpcContext)?.tokenService

			return try await service?.tokens(in: range) ?? []
		}
    }

    func symbols(forDocument xpcContext: XPCDocumentContext, matching query: String, completionHandler: @escaping XPCValueHandler<XPCArray<XPCSymbol>>) {
		queuedRelay.addEncodingOperation(with: completionHandler) {
			let service = try self.documentService(for: xpcContext)?.symbolService

			return try await service?.symbols(matching: query)
		}
    }
}
