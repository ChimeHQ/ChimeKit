<div align="center">

[![Build Status][build status badge]][build status]
[![Platforms][platforms badge]][platforms]
[![Documentation][documentation badge]][documentation]
[![Discord][discord badge]][discord]

</div>

# ChimeKit
ChimeKit provides the functionality needed to build extensions for [Chime][chime], the editor for macOS. You can use it to provide semantic features, display views, and integrate with [ExtensionKit][extensionkit]. Chime can do a lot more with extensions.

<p align="center">
    <picture>
        <source media="(prefers-color-scheme: dark)" srcset="https://github.com/ChimeHQ/ChimeKit/blob/main/chimekit-banner~dark@2x.png 2x">
        <source media="(prefers-color-scheme: light)" srcset="https://github.com/ChimeHQ/ChimeKit/blob/main/chimekit-banner@2x.png 2x"> 
        <img alt="ChimeKit logo: a green hexagon connected to a grey hexagon with a puzzle-piece cutout." src="https://github.com/ChimeHQ/ChimeKit/blob/main/chimekit-banner@2x.png">
    </picture>
</p>

## Overview

Chime's extensions are based on [ExtensionKit][extensionkit]. They are written in Swift and SwiftUI. ChimeKit also includes a system for integrating [Language Server Protocol](https://microsoft.github.io/language-server-protocol/) servers with the extension API. For the most part, ChimeKit abstracts away all of the ExtensionKit details. You program against the ChimeKit APIs, not the ExtensionKit primitives. However, ExtensionKit does impose some requirements related to security and distribution you must be aware of.

ChimeKit development requires [Chime 2.0](https://www.chimehq.com/download), Xcode 14, and macOS Ventura (13.0). However, extensions should try to match ChimeKit's macOS Monterey (12.0) requirement.

📖 [Documentation][documentation] is available in DocC format. But, please don't be shy to [reach out](https://www.chimehq.com/contact) to us - we'll help!

## Integration

ChimeKit supports different integration options, all available via SPM. Be sure to read more in the [documentation][documentation], as it isn't as straightforward as a typical SPM package.

```swift
dependencies: [
    .package(url: "https://github.com/ChimeHQ/ChimeKit", branch: "main")
]
```

## Our Philosophy

We want to provide a simple user experience for extensions, particularly for language support. We don't think it's great to have four different extensions for one language. So, while we will not gatekeep, we'll have a very strong bias towards **one** extension per language.

LSP is pervasive in language support extensions. Many IDEs use a model of one extension per language server. ChimeKit allows for multiple servers per extension. We think of LSP servers as an implementation detail of language support. Coordinating the behaviors of multiple servers is the job of an extension, not the user.

All of Chime's [extensions][extensions] are open source and we will **always** begin work on new language support as open source projects.

## Contributing and Collaboration

I would love to hear from you! Issues or pull requests work great. A [Discord server][discord] is also available for live help, but I have a strong bias towards answering in the form of documentation.

I prefer collaboration, and would love to find ways to work together if you have a similar project.

I prefer indentation with tabs for improved accessibility. But, I'd rather you use the system you want and make a PR than hesitate because of whitespace.

By participating in this project you agree to abide by the [Contributor Code of Conduct](CODE_OF_CONDUCT.md).

[build status]: https://github.com/ChimeHQ/ChimeKit/actions
[build status badge]: https://github.com/ChimeHQ/ChimeKit/workflows/CI/badge.svg
[platforms]: https://swiftpackageindex.com/ChimeHQ/ChimeKit
[platforms badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChimeHQ%2FChimeKit%2Fbadge%3Ftype%3Dplatforms
[documentation]: https://swiftpackageindex.com/ChimeHQ/ChimeKit/main/documentation
[documentation badge]: https://img.shields.io/badge/Documentation-DocC-blue
[discord]: https://discord.gg/esFpX6sErJ
[discord badge]: https://img.shields.io/badge/Discord-purple?logo=Discord&label=Chat&color=%235A64EC
[chime]: https://www.chimehq.com
[extensions]: https://www.chimehq.com/extensions
[extensionkit]: https://developer.apple.com/documentation/extensionkit
