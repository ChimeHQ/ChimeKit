[![License][license badge]][license]
[![Platforms][platforms badge]][platforms]
[![Documentation][docs badge]][documentation]

# ChimeKit
Framework for building [Chime][chime] extensions.

## Overview

Chime's extensions are based on [ExtensionKit](https://developer.apple.com/documentation/extensionkit). They are written in Swift and SwiftUI. ChimeKit also includes a system for integrating [Language Server Protocol](https://microsoft.github.io/language-server-protocol/) servers with the extension API. For the most part, ChimeKit abstracts away all of the ExtensionKit details. You program against the ChimeKit APIs, not the ExtensionKit primitives. However, ExtensionKit does impose some requirements related to security and distribution you must be aware of.

ChimeKit development requires [Chime 2.0](https://www.chimehq.com/download), Xcode 14, and macOS Ventura (13.0).

📖 [Documentation][documentation] is available in DocC format. But, please don't be shy to [reach out](https://www.chimehq.com/contact) to us - we'll help!

## Chime Extension Gallery

This is a first-party extension hosting application, signed by our Developer ID. It will handle discovery and updates, and all open source extensions will be eligible to apply for inclusion. This app will be open source, but it is forthcoming. The actual details of how your sources will be integrated isn't worked out yet, so if you have thoughts, get in touch.

## Our Philosophy

We want to provide a simple user experience for extensions, particularly for language support. We don't think it's great to have four different extensions for one language. So, while we will not gatekeep, we'll have a very strong bias towards **one** extension per language.

LSP is pervasive in language support extensions. Many IDEs use a model of one extension per language server. ChimeKit allows for multiple servers per extension. We think of LSP servers as an implementation detail of language support. Coordinating the behaviors of multiple servers is the job of an extension, not the user.

Chime's core Go and Ruby support aren't open source, yet. But, we will be publishing them. And, going forward, we will **always** begin work on new language support as open source projects.

## Integration

ChimeKit supports two different integration options, both available via SPM. Read more in the [documentation][documentation].

```swift
dependencies: [
    .package(url: "https://github.com/ChimeHQ/ChimeKit")
]
```

```swift
targets: [
    .target(name: "MyExtension", dependencies: [.product(name: "ChimeExtensionInterface", package: "ChimeKit")]),
]
```

## Suggestions or Feedback

We'd love to hear from you! Get in touch via [twitter](https://twitter.com/chimehq), an issue, or a pull request.

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

[license]: https://opensource.org/licenses/BSD-3-Clause
[license badge]: https://img.shields.io/github/license/ChimeHQ/ChimeKit
[platforms]: https://swiftpackageindex.com/ChimeHQ/ChimeKit
[platforms badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChimeHQ%2FChimeKit%2Fbadge%3Ftype%3Dplatforms
[docs badge]: https://img.shields.io/badge/Documentation-DocC-blue
[chime]: https://www.chimehq.com
[documentation]: https://swiftpackageindex.com/ChimeHQ/ChimeKit/main/documentation
