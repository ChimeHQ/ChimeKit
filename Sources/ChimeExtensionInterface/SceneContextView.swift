import Combine
import Foundation
import SwiftUI

@MainActor
final class SceneContextViewModel: ObservableObject {
    @Published public private(set) var projectContext: ProjectContext?
	@Published public private(set) var documentContext: DocumentContext?

    init() {
    }
}

extension SceneContextViewModel: ExtensionSceneProtocol {
    public func setActiveContext(project: ProjectContext?, document: DocumentContext?) {
        self.projectContext = project
        self.documentContext = document
    }
}

public struct DocumentContextKey: EnvironmentKey {
	public static let defaultValue: DocumentContext? = nil
}

public struct ProjectContextKey: EnvironmentKey {
	public static let defaultValue: ProjectContext? = nil
}

public extension EnvironmentValues {
	/// The active `DocumentContext` for the current view.
    var documentContext: DocumentContext? {
        get { self[DocumentContextKey.self] }
        set { self[DocumentContextKey.self] = newValue }
    }

	/// The active `ProjectContext` for the current view.
	///
	/// Keep in mind that not all situations will have an
	/// associated project.
    var projectContext: ProjectContext? {
        get { self[ProjectContextKey.self] }
        set { self[ProjectContextKey.self] = newValue }
    }
}

@available(macOS 13.0, *)
struct SceneContextView<Content: View>: View {
	@ObservedObject private var model = SceneContextViewModel()

	let connection: NSXPCConnection?
	private let content: () -> Content

	init(connection: NSXPCConnection?, _ content: @escaping () -> Content) {
		self.connection = connection
		self.content = content

		if let conn = connection {
			model.export(over: conn)
		}
	}

	var body: some View {
		VStack {
			content()
				.environment(\.documentContext, model.documentContext)
				.environment(\.projectContext, model.projectContext)
		}
	}
}

