import Foundation

@_implementationOnly import ConcurrencyPlus

public final class HostXPCBridge {
    let connection: NSXPCConnection
    private let remoteObject: HostXPCProtocol

    public init(_ connection: NSXPCConnection) throws {
        self.connection = connection

        precondition(connection.remoteObjectInterface == nil)
        connection.remoteObjectInterface = NSXPCInterface(with: HostXPCProtocol.self)

        let proxy = connection.remoteObjectProxyWithErrorHandler { error in
            print("proxy error: ", error)

            fatalError()
        }

        guard let protocolObj = proxy as? HostXPCProtocol else {
            throw XPCBridgeError.invalidInterface
        }

        self.remoteObject = protocolObj
    }
}

extension HostXPCBridge: HostProtocol {
    public func textContent(for documentId: DocumentIdentity) async throws -> (String, Int) {
        return try await withCancellingContinuation({ (continuation: CancellingContinuation<(String, Int)>) in
            self.remoteObject.textContent(for: documentId) { value, version, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let string = value else {
                    continuation.resume(throwing: XPCBridgeError.missingExpectedValue("textContent string"))
                    return
                }

                continuation.resume(returning: (string, version))
            }
        })
    }

    public func textContent(for documentId: DocumentIdentity, in range: TextRange) async throws -> CombinedTextContent {

        let xpcRange = try JSONEncoder().encode(range)

        return try await withCancellingContinuation({ continuation in
            self.remoteObject.textContent(for: documentId, xpcRange: xpcRange) { content, error in
                continuation.resume(with: content, error: error)
            }
        })
    }

    public func textBounds(for documentId: DocumentIdentity, in ranges: [TextRange], version: Int) async throws -> [NSRect] {

        let xpcRanges = try JSONEncoder().encode(ranges)

        return try await connection.withContinuation({ (service: HostXPCProtocol, continuation) in
            service.textBounds(for: documentId, xpcRanges: xpcRanges, version: version, reply: continuation.resumingHandler)
        })
    }

    public func publishDiagnostics(_ diagnostics: [Diagnostic], for documentURL: URL, version: Int?) {
        do {
            let xpcDiagnostics = try JSONEncoder().encode(diagnostics)
            let xpcVersion = version.flatMap({ NSNumber(integerLiteral: $0) })

            self.remoteObject.publishDiagnostics(xpcDiagnostics, for: documentURL, version: xpcVersion)
        } catch {
            fatalError()
        }
    }

    public func invalidateTokens(for documentId: UUID, in target: TextTarget) {
        do {
            let xpcTarget = try JSONEncoder().encode(target)

            self.remoteObject.invalidateTokens(for: documentId, in: xpcTarget)
        } catch {
            fatalError()
        }
    }

    public func documentServiceConfigurationChanged(for documentId: DocumentIdentity, to configuration: ServiceConfiguration) {
        do {
            let xpcConfig = try JSONEncoder().encode(configuration)

            self.remoteObject.documentServiceConfigurationChanged(for: documentId, to: xpcConfig)
        } catch {
            fatalError()
        }
    }
}
