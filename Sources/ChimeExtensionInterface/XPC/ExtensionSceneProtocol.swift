import Foundation

public protocol ExtensionSceneProtocol {
	@MainActor
    func setActiveContext(project: ProjectContext?, document: DocumentContext?) async throws
}

public protocol ExtensionSceneHostProtocol {

}
