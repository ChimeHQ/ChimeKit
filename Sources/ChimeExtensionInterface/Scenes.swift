import ExtensionKit
import Foundation
import SwiftUI

import Extendable

/// Identifier used to distinuish scenes provided by an extension.
public enum ChimeExtensionSceneIdentifier: String, CaseIterable, Hashable, Codable, Sendable {
	case main
}

/// Base protocol used by all Chime extension scenes.
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
@available(macOS 13.0, *)
@MainActor
public struct SidebarScene<Content: View>: ChimeExtensionScene {
	private let content: () -> Content

	public init(content: @escaping () ->  Content) {
		self.content = content
	}

	public nonisolated var body: some AppExtensionScene {
		MainActor.runUnsafely {
			ConnectingAppExtensionScene(sceneID: ChimeExtensionSceneIdentifier.main.rawValue) { _, connection in
				SceneContextView(connection: connection, content)
			}
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
@available(macOS 13.0, *)
@MainActor
public struct DocumentSyncedScene<Content: View>: ChimeExtensionScene {
	private let content: () -> Content

	public init(content: @escaping () ->  Content) {
		self.content = content
	}

	public nonisolated var body: some AppExtensionScene {
		MainActor.runUnsafely {
			ConnectingAppExtensionScene(sceneID: ChimeExtensionSceneIdentifier.main.rawValue) { _, connection in
				SceneContextView(connection: connection, content)
			}
		}
	}
}
