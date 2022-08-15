import Foundation

public final class RemoteProjectService {
	private let connection: NSXPCConnection
    let context: ProjectContext

    init(connection: NSXPCConnection, context: ProjectContext) {
        self.connection = connection
        self.context = context
    }
}

extension RemoteProjectService: SymbolQueryService {
    public func symbols(matching query: String) async throws -> [Symbol] {
//        let obj = protocolObject
//        let xpcContext = CodingProjectContext(context)
//
//        return try await withCheckedThrowingContinuation({ continuation in
//            obj.symbols(forProject: xpcContext, matching: query) { data, error in
//                continuation.resume(with: data, error: error)
//            }
//        })
        return []
    }
}
