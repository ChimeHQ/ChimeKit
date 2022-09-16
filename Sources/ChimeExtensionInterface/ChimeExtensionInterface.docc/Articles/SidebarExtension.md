# Making a Fixed-Sidebar Extension

Present a UI that is active for both projects and documents, fixed to the size of the window.

## Overview

A Fixed-Sidebar extension can present a user interface that is available in all Chime editor windows. This includes projects with no documents open and new documents with no project.

Extension point: `com.chimehq.Edit.extension.ui.sidebar`

The ``SidebarScene`` scene can be used to build a ``ChimeExtensionScene`` which automatically connects to the host and adds the current ``DocumentContext`` and ``ProjectContext`` to the SwiftUI Environment.

## Minimal Example

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
