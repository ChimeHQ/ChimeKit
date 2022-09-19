import ExtensionKit
import Foundation
import SwiftUI

import Extendable

/// Identifier used to distinuish scenes provided by an extension.
///
/// Learn more about ChimeKit User Interfaces: <doc:UserInterfaces>
public enum ChimeExtensionSceneIdentifier: String, CaseIterable, Hashable, Codable, Sendable {
    case main
}

/// Base protocol used by all Chime extension scenes.
///
/// Learn more about ChimeKit User Interfaces: <doc:UserInterfaces>
@available(macOS 13.0, *)
public protocol ChimeExtensionScene: AppExtensionScene {
}

@available(macOS 13.0, *)
extension AppExtensionSceneGroup: ChimeExtensionScene {
}

/// A fixed editor sidebar view.
///
/// This scene will be displayed for all document/project combinations,
/// including ones where no document and/or project is defined.
///
/// This scene will define two values available in the SwiftUI Environment,
/// `documentContext` and `projectContext`. It uses the scene id
/// corresponding to `ChimeExtensionSceneIdentifier.main`.
///
/// Learn more about ChimeKit User Interfaces: <doc:UserInterfaces>
@available(macOS 13.0, *)
public struct SidebarScene<Content: View>: ChimeExtensionScene {
    private let content: () -> Content

    public init(content: @escaping () ->  Content) {
        self.content = content
    }

    public var body: some AppExtensionScene {
		ConnectingAppExtensionScene(sceneID: ChimeExtensionSceneIdentifier.main.rawValue) { _, connection in
			SceneContextView(connection: connection, content)
		}
    }
}

/// An editor sidebar view with a horizontal size kept in sync with the current document.
///
/// This scene will be displayed for all document/project combinations,
/// including ones where no document and/or project is defined.
///
/// This scene will define two values available in the SwiftUI Environment,
/// `documentContext` and `projectContext`. It uses the scene id
/// corresponding to `ChimeExtensionSceneIdentifier.main`.
///
/// Learn more about ChimeKit User Interfaces: <doc:UserInterfaces>
@available(macOS 13.0, *)
public struct DocumentSyncedScene<Content: View>: ChimeExtensionScene {
	private let content: () -> Content

	public init(content: @escaping () ->  Content) {
		self.content = content
	}

	public var body: some AppExtensionScene {
		ConnectingAppExtensionScene(sceneID: ChimeExtensionSceneIdentifier.main.rawValue) { _, connection in
			SceneContextView(connection: connection, content)
		}
	}
}
