import Foundation

/// XPC -> Host
public final class XPCHostBridge<Host: HostProtocol>: HostXPCProtocol {
    let bridgedObject: Host

    init(_ object: Host) {
        self.bridgedObject = object
    }

    func textContent(for id: UUID, reply: @escaping (String?, Int, Error?) -> Void) {
        Task {
            do {
                let pair = try await self.bridgedObject.textContent(for: id)

                reply(pair.0, pair.1, nil)
            } catch {
                reply(nil, 0, error)
            }
        }
    }

    func textContent(for id: UUID, xpcRange: XPCTextRange, reply: @escaping XPCValueHandler<XPCTextContent>) {
        Task {
            do {
                let range = try JSONDecoder().decode(TextRange.self, from: xpcRange)
                let value = try await self.bridgedObject.textContent(for: id, in: range)

                let xpcContent = try JSONEncoder().encode(value)

                reply(xpcContent, nil)
            } catch {
                reply(nil, error)
            }
        }
    }

    func textBounds(for id: UUID, xpcRanges: Data, version: Int, reply: @escaping (Data?, Error?) -> Void) {
        Task {
            do {
                let ranges = try JSONDecoder().decode([TextRange].self, from: xpcRanges)
                let value = try await self.bridgedObject.textBounds(for: id, in: ranges, version: version)

                let data = try JSONEncoder().encode(value)

                reply(data, nil)
            } catch {
                reply(nil, error)
            }
        }
    }

    func publishDiagnostics(_ xpcDiagnostics: XPCArray<XPCDiagnostic>, for documentURL: URL, version: NSNumber?) {
        Task {
            do {
                let diagnostics = try JSONDecoder().decode([Diagnostic].self, from: xpcDiagnostics)

                self.bridgedObject.publishDiagnostics(diagnostics, for: documentURL, version: version?.intValue)
            } catch {
                fatalError("publishDiagnostics: \(error)")
            }
        }
    }

    func invalidateTokens(for documentId: UUID, in xpcTarget: XPCTextTarget) {
        Task {
            do {
                let target = try JSONDecoder().decode(TextTarget.self, from: xpcTarget)

                self.bridgedObject.invalidateTokens(for: documentId, in: target)
            } catch {
                fatalError("publishDiagnostics: \(error)")
            }
        }
    }

    func documentServiceConfigurationChanged(for documentId: UUID, to xpcConfiguration: XPCDocumentServiceConfiguration) {
        guard let config = try? JSONDecoder().decode(ServiceConfiguration.self, from: xpcConfiguration) else {
            return
        }

        self.bridgedObject.documentServiceConfigurationChanged(for: documentId, to: config)
    }
}
