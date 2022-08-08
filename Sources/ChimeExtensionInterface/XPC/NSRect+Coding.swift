import Foundation

//extension NSRect: Codable {
//    public init(from decoder: Decoder) throws {
//        var container = try decoder.unkeyedContainer()
//
//        let point = CGPoint(x: try container.decode(Double.self),
//                            y: try container.decode(Double.self))
//
//        let size = CGSize(width: try container.decode(Double.self),
//                          height: try container.decode(Double.self))
//
//        self.init(origin: point, size: size)
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.unkeyedContainer()
//
//        try container.encode(self.origin.x)
//        try container.encode(self.origin.y)
//        try container.encode(self.size.height)
//        try container.encode(self.size.width)
//    }
//}
