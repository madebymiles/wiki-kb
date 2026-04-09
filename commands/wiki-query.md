---
description: Query the wiki with provenance-traced answers. Uses tag-based retrieval for efficiency. --save files the answer back as a new wiki page.
---

# /wiki-query

Query the wiki. Every claim traces to its source. Uses tiered retrieval to minimise token cost.

## Usage

```
/wiki-query [question]
/wiki-query [question] --project [project-name]
/wiki-query [question] --domain [architecture|product|principle]
/wiki-query [question] --save
```

## Process

### 1. Retrieve efficiently (tiered)

a. Read `wiki/tags.md`. Match query keywords against tags.
b. Read `wiki/index.md` (summary tier). Identify relevant domains from matched entries.
c. Read only the matched domain sub-index (`wiki/[domain]/INDEX.md`).
d. Read only the pages identified by tag match and sub-index review. Do not read all pages.

Respect compartment boundaries: load `professional` and `public` only unless explicitly asked for inner-circle or regulated content.

### 2. Check for cached synthesis

If a `--save`d page already exists for this topic and all its source pages are unmodified since compilation, present the cached synthesis instead of re-reading source pages. Note: "Cached synthesis from [date]. Underlying pages unchanged."

### 3. Synthesise with provenance

Direct answer. Every claim gets inline provenance:

```
The auth pattern uses middleware-based refresh 
[arch/auth-patterns | high | s:3 | 2026-03-15].

First implemented in Project Alpha Phase 1 
[proj/alpha/decisions | high | s:2 | 2026-03-14], 
referenced in Project Beta architecture plan 
[proj/beta/tech-stack | med | s:1 | 2026-04-01].
```

Compact format: `[short-path | confidence | s:source_count | compiled-date]`

### 4. Flag concerns

- Single-source claims (`s:1`): "Single-source. Not independently corroborated."
- Stale confidence: "May be outdated. Last verified [date]."
- Contradictions: present both positions with sources.
- Gaps: "No wiki coverage for [topic]. Consider ingesting [suggested source]."

### 5. Cross-project connections

Highlight explicitly when the answer draws from multiple projects. This is the wiki's highest-value output.

### 6. Log the query

Append to `wiki/log.md`:
```markdown
## [YYYY-MM-DD HH:MM] query | [query text, max 100 chars]
- Pages read: [list of short paths]
- Compartments: [list]
- Gaps: [list or "none"]
- Cached: [yes/no]
```

### 7. Save (if --save)

Create a new wiki page from the synthesis:
- `sources` references all contributing pages.
- `source_count` = number of contributing pages.
- `confidence` = lowest confidence among contributors.
- Cross-references back to all contributors.
- Update all three indexes (summary, domain, tags).

Report: "Saved to [path]. Available in future queries."

### Rules

- Never present a claim without provenance.
- Never fabricate wiki content.
- Every query is logged (compliance-grade access trail).
