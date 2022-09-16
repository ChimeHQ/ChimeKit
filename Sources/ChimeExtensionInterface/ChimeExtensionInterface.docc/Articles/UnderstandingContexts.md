# Document and Project Context

Understand now Chime manages document contexts.

## Overview

A central component of a Chime extension is reacting to changes in editor context. The lifecycle and relationships of documents and projects isn't intuitive, and handling the related functions in ``ExtensionProtocol`` may not be straightforward.

A Chime document is modeled with the ``DocumentContext`` structure. The only thing guaranteed is a stable identifier. Name, type, location on disk, and even project membership can and will change during runtime. Extensions have the opportunity to respond to these changes and update internal state using  ``ExtensionProtocol/didChangeDocumentContext(from:to:)-77fdc``. Depending on the functionality of your extension, context changes can mean internal state must be updated.

## DocumentService

A significant portion of the functionality within the extension interface is implicitly scoped to a particular document context, via a ``DocumentService``. Chime can request a new ``DocumentService`` from all extensions via ``ExtensionProtocol/documentService(for:)-a5ry`` after changes have been processes.

> Important: The type of a document can change. If you extension only operates on certain kinds of documents, be sure to pay attention the ``DocumentContext/uti`` property.

## Lifecycle

Chime manages the association of documents and projects. However, it has to respect platform conventions and user interaction. This means that sometimes the relationship between document and project can be unintuitive.

> Important: Do not make any assumptions about open/closing order. A document may be opened **before** a project, and only associated later.
