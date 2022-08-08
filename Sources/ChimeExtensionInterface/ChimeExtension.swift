import ExtensionKit
import Foundation
import SwiftUI

public enum ChimeExtensionPoint: String, CaseIterable, Hashable, Codable, Sendable {
    case nonui = "com.chimehq.Edit.extension"
    case sidebarUI = "com.chimehq.Edit.extension.ui.sidebar"
    case documentSyncedUI = "com.chimehq.Edit.extension.ui.document-synced"
}

public protocol ChimeBaseExtension : ExtensionProtocol {
    var hostApp: HostProtocol? { get set }
}

public struct ChimeExtensionConfiguration<Extension: ChimeBaseExtension>: AppExtensionConfiguration {
    let appExtension: Extension

    public init(_ appExtension: Extension) {
        self.appExtension = appExtension
    }

    /// Determine whether to accept the XPC connection from the host.
    public func accept(connection: NSXPCConnection) -> Bool {
        appExtension.export(over: connection)
        appExtension.hostApp = try? HostXPCBridge(connection)

        connection.activate()

        return true
    }
}

@available(macOS 13.0, *)
public protocol ChimeExtension : ChimeBaseExtension, AppExtension {
}

@available(macOS 13.0, *)
extension ChimeExtension {
    public var configuration: ChimeExtensionConfiguration<Self> {
        return ChimeExtensionConfiguration(self)
    }
}

@available(macOS 13.0, *)
public protocol SidebarChimeUIExtension : ChimeBaseExtension, AppExtension {
    associatedtype Body: View
    var body: Body { get }
}

@available(macOS 13.0, *)
extension SidebarChimeUIExtension {
    public var configuration: AppExtensionSceneConfiguration {
        let scene = BaseExtensionScene(sceneName: .sidebar) {
            self.body
        }

        return AppExtensionSceneConfiguration(scene, configuration: ChimeExtensionConfiguration(self))
    }
}

@available(macOS 13.0, *)
public protocol DocumentSyncedChimeUIExtension : ChimeBaseExtension, AppExtension {
    associatedtype Body: View
    var body: Body { get }
}

@available(macOS 13.0, *)
extension DocumentSyncedChimeUIExtension {
    public var configuration: AppExtensionSceneConfiguration {
        let scene = BaseExtensionScene(sceneName: .documentSynced) {
            self.body
        }

        return AppExtensionSceneConfiguration(scene, configuration: ChimeExtensionConfiguration(self))
    }
}
