import Foundation

@MainActor
struct RemoteProjectService {
	private let queuedService: RemoteExtension.Service
    let context: ProjectContext

	init(queuedService: RemoteExtension.Service, context: ProjectContext) {
        self.queuedService = queuedService
        self.context = context
    }
}

extension RemoteProjectService: SymbolQueryService {
    public func symbols(matching query: String) async throws -> [Symbol] {
        let xpcContext = try JSONEncoder().encode(context)

		return try await queuedService.addDecodingOperation { service, handler in
			service.symbols(forProject: xpcContext, matching: query, completionHandler: handler)
		}
    }
}
