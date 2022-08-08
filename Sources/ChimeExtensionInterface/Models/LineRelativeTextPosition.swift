import Foundation

public struct LineRelativeTextPosition: Codable, Hashable, Sendable {
    public let line: Int
    public let offset: Int

    public init(line: Int, offset: Int) {
        self.line = line
        self.offset = offset
    }

//    public init?(location: Int, lineService: LineProvider) {
//        guard let position = lineService.computeLineRelativePosition(at: location) else {
//            return nil
//        }
//
//        self.init(line: position.line, offset: position.offset)
//    }
}

extension LineRelativeTextPosition: Comparable {
    public static func < (lhs: LineRelativeTextPosition, rhs: LineRelativeTextPosition) -> Bool {
        if lhs.line == rhs.line {
            return lhs.offset < rhs.offset
        }

        return lhs.line < rhs.line
    }
}

extension LineRelativeTextPosition: CustomStringConvertible {
    public var description: String {
        return "{\(line) + \(offset)}"
    }
}
