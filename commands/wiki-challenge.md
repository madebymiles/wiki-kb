---
description: Challenge recent decisions against established wiki patterns. Skips if fewer than 3 sources compiled that week. Flags single-source risks and cross-project opportunities.
---

# /wiki-challenge

Test recent decisions against accumulated knowledge. Skips automatically in quiet weeks.

## Usage

```
/wiki-challenge
/wiki-challenge --days [number, default 7]
/wiki-challenge --project [project-name]
```

## Process

### 1. Activity check

Read `wiki/log.md`. Count sources compiled in the specified period. If fewer than 3: report "Quiet week ([n] sources). Challenge skipped." and exit. Not enough new decisions to warrant the pass.

### 2. Gather recent decisions

From the log, identify pages created or updated in the period. Read those pages (only those pages, not the full wiki).

### 3. Load established patterns (efficient)

Read `wiki/principles/INDEX.md` and `wiki/architecture/INDEX.md` (sub-indexes, not full pages). Only read full pages for patterns that relate to the recent decisions.

### 4. Test each decision

a. **Consistency:** Aligns with established principles? Flag misalignment with source count context.
b. **Precedent:** Similar problem solved in another project? Same or different approach?
c. **Opportunity:** Pattern that could benefit other projects?
d. **Contradiction:** Conflicts with existing wiki claim?
e. **Confidence impact:** Should any existing page's confidence change?
f. **Single-source risk:** Decision rests on a source_count:1 page? Flag as unreliable foundation.

### 5. Write report

Write to `wiki/reports/challenge-YYYY-MM-DD.md`:

```markdown
---
title: Challenge Report
date: YYYY-MM-DD
decisions_reviewed: [n]
---

# Challenge Report | [Date]

## Contradictions with established patterns
[Conflicts with sources and source counts]

## Cross-project opportunities
[Specific patterns to adopt and where]

## Single-source risks
[Decisions built on s:1 pages. Recommended sources to corroborate.]

## Confidence updates
[Pages to upgrade or downgrade]

## Blind spots
[Decisions made without wiki coverage]

## Reinforced patterns
[Decisions confirming existing knowledge]
```

**CHECKPOINT:** Do not auto-resolve contradictions. Present for Miles's judgment.
