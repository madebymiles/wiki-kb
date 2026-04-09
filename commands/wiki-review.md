---
description: 30-day activity review. Trending topics, confidence trajectory, cross-project connections, and balance check against the four role targets.
---

# /wiki-review

30-day retrospective on wiki activity.

## Usage

```
/wiki-review
/wiki-review --days [number, default 30]
```

## Process

### 1. Parse log

Read `wiki/log.md`. Filter to the specified period. Categorise: ingest, compile, query, lint, challenge, decay.

### 2. Activity metrics

- Pages created (by domain and project)
- Pages updated (which pages updated most often?)
- Queries run (topic clustering: what are you asking most?)
- Sources ingested (by type)
- Contradictions found and resolved
- Confidence upgrades and downgrades
- Cross-project connections surfaced
- WIP items opened, resolved, pending

### 3. Trends

- **Hot domains:** Most active domains by page creation and update volume.
- **Growing projects:** Expanding vs dormant sub-wikis.
- **Confidence trajectory:** Net direction (improving, declining, stable).
- **Cross-project density:** Cross-references between projects. Isolated projects?
- **Query patterns:** High-query, low-confidence topics (signal to ingest more sources).

### 4. Write report

Write to `wiki/reports/review-YYYY-MM-DD.md`:

```markdown
---
title: Wiki Review
date: YYYY-MM-DD
period_days: [n]
---

# Wiki Review | [Date] | Last [n] days

## Activity
- Pages created: [n] | Updated: [n]
- Sources ingested: [n] | Queries: [n]
- Contradictions: [n] (resolved: [n])

## Trending topics
[Top 5 by activity]

## Project activity
[Per-project growth rates]

## Confidence trajectory
- Upgraded: [n] | Decayed: [n] | Net: [direction]

## Cross-project connections
- New this period: [n]
- Most connected: [list]
- Isolated: [list]

## Attention needed
- High-query low-confidence: [topics with suggested sources]
- Dormant projects: [no activity in 30 days]
- Stale WIP: [items approaching 14-day flag]

## Balance check
[Time allocation implied by wiki activity across four roles:
Personal (20%), Professional (20%), Customers/World (30%), Team/Shareholder (30%).
Compare actual vs target.]
```

### 5. Present

Show summary, trending topics, attention needed, and balance check. The balance check surfaces where attention is actually going versus where it should be.
