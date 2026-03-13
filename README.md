# XCDocs

<img src="demo.gif" alt="Demo of the xcdocs CLI" width="720">

**XCDocs** is a Swift package and CLI for Apple's developer documentation.

It exposes the same data and functionality which powers Xcode's MCP tool, called `DocumentationSearch`.

The `xcdocs` CLI is designed for use by agents, like Bitrig's agent, Codex, or Claude Code.

## Availability

- macOS 26+
- Apple silicon only
- Xcode 26.3 RC or above has to be installed, but you don't need Xcode open.

## Install

Ask your agent to help!

#### Recommended

Download the CLI from [Releases](releases) and put it in `/usr/local/bin`.

#### Alternative

You can also clone the repo and run `swift build` yourself. The resulting binary will be in `.build/debug/xcdocs`.

## Usage

```bash
xcdocs --help
```

Search for documentation:

```bash
xcdocs search "swift testing"
xcdocs search "swift testing" --framework "Swift Testing" --limit 5
xcdocs search "swift testing" --kind article --limit 5
xcdocs search "swiftui color" --json
xcdocs search "swiftui color" --omit-content
```

Get an entry by identifier:

```bash
xcdocs get /documentation/Testing
xcdocs get /documentation/Testing --json
```

## Swift API

XCDocs also exposes a Swift package which you can integrate into other tools.

To get started, add the repo to your `Package.swift`.

```swift
import XCDocs

let client = Client()

let searchResults = try await client.search(
    "swift testing",
    frameworks: ["Swift Testing"],
    kinds: [.article],
    limit: 5,
    omitContent: false
)

let entry = try await client.entry(
    for: "/documentation/Testing"
)
```

## Development

Run tests:

```bash
swift test
```

Run formatting checks:

```bash
swift format lint --strict Package.swift
swift format lint --strict --recursive Sources Tests
```
