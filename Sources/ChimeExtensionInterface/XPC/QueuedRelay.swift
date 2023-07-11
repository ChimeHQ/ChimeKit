import Foundation

import Queue

/// More convenient interface between an AsyncQueue and callback-based systems.
struct QueuedRelay {
	public let queue: AsyncQueue

	public init(queue: AsyncQueue) {
		self.queue = queue
	}

	public init(attributes: AsyncQueue.Attributes) {
		self.queue = AsyncQueue(attributes: attributes)
	}

	@discardableResult
	public func addOperation(
		priority: TaskPriority? = nil,
		barrier: Bool = false,
		@_inheritActorContext operation: @escaping @Sendable () async throws -> Void
	) -> Task<Void, Error> {
		queue.addOperation(priority: priority, barrier: barrier) {
			try await operation()
		}
	}

	@discardableResult
	public func addErrorOperation(
		priority: TaskPriority? = nil,
		barrier: Bool = false,
		with callback: @escaping @Sendable (Error?) -> Void,
		@_inheritActorContext operation: @escaping @Sendable () async throws -> Void
	) -> Task<Void, Error> {
		queue.addOperation(priority: priority, barrier: barrier) {
			do {
				try await operation()

				callback(nil)
			} catch {
				callback(error)
				throw error
			}
		}
	}

	@discardableResult
	public func addValueErrorOperation<Value: Sendable>(
		priority: TaskPriority? = nil,
		barrier: Bool = false,
		with callback: @escaping @Sendable (Value?, Error?) -> Void,
		@_inheritActorContext operation: @escaping @Sendable () async throws -> Value
	) -> Task<Value, Error> {
		queue.addOperation(priority: priority, barrier: barrier) {
			do {
				let value = try await operation()

				callback(value, nil)

				return value
			} catch {
				callback(nil, error)
				throw error
			}
		}
	}

	@discardableResult
	public func addEncodingOperation<Value: Encodable & Sendable>(
		priority: TaskPriority? = nil,
		barrier: Bool = false,
		with callback: @escaping @Sendable (Data?, Error?) -> Void,
		@_inheritActorContext operation: @escaping @Sendable () async throws -> Value
	) -> Task<Value, Error> {
		queue.addOperation(priority: priority, barrier: barrier) {
			do {
				let value = try await operation()
				let data = try JSONEncoder().encode(value)

				callback(data, nil)

				return value
			} catch {
				callback(nil, error)
				throw error
			}
		}
	}
}
