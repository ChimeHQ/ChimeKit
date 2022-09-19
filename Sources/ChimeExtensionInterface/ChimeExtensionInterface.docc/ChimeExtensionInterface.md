# ``ChimeExtensionInterface``

Core communication and interfaces for Chime's extension system

## Overview

ChimeKit provides the functionality needed to build extensions, provide semantic features, display views, and integrate with [ExtensionKit](https://developer.apple.com/documentation/extensionkit). Chime can do a lot more with extensions.

ChimeKit is a collection of modules. They can be used individually, or all together via a bundled XCFramework. 

## Integration

ChimeKit has many components and is structured to provide some flexibilty to the extension using it.

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

Using individual modules provides more contorl over dependecies, but does not provide out-of-sandbox-executable support without work from you. See the article on sandboxing for more details.

## Topics

### Fundamentals

- <doc:System>
- <doc:Languages>
- <doc:ExtensionKit>
- <doc:BuildingExtension>

### Building Extensions

- <doc:Sandboxing>
- <doc:Context>
- <doc:Text>
- <doc:UserInterfaces>

### Communication

- ``ExtensionProtocol``
- ``HostProtocol``
- ``ExportedHost``
- ``RemoteScene``
