import Foundation

public protocol FormattingService {
	@MainActor
    func formatting(for ranges: [CombinedTextRange]) async throws -> [TextChange]
	@MainActor
    func organizeImports() async throws -> [TextChange]
}
