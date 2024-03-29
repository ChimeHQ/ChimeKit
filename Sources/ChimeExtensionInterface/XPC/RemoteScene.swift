import Foundation

import AsyncXPCConnection

/// Connect to a `ChimeExtensionScene` over XPC.
@MainActor
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

		try await self.connection.withErrorCompletion { (service: ExtensionSceneXPCProtocol, handler) in
			service.setActiveContext(project: xpcProjectContext, document: xpcDocumentContext, reply: handler)
		}
    }
}
