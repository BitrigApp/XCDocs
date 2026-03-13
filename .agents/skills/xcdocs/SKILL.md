---
name: xcdocs
description: Use when an agent is writing, debugging, or updating code against Apple frameworks and needs local Xcode documentation to resolve compile errors, discover the right symbols, check API shape or availability, confirm usage patterns, or inspect related articles and topics for newly released SDK features.
---

# XCDocs

Use `xcdocs` as a local Apple-framework reference while changing code.

## Use It During Implementation

- Ensure `xcdocs` is available before relying on the skill.
- Reach for it when an Apple API is unfamiliar, newly released, renamed, or failing to compile.
- Start with `search --json --omit-content` to find the likely symbol, article, or topic.
- Add repeatable `--framework` and `--kind {article|symbol|topic}` filters when the query is broad.
- Treat `documents[].uri` from search results as the canonical identifier for `get`.
- Use `get --json` to inspect the full entry before editing code that depends on it.
- Apply what you find to the code: fix symbol names, choose the right overload, adjust availability guards, or switch to the documented API.

## Common Uses

- Fix compile failures against Apple frameworks by verifying the actual symbol name and entry point.
- Explore a newly released framework or feature area before wiring it into code.
- Check whether an API is a symbol, a broader topic page, or an article with setup guidance.
- Find adjacent types or concepts after locating one relevant documentation entry.

## Reference

- Read [references/cli.md](references/cli.md) for command syntax, JSON shapes, and troubleshooting.
