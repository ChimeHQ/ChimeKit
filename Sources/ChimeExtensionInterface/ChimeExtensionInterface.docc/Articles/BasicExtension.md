# Making An Extension

Build a simple extension with no user interface.

## Overview

A UI is not required for a Chime extension. Language-level features can be provided by using the core interfaces to the host application.

Extension point: `com.chimehq.Edit.extension`

## Minimal Example

```swift
import Foundation

import ChimeKit

@main
final class NoUIExtension: ChimeExtension {
    required init() {
    }

    func acceptHostConnection(_ host: HostProtocol) throws {
    }

    func documentService(for context: DocumentContext) async throws -> DocumentService? {
        return self
    }
}

extension NoUIExtension: DocumentService {
    var completionService: CompletionService? {
        get async throws { return self }
    }
}

extension NoUIExtension: CompletionService {
    func completions(at position: CombinedTextPosition, trigger: CompletionTrigger) async throws -> [Completion] {
        let range = TextRange.range(NSRange(location: position.location, length: 0))
        let completion = Completion(displayString: "hello!", range: range, fragments: [])

        return [completion]
    }
}
```
