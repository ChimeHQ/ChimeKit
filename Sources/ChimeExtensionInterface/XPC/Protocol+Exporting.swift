import Foundation

extension HostProtocol {
	@MainActor
	public func export(over connection: NSXPCConnection, remoteExtension: RemoteExtension) {
        precondition(connection.exportedInterface == nil)

        connection.exportedInterface = NSXPCInterface(with: HostXPCProtocol.self)
		connection.exportedObject = ExportedHost(self, remoteExtension: remoteExtension)
    }
}

extension ExtensionProtocol {
	@MainActor
	func export(over connection: NSXPCConnection, host: RemoteHost) {
        precondition(connection.exportedInterface == nil)

        connection.exportedInterface = NSXPCInterface(with: ExtensionXPCProtocol.self)
		connection.exportedObject = ExportedExtension(self, host: host)
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
