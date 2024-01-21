import ExtensionKit
import Foundation
import SwiftUI

import Extendable

/// The extension point identifiers supported by Chime
public enum ChimeExtensionPoint: String, CaseIterable, Hashable, Codable, Sendable {
    case nonui = "com.chimehq.Edit.extension"
    case sidebarUI = "com.chimehq.Edit.extension.ui.sidebar"
    case documentSyncedUI = "com.chimehq.Edit.extension.ui.document-synced"
}

/// A base protocol for all Chime extensions.
///
/// This protocol defines the minimal functionality needed to interact
/// with the Chime extension system.
@available(macOS 13.0, *)
@MainActor
public protocol ChimeExtension: ExtensionProtocol, AppExtension {
	/// Called to establish the global communication channel to the hosting application
	///
	/// When this is called, you can store the `host` value for later use, or
	/// simply ignore it if that isn't needed. This method will only be called
	/// once per extension instance.
	func acceptHostConnection(_ host: HostProtocol) throws
}

@available(macOS 13.0, *)
extension ChimeExtension {
	var globalConfiguration: ConnectingAppExtensionConfiguration {
		return ConnectingAppExtensionConfiguration { connection in
			let remoteHost = RemoteHost(connection: connection)

			self.export(over: connection, host: remoteHost)

			try self.acceptHostConnection(remoteHost)
		}
	}

	public nonisolated var configuration: ConnectingAppExtensionConfiguration {
		MainActor.runUnsafely {
			return globalConfiguration
		}
	}
}

@available(macOS 13.0, *)
@MainActor
public protocol SidebarChimeUIExtension<Scene>: ChimeExtension {
    associatedtype Scene: ChimeExtensionScene
	
    var scene: Scene { get }
}

@available(macOS 13.0, *)
extension SidebarChimeUIExtension {
	public nonisolated var configuration: AppExtensionSceneConfiguration {
		MainActor.runUnsafely {
			return AppExtensionSceneConfiguration(self.scene, configuration: globalConfiguration)
		}
    }
}

@available(macOS 13.0, *)
@MainActor
public protocol DocumentSyncedChimeUIExtension<Scene>: ChimeExtension {
	associatedtype Scene: ChimeExtensionScene

	var scene: Scene { get }
}

@available(macOS 13.0, *)
extension DocumentSyncedChimeUIExtension {
	public var configuration: AppExtensionSceneConfiguration {
		MainActor.runUnsafely {
			return AppExtensionSceneConfiguration(self.scene, configuration: globalConfiguration)
		}
	}
}
