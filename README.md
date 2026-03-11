# XCDocs

**XCDocs** is a Swift package and CLI for Apple's developer documentation.

It exposes the same data and functionality which powers Xcode's MCP tool, called `DocumentationSearch`.

The `xcdocs` CLI is designed for use by agents, like Bitrig's agent, Codex, or Claude Code.

## Availability

XCDocs has been tested on Xcode 26.3 RC and above on macOS 26. 

## Build

```bash
swift build
swift run xcdocs --help
```

## CLI

```bash
swift run xcdocs --help
```

Search for documentation:

```bash
swift run xcdocs search "swift testing"
swift run xcdocs search "swift testing" --framework "Swift Testing" --limit 5
swift run xcdocs search "swiftui color" --json
swift run xcdocs search "swiftui color" --omit-content
```

Fetch an entry by identifier:

```bash
swift run xcdocs fetch /documentation/Testing
swift run xcdocs fetch /documentation/Testing --json
```

## Swift API

```swift
import XCDocs

let client = Client()

let searchResponse = try await client.search(
    SearchRequest(
        query: "swift testing",
        frameworks: ["Swift Testing"],
        maxResults: 5,
        includeContent: true
    )
)

let fetchResponse = try client.fetch(
    FetchRequest(identifier: "/documentation/Testing")
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

CI:

- `.github/workflows/format.yml` runs formatting checks
- `.github/workflows/test.yml` runs the package test suite
