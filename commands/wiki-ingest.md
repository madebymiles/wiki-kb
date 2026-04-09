---
description: Ingest a source document into the wiki knowledge base. Extracts key claims, updates existing pages, creates new pages, traces provenance, resolves WIP items.
---

# /wiki-ingest

Ingest a source into the wiki. The original is stored immutably. Knowledge is compiled into wiki pages with full provenance.

## Usage

```
/wiki-ingest [path-to-source]
/wiki-ingest [path-to-source] --project [project-name]
/wiki-ingest [path-to-source] --domain [architecture|product|principle]
/wiki-ingest [path-to-source] --compartment [professional|inner-circle|household|public|regulated]
```

Defaults: project from `pwd`, domain from content, compartment `professional`.

## Process

### 1. Validate

- Confirm file exists.
- If already in `wiki/raw/processed/`, warn. Ask whether to re-ingest.
- Classify source type: session, documentation, article, checkpoint, architecture doc.
- If `--compartment regulated`: store the raw source but do not compile. Log exclusion. Regulated pages must be manually authored.

### 2. Copy to raw storage

Copy to the appropriate location under `wiki/raw/`. Use compact project abbreviations in paths (alpha, beta, gamma). Never modify the raw copy.

### 3. Read wiki state (efficient)

Read `wiki/index.md` (summary tier only). Read the relevant domain sub-index. Read `wiki/wip.md`.

### 4. Extract and compile

Read the source. Identify decisions, mistakes, patterns, insights, principles, WIP resolutions.

For each item:
- Existing page? Update it. Add source to frontmatter. Increment `source_count`. Note contradictions.
- New concept? Create page. `source_count: 1`, confidence capped at `medium`.
- Cross-references to related pages (same domain, same project, connected concepts).
- Resolves a WIP item? Update wiki page, mark WIP `resolved`.
- Page exceeds 500 words after update? Split it.

### 5. Update indexes

- `wiki/index.md`: add/update entry in compact format.
- `wiki/[domain]/INDEX.md`: add/update with 2-3 sentence summary.
- `wiki/tags.md`: add/update tag mappings.
- `wiki/log.md`: append ingest entry with project, compartment, pages touched, WIP resolved, regulated exclusions.

### 6. Report

```
Source: [filename]
Pages created: [count and names]
Pages updated: [count and names]
Cross-references: [count]
Contradictions: [any, with details]
WIP resolved: [any]
```

**CHECKPOINT:** If contradictions found, present for resolution. Do not silently overwrite.
