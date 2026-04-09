---
description: Batch compile inbox sources into the wiki. Batches by project for efficiency. Runs metadata-only confidence decay. Handles WIP resolution and page size enforcement.
---

# /wiki-compile

Process all uncompiled sources. Also runs WIP review, confidence decay, and page size checks.

## Process

### 1. Check inbox

List files in `wiki/raw/inbox/`. If empty, skip to step 5 (WIP and decay still run).

### 2. Group by project

Sort inbox sources by project (infer from filename, frontmatter, or content). This enables project batching: read each project's existing pages once, not once per source.

### 3. Process each project batch

For each project with sources in the inbox:

a. Read the project's existing wiki pages (all pages under `wiki/projects/[name]/`).
b. Read `wiki/index.md` (summary tier) and the relevant domain sub-indexes.
c. Read `wiki/wip.md`.

For each source in the batch (chronological order):
- Skip `regulated` sections. Log exclusion.
- Extract claims, decisions, patterns, mistakes, insights.
- Update or create pages. Increment `source_count`. Note contradictions. Cap single-source pages at `confidence: medium`.
- Resolve WIP items where applicable.
- Enforce page size: split any page exceeding 500 words.

After all sources for this project:
- Update cross-references.
- Update all three indexes (summary, domain, tags).
- Append log entries.
- Move sources from `inbox/` to `processed/`.

### 4. Distillation check

- Redundant pages? Merge.
- Missing cross-references? Add.
- Pages with zero cross-refs? Flag.

### 5. WIP review

Read `wiki/wip.md`:
- Items >14 days: flag in report.
- Resolved items >30 days: move to `## Archived`.

### 6. Confidence decay (metadata-only, zero token cost)

Run as a file-system operation, not an LLM call. For each wiki page:
- Parse `last_verified` from YAML frontmatter.
- If >90 days old: update confidence in frontmatter (high→medium, medium→low, low→stale).
- If stale for two consecutive lints (check `last_linted`): move to `wiki/archive/`.

This step uses `sed`/`awk` on frontmatter only. No page content is read. No tokens consumed.

### 7. Report

```
WIKI COMPILATION | [Date]

Sources processed: [n] (batched across [n] projects)
Pages created: [n]
Pages updated: [n]
Cross-references added: [n]
Contradictions: [n]
WIP resolved: [n]
WIP flagged (>14 days): [n]
Confidence decayed: [n]
Pages archived (stale >180 days): [n]
Regulated exclusions: [n]
Pages split (>500 words): [n]

Wiki totals: [page count] active | [archive count] archived
```
