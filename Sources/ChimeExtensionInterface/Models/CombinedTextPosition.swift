import Foundation

//import LineTracker

public struct CombinedTextPosition: Codable, Hashable, Sendable {
    public let location: Int
    public let relativePosition: LineRelativeTextPosition

    public init(location: Int, relativePosition: LineRelativeTextPosition) {
        self.location = location
        self.relativePosition = relativePosition
    }

//    public init?(location: Int, lineService: LineProvider) {
//        guard let position = LineRelativeTextPosition(location: location, lineService: lineService) else {
//            return nil
//        }
//
//        self.init(location: location, relativePosition: position)
//    }
}

extension CombinedTextPosition: Comparable {
    public static func < (lhs: CombinedTextPosition, rhs: CombinedTextPosition) -> Bool {
        return lhs.location < rhs.location
    }
}
