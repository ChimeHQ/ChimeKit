# Making a Document-Synced Extension

Present a UI with a height and scroll position kept in sync with the current text document.

## Overview

A Document-Synced extension can present a user interface that is available only for Chime windows that have a text document. The height and scroll position of this view is kept in sync with the text.

Extension point: `com.chimehq.Edit.extension.ui.sidebar`

The ``DocumentSyncedScene`` scene can be used to build a ``ChimeExtensionScene`` which automatically connects to the host and adds the current ``DocumentContext`` and ``ProjectContext`` to the SwiftUI Environment.

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
