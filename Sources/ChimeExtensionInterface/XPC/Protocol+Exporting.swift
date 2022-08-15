import Foundation

extension HostProtocol {
    public func export(over connection: NSXPCConnection) {
        precondition(connection.exportedInterface == nil)

        connection.exportedInterface = NSXPCInterface(with: HostXPCProtocol.self)
        connection.exportedObject = ExportedHost(self)
    }
}

extension ExtensionProtocol {
    public func export(over connection: NSXPCConnection) {
        precondition(connection.exportedInterface == nil)

        connection.exportedInterface = NSXPCInterface(with: ExtensionXPCProtocol.self)
        connection.exportedObject = ExportedExtension(self)
    }
}

extension ExtensionSceneProtocol {
    public func export(over connection: NSXPCConnection) {
        precondition(connection.exportedInterface == nil)

        connection.exportedInterface = NSXPCInterface(with: ExtensionSceneXPCProtocol.self)
        connection.exportedObject = ExportedScene(self)
    }
}

extension ExtensionSceneHostProtocol {
    public func export(over connection: NSXPCConnection) {
        precondition(connection.exportedInterface == nil)

        connection.exportedInterface = NSXPCInterface(with: ExtensionSceneHostXPCProtocol.self)
        connection.exportedObject = ExportedSceneHost(self)
    }
}
