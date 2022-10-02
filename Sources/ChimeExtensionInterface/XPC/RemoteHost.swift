import Foundation

import ConcurrencyPlus

final class RemoteHost {
    private let connection: NSXPCConnection

    public init(_ connection: NSXPCConnection) {
        self.connection = connection

        precondition(connection.remoteObjectInterface == nil)
        connection.remoteObjectInterface = NSXPCInterface(with: HostXPCProtocol.self)
    }

    private func withContinuation<T>(function: String = #function, _ body: (HostXPCProtocol, CheckedContinuation<T, Error>) -> Void) async throws -> T {
        return try await connection.withContinuation(body)
    }

    private func withService(function: String = #function, _ body: (HostXPCProtocol) -> Void) async throws {
        try await connection.withService(body)
    }
}

extension RemoteHost: HostProtocol {
    public func textContent(for documentId: DocumentIdentity) async throws -> (String, Int) {
        return try await withContinuation({ host, continuation in
            host.textContent(for: documentId) { value, version, error in
                let pair: (String, Int)? = value.map { ($0, version) }

                continuation.resume(with: pair, error: error)
            }
        })
    }

    public func textContent(for documentId: DocumentIdentity, in range: TextRange) async throws -> CombinedTextContent {
        let xpcRange = try JSONEncoder().encode(range)

        return try await withContinuation({ host, continuation in
            host.textContent(for: documentId, xpcRange: xpcRange, reply: continuation.resumingHandler)
        })
    }

    public func textBounds(for documentId: DocumentIdentity, in ranges: [TextRange], version: Int) async throws -> [NSRect] {
        let xpcRanges = try JSONEncoder().encode(ranges)

        return try await withContinuation({ host, continuation in
            host.textBounds(for: documentId, xpcRanges: xpcRanges, version: version, reply: continuation.resumingHandler)
        })
    }

    public func publishDiagnostics(_ diagnostics: [Diagnostic], for documentURL: URL, version: Int?) {
        Task {
            let xpcDiagnostics = try JSONEncoder().encode(diagnostics)
            let xpcVersion = version.flatMap({ NSNumber(integerLiteral: $0) })

            try await withService({ host in
                host.publishDiagnostics(xpcDiagnostics, for: documentURL, version: xpcVersion)
            })
        }
    }

    public func invalidateTokens(for documentId: UUID, in target: TextTarget) {
        Task {
            let xpcTarget = try JSONEncoder().encode(target)

            try await withService({ host in
                host.invalidateTokens(for: documentId, in: xpcTarget)
            })
        }
    }

    public func documentServiceConfigurationChanged(for documentId: DocumentIdentity, to configuration: ServiceConfiguration) {
        Task {
            let xpcConfig = try JSONEncoder().encode(configuration)

            try await withService({ host in
                host.documentServiceConfigurationChanged(for: documentId, to: xpcConfig)
            })
        }
    }
}
