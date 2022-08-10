import Foundation

@_implementationOnly import ConcurrencyPlus
//import ExtensionInterface

public final class RemoteScene {
    private let connection: NSXPCConnection

    public init(connection: NSXPCConnection) {
        self.connection = connection
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
