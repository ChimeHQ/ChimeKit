# The Extension System

Learn about what extension can do, the environment they run in, and how they are built.

## Overview

ExtensionKit vs ExtensionProtocol.

## Using ExtensionKit

<doc:ExtensionKit>

## Extension Points

Extension capabilities are defined by their application extension point.

Extension Point | Description
--- | ---
`com.chimehq.Edit.extension` | Functional and semantic features.
`com.chimehq.Edit.extension.ui.sidebar` | Displays a fixed-sidebar view.
`com.chimehq.Edit.extension.ui.document-synced` | Displays a view synchronized to the current document.

UI-based extensions define their view in terms of scenes which conform to ``ChimeExtensionScene``. ChimeKit includes predefined scenes that you can use. There are two types of supported views an extension can display: fixed-sidebar and documented-synced.

## Basic Extension

The most basic extension uses ``ExtensionProtocol`` to interact with the editor and provide services.

Extension point: `com.chimehq.Edit.extension`

## Basic Extension Example

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

