import Foundation

@MainActor
final class ExportedScene<Scene: ExtensionSceneProtocol>: ExtensionSceneXPCProtocol {
    let scene: Scene

    init(_ scene: Scene) {
        self.scene = scene
    }

    func setActiveContext(project xpcProjectContext: XPCProjectContext?, document xpcDocumentContext: XPCDocumentContext?, reply: @escaping (Error?) -> Void) {
        Task {
            do {
                let projectContext = try xpcProjectContext.map { try JSONDecoder().decode(ProjectContext.self, from: $0) }
                let documentContext = try xpcDocumentContext.map { try JSONDecoder().decode(DocumentContext.self, from: $0) }

                try await self.scene.setActiveContext(project: projectContext, document: documentContext)

                reply(nil)
            } catch {
                reply(error)
            }
        }
    }
}
