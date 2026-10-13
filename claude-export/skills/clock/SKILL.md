---
name: clock
description: Get current date/time from system clock. Use before any web search, before installing packages, or when the user asks the time.
---

# Clock

Outputs the current system date and time.

## Usage

```
/clock
```

## What it does

Runs `Get-Date` (PowerShell) to get the system clock.

## When to use

MANDATORY before:
- Any WebSearch or WebFetch call — so search queries include the correct year
- Installing new packages — to verify latest versions exist
- The user asks "what time is it" or "what's the date"

## Timezone

System clock reflects the user's configured timezone. No manual UTC+4 assumption needed.
