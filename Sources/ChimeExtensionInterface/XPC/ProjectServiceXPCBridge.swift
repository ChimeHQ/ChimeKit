import Foundation

//import ExtensionInterface

public actor ProjectServiceXPCBridge {
    let protocolObject: ExtensionXPCProtocol
    let context: ProjectContext

    init(protocolObject: ExtensionXPCProtocol, context: ProjectContext) {
        self.protocolObject = protocolObject
        self.context = context
    }
}

extension ProjectServiceXPCBridge: SymbolQueryService {
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
