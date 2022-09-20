import Foundation

@_implementationOnly import ConcurrencyPlus

/// Connect to a `ChimeExtensionScene` over XPC.
public final class RemoteScene {
    private let connection: NSXPCConnection

    public init(connection: NSXPCConnection) {
        self.connection = connection

		precondition(connection.remoteObjectInterface == nil)
		connection.remoteObjectInterface = NSXPCInterface(with: ExtensionSceneXPCProtocol.self)
    }
}

extension RemoteScene: ExtensionSceneProtocol {
    public func setActiveContext(project: ProjectContext?, document: DocumentContext?) async throws {
        let xpcProjectContext = try project.map { try JSONEncoder().encode($0) }
        let xpcDocumentContext = try document.map { try JSONEncoder().encode($0) }

        try await self.connection.withContinuation { (service: ExtensionSceneXPCProtocol, continuation) in
            service.setActiveContext(project: xpcProjectContext, document: xpcDocumentContext, reply: continuation.resumingHandler)
        }
    }
}
