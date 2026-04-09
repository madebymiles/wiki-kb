---
description: Show wiki statistics, health, and WIP summary. Initialises the wiki if it doesn't exist.
---

# /wiki-status

Current state of the wiki. Creates the structure if it doesn't exist.

## If wiki/ does not exist

Create the full directory structure:

```bash
mkdir -p wiki/raw/inbox wiki/raw/processed wiki/raw/processed/failed wiki/raw/sessions wiki/raw/docs wiki/raw/articles
mkdir -p wiki/architecture wiki/product wiki/principles wiki/projects wiki/reports wiki/reports/archive wiki/archive
```

Create `wiki/index.md` with header (including project abbreviation registry):
```markdown
---
title: Wiki Index
updated: [today]
abbreviations: {alpha: project-alpha, beta: project-beta, gamma: project-gamma}
---

# Knowledge Base Index

No pages yet. Run `/wiki-ingest` to start.
```

Create `wiki/tags.md`, `wiki/log.md`, `wiki/wip.md` with appropriate headers.

Create domain sub-indexes: `wiki/architecture/INDEX.md`, `wiki/product/INDEX.md`, `wiki/principles/INDEX.md`.

Report: "Wiki initialised. Run `/wiki-ingest [path]` to seed it."

## If wiki/ exists

```
WIKI STATUS | [Date]

Pages:          [total active] ([by domain]) | [archived] archived
Compartments:   prof [n], inner [n], house [n], pub [n], reg [n]
Confidence:     high [n], med [n], low [n], stale [n]
Single-source:  [n] pages (capped at medium)
Sources:        [total raw] | [inbox] pending
WIP:            [open] open | [stale] >14 days
Last compile:   [date] | Last lint: [date] | Last challenge: [date]

Recent activity (last 5 log entries):
  [from log.md]

Health:
  Pending inbox: [n]
  Stale pages: [n]
  Orphan pages: [n]
```

Suggest actions if inbox pending, lint overdue, or stale WIP items exist.
