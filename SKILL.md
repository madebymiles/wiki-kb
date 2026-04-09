---
name: wiki-kb
description: Cross-portfolio knowledge base that compounds learning across all projects. Maintains a persistent, LLM-compiled wiki of architecture decisions, product insights, operating principles, and project-specific knowledge. Runs autonomously via hooks and cron, surfaces provenance on every insight. Use whenever starting a new project, making architecture decisions, capturing learnings, querying past decisions, or reviewing cross-project patterns. Also trigger on "what did we decide", "have we solved this before", "wiki", "knowledge base", or "what do we know about".
---

# Wiki Knowledge Base

A cross-portfolio knowledge base that compounds learning across every project. Based on Karpathy's LLM Wiki pattern, adapted for a super-repo with multiple products and trust boundaries.

The LLM writes and maintains the wiki. You source, direct, and query. Every build session, architecture decision, product insight, and lesson learned gets compiled into structured markdown that survives session boundaries and connects across projects.

## Core concept

Three layers:

- **Raw sources** (`wiki/raw/`): Immutable inputs. The LLM reads from these but never modifies them.
- **The wiki** (`wiki/`): LLM-generated markdown pages organised by domain. The LLM owns this layer entirely.
- **The schema** (this SKILL.md + CLAUDE.md): Governs structure, workflows, and rules.

---

## How it runs autonomously

### 1. Hook-driven capture (every session, automatic)

**SessionStart:** Reads `wiki/index.md` (summary tier only, ~2,000 tokens for 200 pages). Identifies the current project from `pwd`. Loads the project overview page. Claude Code starts every session with compounded context.

**Stop (post-build):** Logs timestamp and project name. Reminds to run `/wiki-ingest` or drop notes into `wiki/raw/inbox/`.

### 2. Scheduled compilation (cron via launchd)

**Daily (0530 AEST):**
- Skips if inbox is empty (no token cost).
- Processes inbox sources batched by project (read project pages once, process all sources for that project, then next project).
- Runs confidence decay as a metadata-only pass (zero token cost).
- Moves processed sources to `wiki/raw/processed/`.

**Weekly (Sunday 1800 AEST):**
- **Lint:** Incremental. Only reads pages modified since last lint, plus a 10% random sample of unchanged pages. Applies confidence decay. Archives stale pages.
- **Challenge:** Skipped if fewer than 3 sources were compiled that week (not enough new decisions to challenge). Otherwise tests recent decisions against established patterns.
- **Report rotation:** Archives reports older than 90 days.

### 3. On-demand query with provenance

1. Reads `wiki/index.md` (summary tier) to identify relevant domains.
2. Reads the relevant domain sub-index (`wiki/[domain]/INDEX.md`).
3. Checks `wiki/tags.md` for tag matches.
4. Reads only the matched pages (not all pages).
5. Synthesises an answer with inline provenance for every claim.
6. Logs the query to `wiki/log.md`.

---

## Directory structure

```
wiki/
  index.md                              # Summary tier: one line per page (~10 words)
  tags.md                               # Tag-to-page mapping for fast retrieval
  log.md                                # All operations including queries
  wip.md                                # In-flight decisions not yet finalised
  
  architecture/
    INDEX.md                            # Domain sub-index with fuller summaries
    auth-patterns.md
    deployment-strategies.md
  product/
    INDEX.md
  principles/
    INDEX.md
    
  projects/
    project-alpha/
      overview.md
      decisions.md
      patterns.md
      mistakes.md
    project-beta/
      overview.md
    [new-project]/                      # Created automatically on first session
      
  raw/
    inbox/                              # Drop zone (auto-processed by cron)
    processed/                          # Completed ingestions
    processed/failed/                   # Malformed or unreadable sources
    sessions/
    docs/
    articles/
    
  reports/
    lint-YYYY-MM-DD.md
    challenge-YYYY-MM-DD.md
    review-YYYY-MM-DD.md
    archive/                            # Reports older than 90 days
```

---

## Wiki location (WIKI_ROOT)

The wiki directory can live in a different location from the project you're working in. This is common in multi-project setups where a single wiki serves all projects from a central repo.

Set `WIKI_ROOT` to the absolute path of the directory containing `wiki/`. All commands and the wiki-compiler agent resolve paths against `WIKI_ROOT` instead of assuming `wiki/` is in the current working directory.

**Same directory (default):** If `WIKI_ROOT` is not set, commands look for `wiki/` relative to `pwd`. This works when the wiki lives alongside your project.

**Central repo:** If the wiki lives in a separate super-repo (e.g. `~/Projects/my-skills-repo/wiki/`), set `WIKI_ROOT` in the umbrella skill or in your shell environment:

```bash
export WIKI_ROOT="$HOME/Projects/my-skills-repo"
```

The SessionStart hook checks for `wiki/index.md` relative to `pwd`. In projects where the wiki is not local, the hook silently skips (no error). Wiki commands still work because they resolve against `WIKI_ROOT`.

---

## Indexing strategy (tiered, for token efficiency)

### Summary index (`wiki/index.md`)

One line per page. Kept under 2,000 tokens for 200 pages. Loaded on every session start and every query.

```markdown
- arch/auth-patterns: Token refresh middleware | high | s:3
- arch/deploy: Cloud deployment patterns | med | s:2
- prod/delegation: Friction removal thesis | med | s:1
- proj/alpha/decisions: Project Alpha architecture choices | high | s:5
```

Format: `- [short-path]: [summary, max 10 words] | [confidence] | s:[source_count]`

### Domain sub-indexes (`wiki/[domain]/INDEX.md`)

Fuller summaries per page within a domain. 2-3 sentences each. Loaded only when a query or compile targets that domain.

### Tag index (`wiki/tags.md`)

Maps tags to page paths. Queries match against tags first (cheap), then read only matched pages.

```markdown
auth: arch/auth-patterns, proj/alpha/decisions, proj/beta/auth-plan
deployment: arch/deploy, proj/alpha/decisions
middleware: arch/auth-patterns, arch/middleware-patterns
```

---

## Provenance model

Every wiki page carries YAML frontmatter. Use compact relative paths to minimise token cost.

```yaml
---
title: OAuth Token Refresh Pattern
domain: architecture
project: project-alpha
compartment: professional
compiled: 2026-03-15
source_count: 3
sources:
  - type: session
    date: 2026-03-14
    ref: sessions/alpha/2026-03-14
  - type: doc
    ref: docs/ms-graph-auth
  - type: session
    date: 2026-03-20
    ref: sessions/alpha/2026-03-20
confidence: high
last_verified: 2026-03-20
last_linted: 2026-04-06
supersedes: null
cross_refs: [proj/beta/auth-plan, arch/middleware-patterns]
tags: [auth, oauth, token-refresh, middleware]
---
```

### Compact path convention

All paths in frontmatter use short relative form. The wiki root (`wiki/`) and file extension (`.md`) are implied.

- `sessions/alpha/2026-03-14` means `wiki/raw/sessions/project-alpha/2026-03-14.md`
- `arch/auth-patterns` means `wiki/architecture/auth-patterns.md`
- `proj/alpha/decisions` means `wiki/projects/project-alpha/decisions.md`

Project abbreviations: `alpha` = project-alpha, `beta` = project-beta, `gamma` = project-gamma. Register new abbreviations in `wiki/index.md` header.

### Confidence rules

- `source_count: 0` (inferred): confidence is always `low`.
- `source_count: 1`: confidence capped at `medium`. Single-source claims cannot reach `high`.
- `source_count: 2+` with at least one verified in use: confidence can reach `high`.

### Confidence decay

Applied as a metadata-only pass (no token cost). Shell script checks `last_verified` dates:
- Older than 90 days: `high` to `medium`, `medium` to `low`, `low` to `stale`.
- Two consecutive lint passes at `stale` (180+ days): page moved to `wiki/archive/`. Still searchable on explicit request but excluded from normal operations.

### Page size enforcement

Pages must not exceed 500 words. If a page grows beyond this during compilation, split it into focused sub-pages before proceeding. Smaller pages reduce over-reading during queries.

---

## Compartment model

| Compartment | Contains | Visibility | API transmission | Encryption |
|---|---|---|---|---|
| `regulated` | Regulated (industry-specific), legal, compliance | Explicit query only | **Blocked** | Required (git-crypt) |
| `inner-circle` | Career strategy, financial, private | Explicit query only | Permitted | Required (git-crypt) |
| `household` | Family, school, dietary | Household context only | Permitted | Optional |
| `professional` | Architecture, product, technical | All projects. Default. | Permitted | Not required |
| `public` | Published, open-source | Everywhere | Permitted | Not required |

**Rules:**
- Default loads `professional` and `public` only.
- `regulated` content is never sent to the Claude API. Must be manually authored.
- Lint checks for leaks across all compartment boundaries.
- `inner-circle` and `regulated` pages encrypted at rest via git-crypt.

---

## Work in progress

`wiki/wip.md` captures in-flight decisions. Format:

```markdown
## [YYYY-MM-DD] [Project] | [Brief description]
Status: open | resolved | archived
Decision pending: [what needs to be decided]
Context: [brief context]
Related: [wiki page paths if any]
```

- Items older than 14 days flagged in compilation report.
- Resolved items cleared monthly.

---

## What gets compiled

**Always:** Architecture decisions. Mistakes and prevention rules. Product insights. Technology evaluations. Patterns. Cross-project connections. Operating principles.

**Never:** Debug output. Git operations. Transient errors. Credentials. Private opinions about people. Regulated content (manually authored only).

**With care:** Financial data (`inner-circle`). Career strategy (`inner-circle`). Family context (`household`).

---

## Compilation rules

1. Read the source completely.
2. Skip any `regulated` content. Log the exclusion.
3. Read `wiki/index.md` (summary tier) and the relevant domain sub-index.
4. Read `wiki/wip.md` for in-flight decisions.
5. Batch by project: read the project's existing pages once, process all sources for that project.
6. For each claim or decision:
   a. Existing page? Update it. Increment `source_count`. Note contradictions.
   b. New concept? Create page. `source_count: 1`, confidence capped at `medium`.
   c. Resolves a WIP item? Update page, mark WIP `resolved`.
7. Enforce page size: split any page exceeding 500 words.
8. Update cross-references, `wiki/index.md`, domain sub-indexes, `wiki/tags.md`.
9. Append to `wiki/log.md`.
10. Move source from `inbox/` to `processed/`.

**Distillation:** 5,000-word transcript produces ~200 words of wiki updates across 3-5 pages.

---

## Commands

| Command | Purpose |
|---|---|
| `/wiki-ingest` | Ingest a source with provenance tracking |
| `/wiki-query` | Query with provenance. `--save` files the answer back. |
| `/wiki-compile` | Batch compile inbox. Handles WIP, decay, batching. |
| `/wiki-lint` | Incremental health check. Decay, leaks, contradictions. |
| `/wiki-challenge` | Test recent decisions against patterns. Skips quiet weeks. |
| `/wiki-status` | Statistics, health, WIP summary. Initialises if needed. |
| `/wiki-review` | 30-day activity review with balance check. |
| `/wiki-graph` | Interactive HTML graph or Mermaid diagram. |

## Agent

| Agent | Writes? | Purpose |
|---|---|---|
| `wiki-compiler` | Yes (wiki/ only) | Compiles, maintains, enforces all rules |

---

## Integration with agentic-eng

| agentic-eng | wiki-kb | Connection |
|---|---|---|
| `/checkpoint` | `/wiki-ingest` | Checkpoint suggests wiki ingestion on completion. |
| `/update-claudemd` | Compilation | CLAUDE.md = project rules. Wiki = portfolio knowledge. |
| `Stop` hook | `Stop` hook | Both fire. Verification first, wiki extraction second. |
| CHECKPOINT.md | `wiki/projects/` | Checkpoint = immediate state. Wiki = compiled knowledge. |
| `architecture-explainer` | `wiki/architecture/` | Agent checks wiki for cross-project patterns. |

### Progression alignment

- **Phase 1:** Wiki passively accumulates via `/wiki-ingest`. Cross-project Common Mistakes.
- **Phase 2:** Wiki actively surfaces patterns during `/review`. `/wiki-challenge` as quality gate.
- **Phase 3:** Wiki feeds autonomous builds. Overnight loops query established patterns.

---

## Performance design

| Optimisation | Mechanism | Impact |
|---|---|---|
| Tiered index | Summary index (~2K tokens) + domain sub-indexes | 60-80% fewer tokens on queries |
| Tag-based retrieval | Match tags before reading pages | 40-60% fewer pages read per query |
| Incremental lint | Only lint modified pages + 10% sample | 90% fewer tokens on weekly lint |
| Metadata-only decay | Shell script updates frontmatter, no LLM call | Zero token cost for decay |
| Project batching | Read project pages once per compile, not per source | 30-50% fewer reads on multi-source compiles |
| Stale archival | Move stale pages to archive/ after 180 days | Keeps active wiki lean |
| Report rotation | Archive reports >90 days | Prevents unbounded report growth |
| Challenge skip | Skip if <3 sources compiled that week | 100% saving in quiet weeks |
| Compact paths | Short relative paths in frontmatter | 30% fewer frontmatter tokens |
| Page size cap | Split pages >500 words | Less over-reading per query |
| Query caching | `--save` creates reusable synthesis pages | Avoids re-synthesis of repeated queries |

---

## Installation

See `references/installation.md` for complete setup.
See `references/SECURITY.md` for data classification and encryption.
