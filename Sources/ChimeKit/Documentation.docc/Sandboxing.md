# Sandboxing

Ensure your extensions' functionality work within a sandboxed process.

## Overview

ExtensionKit extensions **must** be sandboxed. ChimeKit manages all permissions for user-opened documents and directories transparently. However, running in a sandbox can make it impossible to host LSP servers, which is one of the core use-cases for Chime extensions.

## Process Service

ChimeKit includes a system for running executables outside of a sandbox. `HostProtocol` contains a facility for inspecting the user's shell environment and running processes on an extension's behalf.
