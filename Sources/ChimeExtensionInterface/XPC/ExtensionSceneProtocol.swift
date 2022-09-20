import Foundation

public protocol ExtensionSceneProtocol {
    func setActiveContext(project: ProjectContext?, document: DocumentContext?) async throws
}

public protocol ExtensionSceneHostProtocol {

}
