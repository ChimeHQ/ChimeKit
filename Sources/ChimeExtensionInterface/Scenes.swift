import Foundation
import ExtensionKit
import SwiftUI
import os.log

//import ExtensionXPCInterface

public enum ChimeExtensionSceneName: String, CaseIterable, Hashable, Codable, Sendable {
    case sidebar
    case documentSynced
}

@available(macOS 13.0, *)
struct BaseExtensionScene<Content: View>: AppExtensionScene {
    let sceneName: ChimeExtensionSceneName
    private let content: () -> Content
    private let contextView: SceneContextView<Content>

    init(sceneName: ChimeExtensionSceneName, content: @escaping () -> Content) {
        self.sceneName = sceneName
        self.content = content
        self.contextView = SceneContextView(content: content)
    }

    var body: some AppExtensionScene {
        PrimitiveAppExtensionScene(id: sceneName.rawValue) {
            contextView
        } onConnection: { connection in
            self.contextView.docModel.export(over: connection)

            connection.activate()

            return true
        }
    }
}

@available(macOS 13.0, *)
public protocol ChimeExtensionScene: AppExtensionScene {}

@available(macOS 13.0, *)
public struct SidebarScene<Content: View>: ChimeExtensionScene {
    private let content: () -> Content

    public init(content: @escaping () ->  Content) {
        self.content = content
    }

    public var body: some AppExtensionScene {
        BaseExtensionScene(sceneName: .sidebar, content: content)
    }
}

@available(macOS 13.0, *)
public struct DocumentSyncedScene<Content: View>: ChimeExtensionScene {
    private let content: () -> Content

    public init(content: @escaping () ->  Content) {
        self.content = content
    }

    public var body: some AppExtensionScene {
        BaseExtensionScene(sceneName: .documentSynced, content: content)
    }
}
