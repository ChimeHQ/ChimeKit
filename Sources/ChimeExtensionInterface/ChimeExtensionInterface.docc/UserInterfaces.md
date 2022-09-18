# Views

Summary

## Overview

Text

## Fixed-Sidebar

A Fixed-Sidebar extension can present a user interface that is available in all Chime editor windows. This includes projects with no documents open and new documents with no project.

Extension point: `com.chimehq.Edit.extension.ui.sidebar`

The ``SidebarScene`` scene can be used to build a ``ChimeExtensionScene`` which automatically connects to the host and adds the current ``DocumentContext`` and ``ProjectContext`` to the SwiftUI Environment.

## Fixed-Sidebar Example

```swift
import Foundation
import SwiftUI

import ChimeKit

@main
final class SidebarExtension: SidebarChimeUIExtension {
    required init() {
    }
    
    func acceptHostConnection(_ host: HostProtocol) throws {
    }

    var scene: some ChimeExtensionScene {
        SidebarScene {
            VStack {
                Rectangle().frame(width: nil, height: 4).foregroundColor(.red)
                Spacer()
                Text("Hello, app extension!")
                Spacer()
                Rectangle().frame(width: nil, height: 4).foregroundColor(.red)
            }
        }
    }
}
```

## Document-Synced

A Document-Synced extension can present a user interface that is available only for Chime windows that have a text document. The height and scroll position of this view is kept in sync with the text.

Extension point: `com.chimehq.Edit.extension.ui.document-synced`

The ``DocumentSyncedScene`` scene can be used to build a ``ChimeExtensionScene`` which automatically connects to the host and adds the current ``DocumentContext`` and ``ProjectContext`` to the SwiftUI Environment.

## Document-Synced Example

```swift
import Foundation
import SwiftUI

import ChimeKit

@main
final class SidebarExtension: SidebarChimeUIExtension {
    required init() {
    }
    
    func acceptHostConnection(_ host: HostProtocol) throws {
    }

    var scene: some ChimeExtensionScene {
        DocumentSyncedScene {
            VStack {
                Rectangle().frame(width: nil, height: 4).foregroundColor(.red)
                Spacer()
                Text("Hello, doc-synced extension!")
                Spacer()
                Rectangle().frame(width: nil, height: 4).foregroundColor(.red)
            }
        }
    }
}
```

## Topics

### Scenes

- ``ChimeExtensionScene``
- ``ChimeExtensionSceneIdentifier``
- ``SidebarScene``
- ``DocumentSyncedScene``

### Environment

- ``DocumentContextKey``
- ``ProjectContextKey``

## Communication

- ``ExtensionSceneProtocol``
- ``ExtensionSceneHostProtocol``
