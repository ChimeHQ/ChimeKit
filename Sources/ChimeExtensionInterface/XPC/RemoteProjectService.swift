import Foundation

final class RemoteProjectService {
	private let connection: NSXPCConnection
    let context: ProjectContext

    init(connection: NSXPCConnection, context: ProjectContext) {
        self.connection = connection
        self.context = context
    }
}

extension RemoteProjectService: SymbolQueryService {
    public func symbols(matching query: String) async throws -> [Symbol] {
        let xpcContext = try JSONEncoder().encode(context)

        return try await connection.withContinuation { (service: ExtensionXPCProtocol, continuation) in
            service.symbols(forProject: xpcContext, matching: query, completionHandler: continuation.resumingHandler)
        }
    }
}
