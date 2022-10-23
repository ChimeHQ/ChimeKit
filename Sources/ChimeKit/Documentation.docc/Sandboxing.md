# Sandboxing

Ensure your extensions' functionality work within a sandboxed process.

## Overview

ExtensionKit extensions **must** be sandboxed. ChimeKit manages all permissions for user-opened documents and directories transparently. However, running in a sandbox can make it impossible to host LSP servers, which is one of the core use-cases for Chime extensions.

## Process Service

ChimeKit includes a system for running executables outside of a sandbox. It is based on [ProcessService](https://github.com/ChimeHQ/ProcessService). By default, ChimeKit depends on ProcessService in a way that **should** cause Xcode to copy ProcessSeviceContainer.framework into any client target. But, that behavior is both opaque and implicit. It's important that, if you need out-of-sandbox support, you verify that ProcessService is being integrated correctly for your extension bundle.
