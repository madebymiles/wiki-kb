---
description: Incremental wiki health check. Only scans modified pages plus a 10% random sample. Checks contradictions, compartment leaks, confidence violations, source integrity, and stale archival.
---

# /wiki-lint

Incremental audit. Only reads pages changed since last lint plus a random 10% sample of unchanged pages.

## Process

### 1. Identify pages to scan

Read `wiki/index.md`. For each page, check `last_linted` in frontmatter:
- **Modified since last lint:** Scan fully.
- **Unmodified:** Include 10% random sample. Skip the rest.

At steady state with 200 pages and 10 modified per week, this scans ~30 pages instead of 200.

### 2. Check each scanned page

a. **Frontmatter completeness:** All required fields present (title, domain, project, compartment, compiled, source_count, sources, confidence, last_verified, last_linted, cross_refs, tags)?
b. **Source validity:** Do referenced raw sources exist?
c. **source_count integrity:** Does count match actual sources list length?
d. **Confidence ceiling:** source_count:1 pages must not exceed `confidence: medium`.
e. **Confidence decay:** If `last_verified` >90 days, apply decay.
f. **Cross-reference integrity:** Do all cross_refs point to existing pages? Are there inbound refs not listed?
g. **Page size:** Flag pages exceeding 500 words.

Update `last_linted` to today on every scanned page.

### 3. Cross-page analysis (scanned pages only)

a. **Contradictions:** Compare claims within the same domain.
b. **Orphans:** Pages with zero inbound cross-references.
c. **Missing pages:** Concepts mentioned but lacking own page.
d. **Redundant pages:** Substantially overlapping topics.

### 4. Compartment audit (all pages, metadata-only)

Scan frontmatter only (no content read, minimal token cost):
a. Cross-references from professional/public to inner-circle/regulated? Leak.
b. Regulated pages present but not in git-crypt `.gitattributes`? Flag.

### 5. Stale archival

Pages at `confidence: stale` for two consecutive lint passes (check `last_linted` history):
- Move to `wiki/archive/`.
- Remove from `wiki/index.md`, domain sub-index, `wiki/tags.md`.
- Log the archival.

### 6. WIP health

- Open items count.
- Items >14 days.
- Resolved items awaiting archival.

### 7. Report rotation

Move reports in `wiki/reports/` older than 90 days to `wiki/reports/archive/`.

### 8. Write report

Write to `wiki/reports/lint-YYYY-MM-DD.md`:

```markdown
---
title: Wiki Lint Report
date: YYYY-MM-DD
pages_scanned: [n] of [total] ([modified] modified + [sample] sampled)
issues_found: [n]
---

# Wiki Lint Report | [Date]

## Critical
[Contradictions, compartment leaks, regulated exposure, confidence violations]

## Warning
[Stale confidence, orphans, incomplete frontmatter, oversized pages, WIP >14 days]

## Info
[Missing pages, redundant pages, missing cross-refs, git-crypt gaps]

## Actions taken
- Confidence decayed: [n] pages
- Pages archived: [n] pages
- Reports rotated: [n] files
- last_linted updated: [n] pages

## Statistics
- Active pages: [n] | Archived: [n]
- By domain: arch [n], prod [n], princ [n], proj [n]
- By compartment: professional [n], inner-circle [n], household [n], public [n], regulated [n]
- By confidence: high [n], med [n], low [n], stale [n]
- Single-source pages: [n]
- Avg cross-refs/page: [n]
- Avg source_count/page: [n]
- WIP: [open] open, [stale] >14 days
```
