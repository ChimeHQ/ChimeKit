# ``ChimeKit``

Build Chime extensions.

## Overview

ChimeKit provides the functionality needed to build Extensions for [Chime](https://www.chimehq.com). You can use it to provide semantic features, display views, and integrate with [ExtensionKit](https://developer.apple.com/documentation/extensionkit). Chime can do a lot more with extensions.

## Structure

ChimeKit can be used as a single library. But, internally it is a collection of modules, and they can be used independently.

- `ChimeExtensionInterface`: Core communication and interfaces for Chime's extension system
- `ChimeLSPAdapter`: Integrate [Language Server Protocol](https://microsoft.github.io/language-server-protocol/) with Chime extensions.

## Topics

### Fundamentals

- <doc:System>
- <doc:Integration>
- <doc:Languages>
- <doc:ExtensionKit>
- <doc:Create-An-Extension>

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
