# Adding Languages

Add semantic-level features for new programming languages.

## Overview

Adding support for a new languages has multiple components. Source interactions, like highlighting and indenting, are low-latency operations that must happen within the Chime main application. These things cannot be done by an extension today.

If Chime does not support a language you'd like to use, the first step is to let us know! Our process will look like this:

- Create an SPM-based [tree-sitter](https://github.com/ChimeHQ/SwiftTreeSitter#language-parsers) parser
- Ensure that parser has the needed queries defined
- Incorporate the parser and queries into a new Chime build
- Define Uniform Type Identifiers (UTIs) for the language

Your process will depend on what kind of support you need to build. If you are using an LSP server, at a minimum, you'll need to ensure that [LanguageServerProtocol](https://github.com/ChimeHQ/LanguageServerProtocol) has a language identifier constant defined. After that, your extension does the rest, most likely by making use of the `LSPService` API within the `ChimeLSPAdapter` module of ChimeKit.

## Validating the UTI

Chime relies heavily internally on [UTIs](https://developer.apple.com/documentation/uniformtypeidentifiers) for identifying file types. It is critical that the UTI is correctly set for all content. If you are unsure, you can verify it with the `kMDItemContentType` key from the `mdls` tool.

```
mdls path/to/your/file
```
