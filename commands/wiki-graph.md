---
description: Generate an interactive HTML graph or Mermaid diagram of the wiki structure. Nodes are pages, edges are cross-references. No Obsidian dependency.
---

# /wiki-graph

Visual map of the wiki. Shows structure, connections, confidence, and orphans.

## Usage

```
/wiki-graph
/wiki-graph --domain [architecture|product|principle|project]
/wiki-graph --project [project-name]
/wiki-graph --format [html|mermaid]
```

Default: full wiki as HTML. `--format mermaid` for inline VS Code viewing.

## Process

### 1. Read page metadata (frontmatter only)

Scan all active wiki pages. Extract from frontmatter only (not page content):
- title, domain, project, confidence, source_count, cross_refs

Exclude `inner-circle` and `regulated` pages unless explicitly requested. Exclude archived pages.

### 2. Build graph data

```json
{
  "nodes": [{"id": "arch/auth-patterns", "title": "...", "domain": "architecture", "confidence": "high", "source_count": 3}],
  "edges": [{"source": "arch/auth-patterns", "target": "proj/beta/auth-plan"}]
}
```

Apply filters if `--domain` or `--project` specified.

### 3. Generate output

**HTML (default):** Standalone file at `wiki/reports/graph.html`. D3.js force-directed layout.
- Colour by domain: architecture (blue #1565C0), product (green #2E7D32), principle (amber #F57F17), project (grey #616161)
- Node size by source_count
- Opacity by confidence: high (100%), medium (75%), low (50%), stale (25%)
- Cross-project edges in pink (#E91E63)
- Orphan nodes with red border (#C62828)
- Hover for title. Click for full frontmatter.

**Mermaid:** File at `wiki/reports/graph.mermaid`. Renders in VS Code with Mermaid extension.

### 4. Report

```
Graph: wiki/reports/graph.html ([n] nodes, [n] edges)
Open: open wiki/reports/graph.html

Hub pages (most connections): [top 3]
Orphan pages (zero connections): [list]
Cross-project edges: [count]
```

If >200 nodes, suggest filtering by domain or project.
