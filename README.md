# wiki-kb

A persistent, compounding knowledge base for Claude Code. Every decision, pattern, and mistake gets compiled into structured markdown with full provenance. The wiki runs autonomously and tells you where every insight came from.

## Quick start

Requires [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Run in your terminal:

```bash
git clone https://github.com/Stritheo/wiki-kb.git
cd wiki-kb && ./setup.sh ~/path/to/your-project
```

Then open Claude Code in your project and type:

```
/wiki-ingest CLAUDE.md
```

Your wiki is live. Ask it anything:

```
/wiki-query what patterns have we established?
```

---

## Why this exists

Claude Code already has strong building blocks for session continuity: CLAUDE.md accumulates project rules, CHECKPOINT.md preserves session state, hooks automate verification, and `/insights` surfaces usage patterns. These work well within a single project and a single session.

This skill adds a compounding layer on top of those foundations. It connects knowledge across projects and across time, so that a pattern discovered in one project is available when you encounter the same problem in another, six months later. It tracks where every piece of knowledge came from, how confident you should be in it, and whether newer evidence has changed the picture.

CLAUDE.md is your project's rulebook. CHECKPOINT.md is your session bookmark. The wiki is your portfolio's institutional memory.

The approach is based on Andrej Karpathy's LLM Wiki pattern: instead of retrieving from raw documents on every question, the LLM incrementally compiles and maintains a structured knowledge base. The knowledge is built up once and kept current, not rediscovered from scratch on every query.

Claude Code's skill system makes this possible without waiting for a native implementation. The wiki is just markdown files in your repo. If and when persistent knowledge becomes a built-in capability, the compiled wiki migrates. The markdown files are the asset. The skill is the workflow around them.

## What you get

Eight commands and an autonomous compiler agent:

| Command | What it does |
|---|---|
| `/wiki-ingest [path]` | Feed a document into the wiki. Extracts decisions, patterns, mistakes. Traces provenance. |
| `/wiki-query [question]` | Ask the wiki anything. Every claim cites its source. `--save` files the answer back. |
| `/wiki-compile` | Process the inbox. Batches by project, handles contradictions, runs confidence decay. |
| `/wiki-lint` | Health check. Finds contradictions, orphan pages, stale claims, compartment leaks. |
| `/wiki-challenge` | Tests recent decisions against established patterns. Finds blind spots. |
| `/wiki-status` | Wiki statistics, health summary. Creates the wiki if it doesn't exist. |
| `/wiki-review` | 30-day retrospective. Trending topics, confidence trajectory, activity balance. |
| `/wiki-graph` | Generates an interactive visual graph of the wiki. HTML or Mermaid. |

## How it works

```
You build. Sessions produce decisions, patterns, mistakes.
    |
    v
Sources land in wiki/raw/inbox/ (manually or via hooks)
    |
    v
/wiki-compile processes the inbox:
  - Reads sources, batched by project
  - Updates or creates wiki pages with provenance
  - Flags contradictions, resolves WIP items
  - Runs zero-cost confidence decay
    |
    v
/wiki-lint and /wiki-challenge maintain quality:
  - Incremental scan for contradictions and leaks
  - Tests decisions against established patterns
  - Archives stale pages and old reports
    |
    v
You query. /wiki-query reads tiered indexes,
returns provenance-traced answers. --save files
answers back into the wiki to compound.
```

## Key design decisions

**Provenance on every claim.** Every wiki page traces back to its source documents, compilation date, and confidence level. No orphan claims. You always know where knowledge came from.

**Confidence model.** Single-source claims are capped at medium confidence. Only corroborated claims (2+ independent sources) can reach high. Unchecked claims decay over 90 days. Stale pages archive after 180 days.

**Compartment model.** Five tiers (regulated, inner-circle, household, professional, public) control what surfaces when. Regulated content is never sent to the API. Lint checks for leaks across boundaries. Sensitive compartments encrypted at rest via git-crypt.

**Token efficiency.** Tiered indexing cuts query cost by 60-80%. Incremental lint cuts weekly maintenance cost by 90%. Confidence decay runs as a shell script with zero token cost. Challenge passes skip automatically in quiet weeks.

**Cross-project intelligence.** Patterns compile across all projects. Solve a problem once, surface the pattern everywhere.

## Advanced setup

The quick start gives you a working wiki. These optional features add autonomy, security, and tooling. Configure any of them at any time.

### Autonomous compilation (cron)

Run `/wiki-compile` automatically every morning. New sources in `wiki/raw/inbox/` get processed while you sleep.

See `references/installation.md` section 4 for the cron scripts and launchd plists.

### Encryption at rest (git-crypt)

Encrypt sensitive compartments (inner-circle, regulated, household) so they're protected in your git repository.

```bash
brew install git-crypt
git-crypt init
git-crypt export-key ~/keys/wiki-kb.key
echo 'wiki/**/inner-circle/** filter=git-crypt diff=git-crypt' >> .gitattributes
```

See `references/SECURITY.md` for the full data classification matrix.

### Web clipper

Clip web articles into the wiki from your terminal. No Obsidian dependency.

```bash
brew install pandoc
cp wiki-kb/references/web-clipper.sh ~/scripts/wiki-clip.sh
chmod +x ~/scripts/wiki-clip.sh

# Usage:
wiki-clip https://example.com/interesting-article
```

### Confidence decay (zero token cost)

A shell script that downgrades confidence on stale pages without calling the API.

```bash
cp wiki-kb/references/confidence-decay.sh ~/scripts/wiki-decay.sh
chmod +x ~/scripts/wiki-decay.sh
```

### Multi-project setup

Share one wiki across all your projects. Set `WIKI_ROOT` to point to the repo containing the `wiki/` directory:

```bash
export WIKI_ROOT="$HOME/path/to/central-repo"
```

See `SKILL.md` (WIKI_ROOT section) for full documentation including skill symlinks and hook distribution.

### Visual graph

Generate an interactive graph of the wiki's structure from Claude Code:

```
/wiki-graph
```

Or install the Obsidian Visualizer VS Code extension for a lightweight graph view without Obsidian.

### Commands vs skills format

The setup script auto-detects your Claude Code format. If you use `.claude/skills/[name]/SKILL.md` directories (newer format), the script creates skill directories. If you use `.claude/commands/[name].md` (standard format), it copies flat files. Both work.

## Credits and lineage

Built on ideas from:

- **Andrej Karpathy's LLM Wiki pattern** ([GitHub Gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f), April 2026). The three-layer architecture, the compilation model, the lint operation, and the core insight that LLMs should maintain knowledge bases rather than rediscover knowledge from scratch. The gist is the foundation. This skill is an adaptation, not a fork.

- **Allie K. Miller's Claudeopedia concept** (X, April 2026). The activity review idea (adapted as `/wiki-review`), the web clipper integration, the "question your assumptions" cron (adapted as `/wiki-challenge`), and the interactive visualisation concept (adapted as `/wiki-graph`).

- **Matt Van Horn** for the original `/last30days` skill referenced by Miller.

- **Community contributions** in the Karpathy gist comments, particularly: wip.md for work-in-progress tracking (glaucobrito), confidence-scored claims (SwarmVault), and enterprise security critiques (Epsilla) that informed the compartment model.

The implementation, performance optimisations, provenance model, compartment system, and setup automation are original work.

## Licence

MIT. See [LICENSE](LICENSE).
