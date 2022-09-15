import Foundation

@_implementationOnly import ConcurrencyPlus

public final class RemoteScene {
    private let connection: NSXPCConnection

    public init(connection: NSXPCConnection) {
        self.connection = connection

		precondition(connection.remoteObjectInterface == nil)
		connection.remoteObjectInterface = NSXPCInterface(with: ExtensionSceneXPCProtocol.self)
    }
}

extension RemoteScene: ExtensionSceneProtocol {
    public func setActiveContext(project: ProjectContext?, document: DocumentContext) async throws {
        let xpcProjectContext = try project.map { try JSONEncoder().encode($0) }
        let xpcDocumentContext = try JSONEncoder().encode(document)

        try await self.connection.withContinuation { (service: ExtensionSceneXPCProtocol, continuation) in
            service.setActiveContext(project: xpcProjectContext, document: xpcDocumentContext, reply: continuation.resumingHandler)
        }
    }
}
