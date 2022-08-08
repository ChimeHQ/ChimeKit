import Foundation

@_implementationOnly import ConcurrencyPlus

extension CancellingContinuation where T: Decodable {
    func resume(with data: Data?, error: Error?) {
        if let error = error {
            resume(throwing: error)
            return
        }

        guard let data = data else {
            resume(throwing: XPCBridgeError.missingExpectedValue("Codable data: \(T.self)"))
            return
        }

        do {
            let value = try JSONDecoder().decode(T.self, from: data)

            resume(returning: value)
        } catch {
            resume(throwing: error)
        }
    }
}

extension CheckedContinuation where T: Decodable, E == Error {
    func resume(with data: Data?, error: Error?) {
        if let error = error {
            resume(throwing: error)
            return
        }

        guard let data = data else {
            resume(throwing: XPCBridgeError.missingExpectedValue("Codable data: \(T.self)"))
            return
        }

        do {
            let value = try JSONDecoder().decode(T.self, from: data)

            resume(returning: value)
        } catch {
            resume(throwing: error)
        }
    }

    public var resumingHandler: (Data?, Error?) -> Void {
        return {
            self.resume(with: $0, error: $1)
        }
    }
}
