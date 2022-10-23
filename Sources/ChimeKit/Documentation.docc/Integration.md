# Integration

Build and link against the ChimeKit modules.

## Overview

ChimeKit has many components and is packaged for flexibility. When creating an extension, you can decide how you want to use it in your project. This offers you control, but does come with some complexity and trade-offs.

## Linking Considerations

`ChimeKit`: This is the standard library. It includes all of the ChimeKit functionality, but will also cause its dependencies to linked into your target. This includes the ProcessServiceContainer.framework for handling out-of-sandbox processes.

Alternatively, you can depend on and use ChimeKit's internal modules individually. This provides more control over dependencies and linking behavior.

## Xcode Configuration

SPM provides very limited control over linking. If this is a problem, it is possible to build a custom framework wrapper around ChimeKit for better control. Chime itself does this, but it should only be necessary when using a single app container for many extensions.

It is also worth paying attention to how Xcode/SPM packages ProcessServiceContainer.framework. If you require ProcessService features, check your app's bundle to ensure Xcode has properly copied the framework.

## Compatibility

We'll do our best to minimize ABI- and API-incompatible changes, and use deprecations. But, these kinds of changes are inevitable. Chime cannot make its own version of ChimeKit available to extensions for runtime linking, but that would help reduce issues here.

If you'd like to see that, please file feedback with Apple asking for the feature.
