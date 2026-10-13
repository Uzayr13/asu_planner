---
name: web-search
description: Search the web with mandatory clock check. Use instead of bare WebSearch. Ensures queries always include the current year.
---

# Web Search

Search the web for current information. Always checks the clock first to ensure the correct year is used in queries and results interpretation.

## Before Every Search

Run the clock skill: `/clock`

This ensures:
- Search queries include the correct current year when needed (e.g., "latest version 2026")
- Results are interpreted relative to the current date
- Version comparisons account for the current date

## How to Search

1. Run `/clock` to get current date
2. Construct search query using the correct year
3. Use WebSearch with the query
4. Report results, citing sources

## Example

```
User: "What's the latest Docker version?"

Claude:
  1. /clock → 2026-05-29
  2. WebSearch("Docker latest stable version 2026")
  3. Report results
```
