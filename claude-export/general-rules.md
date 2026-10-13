# Portable engineering rules

Distilled from the Hashnoor CLAUDE.md — project-agnostic, drop into any repo's
CLAUDE.md (or your global `~/.claude/CLAUDE.md`).

## Working discipline

1. **Plan first, then implement.** Write a planning document, scrutinize it
   across multiple passes (self-review + external review), fix every gap, then
   implement strictly per the plan.
2. **Scrutinize everything** — plans, code, PRs. Look for contradictions, gaps,
   edge cases, silent failures. Multiple passes, not one skim.
3. **Push back** on anything that doesn't make sense or is contradictory. Relay
   hurdles and ask questions freely — never sit on a blocker.
4. **After every change**: bump the version in its single source of truth, run
   the sync step, commit, push. Don't wait to be asked.
5. **Never commit secrets** (`.env`, keystores, certs). Commit `.env.example`
   as the template instead.
6. **Never add `Co-Authored-By`** to commit messages.

## Data correctness

7. **Compute money forward** from quantity × unit price. Never reverse-engineer
   amounts from stored totals — float noise accumulates (229.99 vs 230.00).
8. **One authority for business math** (pricing, tax, discounts) on the server;
   clients mirror it. When they disagree, the server wins.
9. **Special modes fix the math server-side** on *every* path (create AND
   update), not just the UI. Check the math, not the display.
10. **Trim and normalize canonical text** (names, codes) at every comparison
    point. Trailing spaces create duplicate entities and miscounts.
11. **Numeric/decimal DB columns come back as strings** on some drivers —
    convert before formatting (`.toFixed()` on a string throws).
12. **Units at every boundary**: know whether a distance is metres or km where
    you compute it. A missing ÷1000 is a 1000× odometer bug.
13. **Append-only ledgers stay append-only** — never UPDATE/DELETE; compensate
    with reversal rows.
14. **When adding a field to an entity-create object, diff against the old
    object** — a silently defaulted field is a dropped field.

## Time & dates

15. **Never slice UTC ISO strings for user-facing dates** (`toISOString().slice(0,10)`
    shifts by the UTC offset). Use local date components or an explicit timezone.
16. **Business day/session boundaries use the business timezone explicitly**
    (SQL `AT TIME ZONE` / offset math), never the server's local clock.

## Framework gotchas

17. **ORM updates: use `update()`, not `save()`**, when cascades can nullify
    foreign keys on existing rows.
18. **Query builders: never raw `::casts` inside where-strings** — the parameter
    parser mangles them. Pass typed JS values and bounds instead.
19. **HTTP client POST with no body**: send `undefined`, not `null` — `null`
    serializes to the string `"null"` and the body parser 400s.
20. **Type-check exit-code trap**: `tsc | tail` returns tail's exit code. Check
    `$?` explicitly or don't pipe.
21. **Sibling methods with similar signatures** — prefer named/object arguments;
    swapped positional args fail silently in the wrong column.

## Build & release

22. **Migrations: complete explicit list** in release builds. No destructive
    fallback that silently wipes user data.
23. **Obfuscation + reflection**: keep every class the deserializer touches
    (DTOs are classes too), not just the interfaces.
24. **CLI and IDE builds can write to different output directories** — commit
    the artifact from the path the release flow actually reads, and stamp a
    version file next to it so unrelated commits never trigger update prompts.
25. **Deploy as the service user, never root** — root-owned `node_modules` breaks
    the service account. One known runbook (pull → install → build → restart),
    never a second improvised way.

## UI

26. **Layout-dependent operations** (map zoom/fit, measurement) must run
    post-layout (`post {}`, `requestAnimationFrame`) — during the render pass
    the viewport is 0px and you land at world zoom.
27. **Popovers over map/canvas layers** need z-index above the layer panes; a
    global CSS rule beats a per-component prop the component doesn't have.
28. **Refresh derived state when a surface opens**, not only on navigation —
    navigation-only refreshes race the return path and show stale menus.
29. **Missing OS permissions are a graceful gate** (a grant step), never a crash.
30. **Hot-path polling needs fast intervals** — exempt those endpoints from rate
    limits or the limiter throttles them.

## Integrations

31. **External enrichment (map-matching, smoothing) is display-only** — the raw
    data stays the source of truth; never compute metrics from enriched output.
32. **Fail-soft external services**: timeouts return null and fall back to raw
    data; an unreachable third party must never fail the core flow.
33. **High-frequency raw data gets a retention/purge job** from day one.
34. **Never guess IDs or option names** in external systems — discover them via
    API and persist the mapping.
