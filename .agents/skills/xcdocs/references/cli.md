# XCDocs CLI Reference

## Availability

- macOS 26 or later
- Apple silicon
- Xcode 26.3 RC or newer installed locally
- `xcdocs` available in the agent environment

## Commands

### Search

Use semantic search against the local documentation asset.

```bash
xcdocs search "swift testing" --limit 5 --omit-content --json
```

Flags:

- `--framework <framework>`: repeat to constrain results to one or more frameworks
- `--kind <kind>`: repeat to constrain results to `article`, `symbol`, or `topic`
- `--limit <limit>`: default `10`
- `--omit-content`: skip full document bodies in search results
- `--json`: emit machine-readable output

The CLI also defaults to `search` when no subcommand is supplied, but explicit `search` is easier to read in logs and transcripts.

### Get

Use a stable documentation identifier from search output to fetch the full entry.

```bash
xcdocs get /documentation/Testing --json
```

### Version

Confirm the executable and package version.

```bash
xcdocs version
```

## JSON Shapes

Observed `search --json` shape:

```json
{
  "documents": [
    {
      "uri": "/documentation/Testing",
      "contents": null,
      "score": 0.7537404298782349,
      "title": "Swift Testing"
    }
  ]
}
```

Observed `get --json` shape:

```json
{
  "id": "/documentation/Testing",
  "framework": "Swift Testing",
  "kind": "symbol",
  "title": "Swift Testing",
  "content": "..."
}
```

## Recommended Flow

1. Search broadly with `--omit-content --json`.
2. Add `--framework` or `--kind` when disambiguation is needed.
3. Use `documents[].uri` as the input to `get`.
4. Use the fetched entry to drive code changes: correct the symbol, adjust API usage, or add the right availability handling.

## Troubleshooting

- If the CLI reports an availability error, verify macOS and Xcode requirements first.
- If the search results are noisy, add `--framework` before overfitting the query text.
- If the search results are empty, remove filters and broaden the natural-language query.
