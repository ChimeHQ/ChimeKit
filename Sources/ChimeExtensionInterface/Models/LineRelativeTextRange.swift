import Foundation

public typealias LineRelativeTextRange = Range<LineRelativeTextPosition>

//extension LineRelativeTextRange {
//    public init?(range: NSRange, lineService: LineProvider) {
//        guard
//            let start = LineRelativeTextPosition(location: range.lowerBound, lineService: lineService),
//            let end = LineRelativeTextPosition(location: range.upperBound, lineService: lineService)
//        else {
//            return nil
//        }
//
//        self = start..<end
//    }
//}
