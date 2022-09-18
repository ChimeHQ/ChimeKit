import Foundation
import os.log

@_implementationOnly import ConcurrencyPlus

/// XPC -> Extension
final class ExportedExtension<Extension: ExtensionProtocol>: ExtensionXPCProtocol {
    private let bridgedObject: Extension
    private let log: OSLog
    private let queue: TaskQueue
    private var documentServices: [DocumentIdentity: DocumentService]

    init(_ object: Extension) {
        self.bridgedObject = object
        self.log = OSLog(subsystem: "com.chimehq.ChimeKit", category: "ExportedExtension")
        self.queue = TaskQueue()
        self.documentServices = [:]
    }

    private func resolveBookmarkData(_ bookmarkData: [Data]) {
        for data in bookmarkData {
            var stale: Bool = false

            do {
                let url = try URL(resolvingBookmarkData: data,
                                  options: [.withoutUI],
                                  relativeTo: nil,
                                  bookmarkDataIsStale: &stale)

                os_log("accessing the url: %{public}@", log: self.log, type: .info, String(describing: url))
            } catch {
                os_log("failed to resolve bookmark: %{public}@", log: self.log, type: .error, String(describing: error))
            }
        }
    }

    func didOpenProject(with xpcContext: XPCProjectContext, bookmarkData: [Data]) {
        let obj = self.bridgedObject

        queue.addOperation {
            do {
                let context = try JSONDecoder().decode(ProjectContext.self, from: xpcContext)

                self.resolveBookmarkData(bookmarkData)

                try await obj.didOpenProject(with: context)
            } catch {
                os_log("didOpenProject failed: %{public}@", log: self.log, type: .error, String(describing: error))
            }
        }
    }

    func willCloseProject(with xpcContext: XPCProjectContext) {
        let obj = self.bridgedObject

        queue.addOperation {
            do {
                let context = try JSONDecoder().decode(ProjectContext.self, from: xpcContext)
                try await obj.willCloseProject(with: context)
            } catch {
                os_log("willCloseProject failed: %{public}@", log: self.log, type: .error, String(describing: error))
            }
        }
    }

    func didOpenDocument(with xpcContext: XPCDocumentContext, bookmarkData: [Data], completionHandler: @escaping XPCValueHandler<URL>) {
        os_log("didOpenDoc", log: self.log, type: .info)

        let context: DocumentContext

        do {
            context = try JSONDecoder().decode(DocumentContext.self, from: xpcContext)
        } catch {
            os_log("caught failure %{public}@", log: self.log, type: .info, String(describing: error))
            completionHandler(nil, error)
            return
        }

        let obj = self.bridgedObject

        queue.addOperation {
            do {
                self.resolveBookmarkData(bookmarkData)

                let url = try await obj.didOpenDocument(with: context)

                os_log("didOpenDoc completed", log: self.log, type: .info)
                completionHandler(url, nil)
            } catch {
                os_log("caught task failure %{public}@", log: self.log, type: .info, String(describing: error))
                completionHandler(nil, error)
            }
        }
    }

    func didChangeDocumentContext(from xpcOldContext: XPCDocumentContext, to xpcNewContext: XPCDocumentContext, completionHandler: @escaping XPCHandler) {
        let oldContext: DocumentContext
        let newContext: DocumentContext

        do {
            oldContext = try JSONDecoder().decode(DocumentContext.self, from: xpcOldContext)
            newContext = try JSONDecoder().decode(DocumentContext.self, from: xpcNewContext)
        } catch {
            completionHandler(error)
            return
        }

        precondition(oldContext.id == newContext.id)

        let obj = self.bridgedObject

        queue.addOperation {
            do {
                try await obj.didChangeDocumentContext(from: oldContext, to: newContext)

                completionHandler(nil)
            } catch {
                completionHandler(error)
            }
        }
    }

    func willCloseDocument(with context: XPCDocumentContext) {
    }

    func willApplyChange(with xpcContext: XPCDocumentContext, xpcChange: Data) {
        let context: DocumentContext
        let change: CombinedTextChange

        do {
            context = try JSONDecoder().decode(DocumentContext.self, from: xpcContext)
            change = try JSONDecoder().decode(CombinedTextChange.self, from: xpcChange)
        } catch {
            return
        }

        let obj = self.bridgedObject

        queue.addOperation {
            do {
                let service = try await obj.documentService(for: context)

                try await service?.willApplyChange(change)
            } catch {
                os_log("willApplyChange failure %{public}@", log: self.log, type: .info, String(describing: error))
            }
        }
    }

    func didApplyChange(with xpcContext: XPCDocumentContext, xpcChange: Data) {
        let context: DocumentContext
        let change: CombinedTextChange

        do {
            context = try JSONDecoder().decode(DocumentContext.self, from: xpcContext)
            change = try JSONDecoder().decode(CombinedTextChange.self, from: xpcChange)
        } catch {
            return
        }

        let obj = self.bridgedObject

        queue.addOperation {
            do {
                let service = try await obj.documentService(for: context)

                try await service?.didApplyChange(change)
            } catch {
                os_log("didApplyChange failure: %{public}@", log: self.log, type: .info, String(describing: error))
            }
        }
    }

    func willSave(with xpcContext: XPCDocumentContext, completionHandler: @escaping XPCHandler) {
        let context: DocumentContext

        do {
            context = try JSONDecoder().decode(DocumentContext.self, from: xpcContext)
        } catch {
            completionHandler(error)
            return
        }

        let obj = self.bridgedObject

        queue.addOperation {
            do {
                let service = try await obj.documentService(for: context)
                try await service?.willSave()

                completionHandler(nil)
            } catch {
                completionHandler(error)
            }
        }
    }

    func didSave(with xpcContext: XPCDocumentContext, completionHandler: @escaping XPCHandler) {
        let context: DocumentContext

        do {
            context = try JSONDecoder().decode(DocumentContext.self, from: xpcContext)
        } catch {
            completionHandler(error)
            return
        }

        let obj = self.bridgedObject

        queue.addOperation {
            do {
                let service = try await obj.documentService(for: context)
                try await service?.didSave()

                completionHandler(nil)
            } catch {
                completionHandler(error)
            }
        }
    }

    func symbols(forProject xpcContext: XPCProjectContext, matching query: String, completionHandler: @escaping XPCValueHandler<XPCArray<XPCSymbol>>) {
        let obj = self.bridgedObject

        queue.addOperation {
            do {
                let context = try JSONDecoder().decode(ProjectContext.self, from: xpcContext)
                let service = try await obj.symbolService(for: context)
                let symbols = try await service?.symbols(matching: query) ?? []
                let symbolData = try JSONEncoder().encode(symbols)

                completionHandler(symbolData, nil)
            } catch {
                completionHandler(nil, error)
            }
        }
    }

    func completions(for xpcContext: XPCDocumentContext, at xpcPosition: XPCCombinedTextPosition, xpcTrigger: XPCCompletionTrigger, completionHandler: @escaping XPCValueHandler<Data>) {
        let obj = self.bridgedObject

        queue.addOperation {
            do {
                let context = try JSONDecoder().decode(DocumentContext.self, from: xpcContext)
                let position = try JSONDecoder().decode(CombinedTextPosition.self, from: xpcPosition)
                let trigger = try JSONDecoder().decode(CompletionTrigger.self, from: xpcTrigger)
                let docService = try await obj.documentService(for: context)
                let service = try await docService?.completionService
                let completions = try await service?.completions(at: position, trigger: trigger) ?? []
                let data = try JSONEncoder().encode(completions)

                completionHandler(data, nil)
            } catch {
                completionHandler(nil, error)
            }
        }
    }

    func formatting(for xpcContext: XPCDocumentContext, for xpcRanges: XPCArray<XPCCombinedTextRange>, completionHandler: @escaping XPCValueHandler<XPCArray<XPCTextChange>>) {
		queue.addOperation {
			do {
				let ranges = try JSONDecoder().decode([CombinedTextRange].self, from: xpcRanges)
				let service = try await self.documentService(for: xpcContext)?.formattingService
				let value = try await service?.formatting(for: ranges)
				let data = try JSONEncoder().encode(value)

				completionHandler(data, nil)

			} catch {
				completionHandler(nil, error)
			}
		}
    }

    func organizeImports(for xpcContext: XPCDocumentContext, completionHandler: @escaping XPCValueHandler<XPCArray<XPCTextChange>>) {
		queue.addOperation {
			do {
				let service = try await self.documentService(for: xpcContext)?.formattingService
				let value = try await service?.organizeImports()
				let data = try JSONEncoder().encode(value)

				completionHandler(data, nil)

			} catch {
				completionHandler(nil, error)
			}
		}
    }

    func semanticDetails(for xpcContext: XPCDocumentContext, at xpcPosition: XPCCombinedTextPosition, completionHandler: @escaping XPCValueHandler<XPCSemanticDetails>) {
		queue.addOperation {
			do {
				let position = try JSONDecoder().decode(CombinedTextPosition.self, from: xpcPosition)
				let service = try await self.documentService(for: xpcContext)?.semanticDetailsService
				let value = try await service?.semanticDetails(at: position)
				let data = try JSONEncoder().encode(value)

				completionHandler(data, nil)

			} catch {
				completionHandler(nil, error)
			}
		}
    }

    func findDefinition(for xpcContext: XPCDocumentContext, at xpcPosition: XPCCombinedTextPosition, completionHandler: @escaping XPCValueHandler<XPCArray<XPCDefinitionLocation>>) {
        queue.addOperation {
            do {
                let position = try JSONDecoder().decode(CombinedTextPosition.self, from: xpcPosition)
                let service = try await self.documentService(for: xpcContext)?.defintionService
                let defs = try await service?.definitions(at: position) ?? []
                let data = try JSONEncoder().encode(defs)

                completionHandler(data, nil)

            } catch {
                completionHandler(nil, error)
            }
        }
    }

    func tokens(for xpcContext: XPCDocumentContext, in xpcRange: XPCCombinedTextRange, completionHandler: @escaping XPCValueHandler<XPCArray<XPCToken>>) {
        queue.addOperation {
            do {
                let range = try JSONDecoder().decode(CombinedTextRange.self, from: xpcRange)
                let service = try await self.documentService(for: xpcContext)?.tokenService
                let tokens = try await service?.tokens(in: range) ?? []
                let data = try JSONEncoder().encode(tokens)

                completionHandler(data, nil)
            } catch {
                completionHandler(nil, error)
            }
        }
    }

    func symbols(forDocument xpcContext: XPCDocumentContext, matching query: String, completionHandler: @escaping XPCValueHandler<XPCArray<XPCSymbol>>) {
		queue.addOperation {
			do {
				let service = try await self.documentService(for: xpcContext)?.symbolService
				let value = try await service?.symbols(matching: query)
				let data = try JSONEncoder().encode(value)

				completionHandler(data, nil)
			} catch {
				completionHandler(nil, error)
			}
		}
    }
}

extension ExportedExtension {
    private func documentService(for xpcContext: XPCDocumentContext) async throws -> DocumentService? {
        let context = try JSONDecoder().decode(DocumentContext.self, from: xpcContext)

        return try await self.bridgedObject.documentService(for: context)
    }
}
