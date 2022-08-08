import Foundation

public protocol FormattingService {
    func formatting(for ranges: [CombinedTextRange]) async throws -> [TextChange]
    func organizeImports() async throws -> [TextChange]
}
