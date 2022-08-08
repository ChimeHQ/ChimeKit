import Foundation

@_implementationOnly import ConcurrencyPlus
//import ExtensionInterface

public final class ExtensionXPCBridge {
    private let connection: NSXPCConnection
    private let remoteObject: ExtensionXPCProtocol
    private var docServices: [DocumentIdentity: DocumentServiceXPCBridge]
    private let queue: DispatchQueue

    public init(connection: NSXPCConnection) throws {
        self.connection = connection
        self.docServices = [:]
        self.queue = DispatchQueue(label: "com.chimehq.ChimeKit.RemoteExtension")

        precondition(connection.remoteObjectInterface == nil)
        connection.remoteObjectInterface = NSXPCInterface(with: ExtensionXPCProtocol.self)

        guard let protocolObj = connection.remoteObjectProxy as? ExtensionXPCProtocol else {
            throw XPCBridgeError.invalidInterface
        }

        self.remoteObject = protocolObj
    }

    private func documentServiceBridge(for context: DocumentContext) -> DocumentServiceXPCBridge {
        return queue.sync {
            if let service = docServices[context.id] {
                return service
            }

            let service = DocumentServiceXPCBridge(remoteObject: self.remoteObject, context: context)

            docServices[context.id] = service

            return service
        }
    }
}

extension ExtensionXPCBridge: ExtensionProtocol {
    public func didOpenProject(with context: ProjectContext) async throws {
        let bookmarks: [Data] = [
            try context.url.bookmarkData(),
        ]

        remoteObject.didOpenProject(with: CodingProjectContext(context), bookmarkData: bookmarks)
    }

    public func willCloseProject(with context: ProjectContext) async throws {
        remoteObject.willCloseProject(with: CodingProjectContext(context))
    }

    public func didOpenDocument(with context: DocumentContext) async throws -> URL? {
        let xpcContext = try JSONEncoder().encode(context)

        let bookmarks: [Data] = [
            try context.url?.bookmarkData(),
        ].compactMap({ $0 })

        return try await withCancellingContinuation({ continuation in
            self.remoteObject.didOpenDocument(with: xpcContext, bookmarkData: bookmarks, completionHandler: { url, error in
                // have to special-case this because of the allowed optional
                switch (url, error) {
                case (let url, nil):
                    continuation.resume(returning: url)
                case (_, let error?):
                    continuation.resume(throwing: error)
                }
            })
        })
    }

    public func didChangeDocumentContext(from oldContext: DocumentContext, to newContext: DocumentContext) async throws {
//        precondition(oldContext.id == newContext.id)
//
//        let xpcOldContext = try JSONEncoder().encode(oldContext)
//        let xpcNewContext = try JSONEncoder().encode(newContext)
//
//        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
//            self.remoteObject.didChangeDocumentContext(from: xpcOldContext, to: xpcNewContext, completionHandler: { error in
//                continuation.resume(with: error)
//            })
//        })
    }

    public func willCloseDocument(with context: DocumentContext) async throws {
        let xpcContext = try JSONEncoder().encode(context)

        self.remoteObject.willCloseDocument(with: xpcContext)
    }

    public func documentService(for context: DocumentContext) async throws -> DocumentService? {
        return documentServiceBridge(for: context)
    }

    public func symbolService(for context: ProjectContext) async throws -> SymbolQueryService? {
        return ProjectServiceXPCBridge(protocolObject: remoteObject, context: context)
    }
}
