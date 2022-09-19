# Integration

Build and link against the ChimeKit modules.

## Overview

ChimeKit has many components and is packaged as both an XCFramework and individual modules. When creating an extension, you can decide how you want to use it for your project. This offers you control, but does come with some complexity.

## Considerations

The XCFramework is pre-built to include everything ChimeKit offers. It also bundles a pre-built XPC Service that can be used to run executables outside of the sandbox.

Using the pre-built XCFramework:

```swift
dependencies: [
    .package(url: "https://github.com/ChimeHQ/ChimeKit")
]
```

Using modules individually:

```swift
targets: [
    .target(name: "MyExtension", dependencies: [.product(name: "ChimeExtensionInterface", package: "ChimeKit")]),
]
```

Using individual modules provides more control over dependencies, but does not provide out-of-sandbox-executable support without work from you. See the article on sandboxing for more details: <doc:Sandboxing>.


## Xcode Configuration

Due to an SPM limitation, an extension Xcode target **must** depend on `ChimeKitWrapper` but link against the framework.

The framework must also be copied into your extension/wrapper app to be found at runtime. By default, the Generic Extension Xcode template will include the correct runtime search paths to find the framework within its containing application bundle.

To summarize:

Target | Phase | Value
Container | `Embed Frameworks` | `ChimeKit.xcframework`
Extension | `Dependencies` | `ChimeKitWrapper`
Extension | `Link Binary With Libraries` | `ChimeKit.xcframework`

## Compatibility

Chime uses the ChimeKit binary XCFramework as its own interface to extensions. This means that there could be drift between the app and the extension. We'll do our best to minimize ABI- and API-incompatible changes, and use deprecations. But, these kinds of changes are inevitable. Chime cannot make its own copy of ChimeKit available to extensions for runtime linking, but that would help reduce issues here.

If you'd like to see that, please file feedback with Apple asking for the feature.
