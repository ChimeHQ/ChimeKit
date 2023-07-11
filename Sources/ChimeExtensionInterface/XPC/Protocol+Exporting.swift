import Foundation

extension HostProtocol {
	@MainActor
    public func export(over connection: NSXPCConnection) {
        precondition(connection.exportedInterface == nil)

        connection.exportedInterface = NSXPCInterface(with: HostXPCProtocol.self)
        connection.exportedObject = ExportedHost(self)
    }
}

extension ExtensionProtocol {
	@MainActor
    func export(over connection: NSXPCConnection) {
        precondition(connection.exportedInterface == nil)

        connection.exportedInterface = NSXPCInterface(with: ExtensionXPCProtocol.self)
        connection.exportedObject = ExportedExtension(self)
    }
}

extension ExtensionSceneProtocol {
	@MainActor
    func export(over connection: NSXPCConnection) {
        precondition(connection.exportedInterface == nil)

        connection.exportedInterface = NSXPCInterface(with: ExtensionSceneXPCProtocol.self)
        connection.exportedObject = ExportedScene(self)
    }
}

extension ExtensionSceneHostProtocol {
	@MainActor
    public func export(over connection: NSXPCConnection) {
        precondition(connection.exportedInterface == nil)

        connection.exportedInterface = NSXPCInterface(with: ExtensionSceneHostXPCProtocol.self)
        connection.exportedObject = ExportedSceneHost(self)
    }
}
