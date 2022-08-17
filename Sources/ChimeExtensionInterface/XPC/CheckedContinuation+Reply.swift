import Foundation

@_implementationOnly import ConcurrencyPlus

extension CheckedContinuation where T: Decodable, E == Error {
    func resume(with data: Data?, error: Error?) {
        do {
			if let error = error { throw error }
			guard let data = data else { throw ConnectionContinuationError.missingBothValueAndError }

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
