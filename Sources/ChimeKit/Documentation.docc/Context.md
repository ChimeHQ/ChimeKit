# Editing Context

Integrate with Chime's document and project model.

## Overview

A central component of a Chime extension is reacting to changes in editor context. The lifecycle and relationships of documents and projects isn't intuitive, and handling the related functions in ``ExtensionProtocol`` may not be straightforward.

## DocumentContext

A Chime document is modeled with the ``DocumentContext`` structure. The only thing guaranteed is a stable identifier. Name, type, location on disk, and even project membership can and will change during runtime. Extensions have the opportunity to respond to these changes and update internal state using  ``ExtensionProtocol/didChangeDocumentContext(from:to:)-77fdc``. Depending on the functionality of your extension, context changes can mean internal state must be updated.


## Topics

### Documents

- ``DocumentContext``
- ``DocumentIdentity``
- ``DocumentContentIdentity``
- ``DocumentConfiguration``

### Projects

- ``ProjectContext``
- ``ProjectIdentity``
