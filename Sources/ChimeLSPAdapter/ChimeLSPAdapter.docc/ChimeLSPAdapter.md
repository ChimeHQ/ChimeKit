# ``ChimeLSPAdapter``

Integrate Language Server Protocol with Chime.

## Overview

ChimeKit provides support for [Language Server Protocol][lsp] servers. Configure and run server processes, transform their output, and integrate them into an extension.

The underlying functionality is provided by the [LanguageClient][languageclient] package.

ChimeKit is a collection of modules.

- `ChimeExtensionInterface`: Core communication and interfaces for Chime's extension system
- `ChimeLSPAdapter`: Integrate Language Server Protocol with Chime extensions.
- `ChimeKit.xcframework`: All of ChimeKit's functionality and services, bundled into one framework.

Sandboxing will have a major impact on a language server. See ChimeExtensionInterface for details on ChimeKit's sandbox support.

[lsp]: https://microsoft.github.io/language-server-protocol/
[languageclient]: https://github.com/chimehq/LanguageClient
