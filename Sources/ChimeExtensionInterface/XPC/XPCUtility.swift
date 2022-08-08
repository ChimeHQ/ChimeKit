import Foundation

typealias XPCReply = (Error?) -> Void
typealias XPCValueReply<T> = (T?, Error?) -> Void
