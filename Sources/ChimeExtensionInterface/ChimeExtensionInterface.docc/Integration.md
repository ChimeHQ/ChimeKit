# Integration

Build and link against the ChimeKit modules.

## Overview

ChimeKit has many components and is packaged as both an XCFramework and individual modules. When creating an extension, you can decide how you want to use it for your project. This offers you control, but does come with some complexity and trade-offs.

## Linking Considerations

The ChimeKit package comes with three distinct libraries, to offer you greater control over the linking process. This is needed because of an SPM [limitation](https://github.com/apple/swift-package-manager/issues/4449). Hopefully this is temporary.

`ChimeKit`: This is the standard library. It includes all of the ChimeKit functionality, including a pre-built XPC Service that can be used to run executables outside of the sandbox.

> Important: Due to the SPM limitation, when used as a dependency to another SPM target, ChimeKit will be linked *both* statically and dynamically. This negtiavely impacts binary size, but should not affect runtime behavior.

`ChimeKitStatic`/`ChimeKitDynamic`: These are explicitly-linked version of ChimeKit. They can be used to work around the double-linking of `ChimeKit`. However, it is currently impossible to use the purely-dynamic version without additional tricks to make SPM build the dependencies first.

Alternatively, you can depend on and use ChimeKit's internal modules individually. This  provides more control over dependencies, but does not provide out-of-sandbox-executable support without work from you. See the article on sandboxing for more details: <doc:Sandboxing>.

## Xcode Configuration

To achieve pure dynamic linking, an extension Xcode target **must** depend on `ChimeKit` but link against the framework.

The framework must also be copied into your extension/wrapper app to be found at runtime. By default, the Generic Extension Xcode template will include the correct runtime search paths to find the framework within its containing application bundle.

To summarize:

Target | Phase | Value
Container | `Embed Frameworks` | `ChimeKit.xcframework`
Extension | `Dependencies` | `ChimeKit`
Extension | `Link Binary With Libraries` | `ChimeKit.xcframework`

## Compatibility

Chime uses the ChimeKit binary XCFramework as its own interface to extensions. This means that there could be drift between the app and the extension. We'll do our best to minimize ABI- and API-incompatible changes, and use deprecations. But, these kinds of changes are inevitable. Chime cannot make its own copy of ChimeKit available to extensions for runtime linking, but that would help reduce issues here.

If you'd like to see that, please file feedback with Apple asking for the feature.
