import Foundation

//import LineTracker

public struct CombinedTextRange: Codable, Hashable, @unchecked Sendable {
    public let version: Int
    public let range: NSRange
    public let lineRelativeRange: LineRelativeTextRange
    public let limit: Int

    public init(version: Int, range: NSRange, lineRelativeRange: LineRelativeTextRange, limit: Int) {
        self.version = version
        self.range = range
        self.lineRelativeRange = lineRelativeRange
        self.limit = limit
    }

//    public init?(range: NSRange, length: Int, version: Int, lineService: LineProvider) {
//        let lowerBound = LineRelativeTextPosition(line: 0, offset: 0)
//        guard let upperBound = lineService.computeLineRelativePosition(at: length) else {
//            return nil
//        }
//
//        self = CombinedTextRange(version: version,
//                                 range: range,
//                                 lineRelativeRange: lowerBound..<upperBound,
//                                 limit: length)
//    }
}
