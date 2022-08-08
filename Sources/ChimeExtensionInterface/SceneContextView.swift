import Combine
import Foundation
import SwiftUI
import os.log

//import ExtensionInterface

@MainActor
public final class DocumentModel: ObservableObject {
    let log = OSLog(subsystem: "com.chimehq.ChimeKit", category: "DocumentModel")

    @Published public private(set) var documentContext: DocumentContext

    var hostApp: HostProtocol?

    init(documentContext: DocumentContext) {
        self.documentContext = documentContext
    }

    public func getLine() async -> NSRect {
        let range = TextRange.lineRelativeRange(LineRelativeTextPosition(line: 45, offset: 8)..<LineRelativeTextPosition(line: 45, offset: 27))
        let docId = documentContext.id
        
        return await Task {
            do {
                let value = try await hostApp?.textBounds(for: docId, in: [range], version: 1)

                os_log("task done: %{public}@", log: log, type: .error, String(describing: value))

                return value?.first ?? .zero
            } catch {
                os_log("task failed: %{public}@", log: log, type: .error, String(describing: error))
            }

            return .zero
        }.value
    }
}

extension DocumentModel: ExtensionSceneProtocol {
    public func setActiveContext(project: ProjectContext?, document: DocumentContext) async throws {
        self.documentContext = document
    }
}

@MainActor
final class SceneContextViewModel: ObservableObject {
    static let defaultContext = DocumentContext()

    @Published public private(set) var projectContext: ProjectContext?
    @Published public private(set) var documentContext = SceneContextViewModel.defaultContext

    init() {
    }
}

extension SceneContextViewModel: ExtensionSceneProtocol {
    public func setActiveContext(project: ProjectContext?, document: DocumentContext) {
        self.projectContext = project
        self.documentContext = document
    }
}

public struct DocumentContextKey: EnvironmentKey {
    public static var defaultValue = SceneContextViewModel.defaultContext
}

public struct ProjectContextKey: EnvironmentKey {
    public static var defaultValue: ProjectContext? = nil
}

public extension EnvironmentValues {
    var documentContext: DocumentContext {
        get { self[DocumentContextKey.self] }
        set { self[DocumentContextKey.self] = newValue }
    }

    var projectContext: ProjectContext? {
        get { self[ProjectContextKey.self] }
        set { self[ProjectContextKey.self] = newValue }
    }
}

@available(macOS 13.0, *)
public struct SceneContextView<Content: View>: View {
    @ObservedObject var model = SceneContextViewModel()
    @ObservedObject var docModel = DocumentModel(documentContext: DocumentContext())

    private let content: () -> Content

    public init(content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        content()
            .environment(\.documentContext, model.documentContext)
            .environment(\.projectContext, model.projectContext)
            .environmentObject(docModel)
    }
}
