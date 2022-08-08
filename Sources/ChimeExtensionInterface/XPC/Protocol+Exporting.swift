import Foundation

//import ExtensionInterface

extension HostProtocol {
    public func export(over connection: NSXPCConnection) {
        precondition(connection.exportedInterface == nil)

        connection.exportedInterface = NSXPCInterface(with: HostXPCProtocol.self)
        connection.exportedObject = XPCHostBridge(self)
    }
}

extension ExtensionProtocol {
    public func export(over connection: NSXPCConnection) {
        precondition(connection.exportedInterface == nil)

        connection.exportedInterface = NSXPCInterface(with: ExtensionXPCProtocol.self)
        connection.exportedObject = XPCExtensionBridge(self)
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
