# Building and Debugging Extensions

Understand how to set up, build, and debug an extension.

## Overview

Chime uses [ExtensionKit](https://developer.apple.com/documentation/extensionkit) for its extensions. Extensions must be delivered via a container application and always run in a system-managed process. This means that you have a little more work to do to get an extension project set up. It's also more involved to debug your extension. 

## Project Structure

The recommended approach for structuring an extension is as a SPM package. However, a package alone isn't quite enough, as testing requires a container application. A set up that works is a standard SPM package in a git repo with an additional `Projects/ExtensionContainer` Xcode project. This project will host both the container application and a standalone extension target. 

You can check out ``<doc:Project>`` for a step-by-step tutorial on how to get that going. But, here's the basic idea.

## Building

Extensions only become visible to the system after their containing application has been run at least once. You can verify that your extension is visible with the `pluginkit` cli tool.

```
pluginkit -v -m
```

## Selection

Unfortunately, ExtensionKit currently lacks the ability for the host application to distinguish between multiple copies of the same extension. This is **critically** important to understand during development, because you have no way to ensure that Chime is loading or running you in-development copy.

## Logging

It is possible to see logging output from your extension via Console.app. Filtering is highly recommended, because there's so much in there. All of the logging that comes from Chime and ChimeKit can be seeing with the `subsystem:com.chimehq` filter.

## Debugging

It is possible to attach to a running extension instance using Xcode's Debug > Attach to Process facility.

However, Chime actively manages the lifecycle of extensions. It will disable them if they do not apply to the current project/document context. And, this is on top of the management the system does. This can make the debugging process a lot more fragile.
