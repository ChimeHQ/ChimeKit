import Foundation

//import LineTracker

public enum TextRange: Codable, Hashable, @unchecked Sendable {
    case range(NSRange)
    case lineRelativeRange(LineRelativeTextRange)

//    public func resolve(with provider: LineProvider) -> NSRange? {
//        switch self {
//        case .range(let range):
//            return range
//        case .lineRelativeRange(let relativeRange):
//            guard
//                let start = provider.computeAbsoluteLocation(of: relativeRange.lowerBound),
//                let end = provider.computeAbsoluteLocation(of: relativeRange.upperBound)
//            else {
//                return nil
//            }
//
//            return NSRange(start..<end)
//        }
//    }
//
//    public func combinedRange(with provider: LineProvider, length: Int, version: Int) -> CombinedTextRange? {
//        guard let range = resolve(with: provider) else { return nil }
//
//        switch self {
//        case .range:
//            return CombinedTextRange(range: range, length: length, version: version, lineService: provider)
//        case .lineRelativeRange(let relativeRange):
//            return CombinedTextRange(version: version,
//                                     range: range,
//                                     lineRelativeRange: relativeRange,
//                                     limit: length)
//        }
//    }
}

