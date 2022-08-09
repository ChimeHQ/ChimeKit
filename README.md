[![License][license badge]][license]

# ChimeKit
Framework for building [Chime](https://www.chimehq.com) extensions.

## Overview

Chime's extensions are based on [ExtensionKit](https://developer.apple.com/documentation/extensionkit). They are written in Swift and SwiftUI, and use `async` extensively. For the most part, ChimeKit abstracts away all of the ExtensionKit details. You program against the ChimeKit APIs, not the ExtensionKit primitives. However, ExtensionKit does impose some requirements related to security and distribution you must be aware of.

### Sandboxing

ExtensionKit extensions **must** be sandboxed. ChimeKit manages all permissions for user-opened documents and directories transparently. However, running in a sandbox can make it impossible to host [Language Server Protocol](https://microsoft.github.io/language-server-protocol/) servers, which is one of the core use-cases for Chime extensions. ChimeKit includes a system for running executables outside of a sandbox. It is based on [ProcessService](https://github.com/ChimeHQ/ProcessService).

### Distribution

ExtensionKit extensions **must** be delivered within a wrapper application. You can definitely build this yourself, or even host a Chime extension within an existing application. However, if you don't want to be bothered with this, you can apply for inclusion into our Extension Gallery application. This is a first-party extension hosting-application. It will handle discovery and updates, and all open source extensions will be eligible for inclusion. This app will be open source, and its repo is forthcoming.

## Our Philosophy

We want to provide a simple user experience for extensions, particularly for language support. We don't think it's great to have four different extensions for one language. So, while we will not gatekeep, we'll have a very strong bias towards one extension per language.

Chime's core Go and Ruby support aren't yet open sourced, yet. But, we will be publishing them eventually. And, going forward, we will **always** begin work on new language support as open source projects.

## Integration

ChimeKit supports two different integration options, both available via SPM.

```swift
dependencies: [
    .package(url: "https://github.com/ChimeHQ/ChimeKit")
]
```

This package includes the modules `ChimeExtensionInterface`, `ChimeLSPAdapter` which you can use directly. These do not provide out-of-sandbox-executable support without work from you.

You can also use the bundled `ChimeKit.xcframework`, which provides the same API and does include the ability to transparently run executables. However, due to an [SPM limitation](https://github.com/apple/swift-package-manager/issues/4449), your extension Xcode target must **depend** on `ChimeKitWrapper` but **link** against the framework.

## Documentation

### Non-UI Extension

Extension point identifier: `com.chimehq.Edit.extension`

```swift
import Foundation

import ChimeKit

@main
class NoUIExtension: ChimeExtension {
    var hostApp: HostProtocol?

    required init() {
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

### Fixed Sidebar Extension

Extension point identifier: `com.chimehq.Edit.extension.ui.sidebar`

```swift
import Foundation
import SwiftUI

import ChimeKit

@main
class SidebarExtension: SidebarChimeUIExtension {
    var hostApp: HostProtocol?

    required init() {
    }
    
    var body: some View {
        VStack {
            Rectangle().frame(width: nil, height: 4).foregroundColor(.red)
            Spacer()
            Text("Hello, app extension!")
            Spacer()
            Rectangle().frame(width: nil, height: 4).foregroundColor(.blue)
        }
    }
}
```

### Document-Synced Extension

Extension point identifier: `com.chimehq.Edit.extension.ui.document-synced`

```swift
import Foundation
import SwiftUI

import ChimeKit

@main
class SidebarExtension: DocumentSyncedChimeUIExtension {
    var hostApp: HostProtocol?

    required init() {
    }
    
    var body: some View {
        VStack {
            Rectangle().frame(width: nil, height: 4).foregroundColor(.red)
            Spacer()
            Text("Hello, doc-synced extension!")
            Spacer()
            Rectangle().frame(width: nil, height: 4).foregroundColor(.blue)
        }
    }
}
```

## Suggestions or Feedback

We'd love to hear from you! Get in touch via [twitter](https://twitter.com/chimehq), an issue, or a pull request.

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

[license]: https://opensource.org/licenses/BSD-3-Clause
[license badge]: https://img.shields.io/github/license/ChimeHQ/SwiftTreeSitter
