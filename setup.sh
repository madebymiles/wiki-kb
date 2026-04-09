#!/bin/bash
# wiki-kb setup script
# Usage: ./setup.sh [project-directory]
# If no directory specified, installs in the current directory.

set -euo pipefail

# Colours for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
DIM='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-$(pwd)}"

# Resolve to absolute path
TARGET="$(cd "$TARGET" 2>/dev/null && pwd || echo "$TARGET")"

echo ""
echo -e "${BOLD}wiki-kb${NC} -- Persistent knowledge base for Claude Code"
echo -e "${DIM}Based on Karpathy's LLM Wiki pattern${NC}"
echo ""

# ─── Preflight checks ───────────────────────────────────────────

if ! command -v claude &>/dev/null; then
    echo -e "${YELLOW}Warning:${NC} Claude Code not found on PATH."
    echo "Install: npm install -g @anthropic/claude-code"
    echo "The wiki files will still be installed, but you'll need Claude Code to use them."
    echo ""
    CLAUDE_AVAILABLE=false
else
    CLAUDE_AVAILABLE=true
fi

if [ ! -d "$TARGET" ]; then
    echo -e "${YELLOW}Creating directory:${NC} $TARGET"
    mkdir -p "$TARGET"
fi

# Check for existing .claude directory
if [ ! -d "$TARGET/.claude" ]; then
    mkdir -p "$TARGET/.claude"
fi

# Detect format: skills or commands
if [ -d "$TARGET/.claude/skills" ] && [ "$(find "$TARGET/.claude/skills" -maxdepth 1 -type d | wc -l)" -gt 1 ]; then
    FORMAT="skills"
    echo -e "${BLUE}Detected:${NC} Skills directory format (.claude/skills/)"
else
    FORMAT="commands"
    echo -e "${BLUE}Detected:${NC} Commands format (.claude/commands/)"
fi

echo -e "${BLUE}Installing to:${NC} $TARGET"
echo ""

# ─── Step 1: Wiki directory structure ────────────────────────────

echo -e "${GREEN}[1/4]${NC} Creating wiki directory structure..."

mkdir -p "$TARGET/wiki/raw/inbox"
mkdir -p "$TARGET/wiki/raw/processed/failed"
mkdir -p "$TARGET/wiki/raw/sessions"
mkdir -p "$TARGET/wiki/raw/docs"
mkdir -p "$TARGET/wiki/raw/articles"
mkdir -p "$TARGET/wiki/architecture"
mkdir -p "$TARGET/wiki/product"
mkdir -p "$TARGET/wiki/principles"
mkdir -p "$TARGET/wiki/projects"
mkdir -p "$TARGET/wiki/reports/archive"
mkdir -p "$TARGET/wiki/archive"

# ─── Step 2: Install commands/skills and agent ───────────────────

echo -e "${GREEN}[2/4]${NC} Installing wiki commands and agent..."

if [ "$FORMAT" = "skills" ]; then
    # Skills format: create a directory per command
    for cmd_file in "$SCRIPT_DIR"/commands/*.md; do
        cmd_name=$(basename "$cmd_file" .md)
        skill_dir="$TARGET/.claude/skills/$cmd_name"
        mkdir -p "$skill_dir"
        cp "$cmd_file" "$skill_dir/SKILL.md"
    done
    # Umbrella skill
    mkdir -p "$TARGET/.claude/skills/wiki-kb"
    cp "$SCRIPT_DIR/SKILL.md" "$TARGET/.claude/skills/wiki-kb/SKILL.md"
else
    # Commands format: flat files
    mkdir -p "$TARGET/.claude/commands"
    cp "$SCRIPT_DIR"/commands/*.md "$TARGET/.claude/commands/"
fi

# Agent (same format either way)
mkdir -p "$TARGET/.claude/agents" 2>/dev/null || mkdir -p "$TARGET/agents"
if [ -d "$TARGET/.claude/agents" ]; then
    cp "$SCRIPT_DIR/agents/wiki-compiler.md" "$TARGET/.claude/agents/"
elif [ -d "$TARGET/agents" ]; then
    cp "$SCRIPT_DIR/agents/wiki-compiler.md" "$TARGET/agents/"
fi

# Security reference
mkdir -p "$TARGET/.claude/references" 2>/dev/null || true
cp "$SCRIPT_DIR/references/SECURITY.md" "$TARGET/.claude/references/" 2>/dev/null || true

# ─── Step 3: Hooks ──────────────────────────────────────────────

echo -e "${GREEN}[3/4]${NC} Configuring hooks..."

SETTINGS_FILE="$TARGET/.claude/settings.json"

if [ -f "$SETTINGS_FILE" ]; then
    # settings.json exists -- check if wiki hooks are already present
    if grep -q "WIKI" "$SETTINGS_FILE" 2>/dev/null; then
        echo "  Wiki hooks already present. Skipping."
    else
        echo "  Existing settings.json found. Wiki hooks need to be merged manually."
        echo "  See references/installation.md for the hook configuration to add."
        echo ""
        echo -e "  ${DIM}SessionStart: [ -f wiki/index.md ] && echo '[WIKI] Knowledge base loaded.' && head -20 wiki/index.md || true${NC}"
        echo -e "  ${DIM}Stop: echo \"[WIKI] Session ended. Project: \$(basename \$(pwd))\"${NC}"
    fi
else
    # No settings.json -- create one with wiki hooks
    cat > "$SETTINGS_FILE" << 'SETTINGS'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "[ -f wiki/index.md ] && echo '[WIKI] Knowledge base loaded.' && head -20 wiki/index.md || true",
            "timeout": 5
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo \"[WIKI] Session ended. Project: $(basename $(pwd)) | $(date '+%Y-%m-%d-%H%M%S')\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
SETTINGS
    echo "  Created settings.json with wiki hooks."
fi

# ─── Step 4: Initialise wiki files ──────────────────────────────

echo -e "${GREEN}[4/4]${NC} Initialising wiki..."

# index.md
if [ ! -f "$TARGET/wiki/index.md" ]; then
    cat > "$TARGET/wiki/index.md" << 'INDEX'
---
title: Wiki Index
updated: $(date '+%Y-%m-%d')
abbreviations: {}
---

# Knowledge Base Index

No pages yet. Run `/wiki-ingest` to add your first source, or drop files into `wiki/raw/inbox/` for automatic compilation.

Format: `- [short-path]: [summary, max 10 words] | [confidence] | s:[source_count]`
INDEX
    # Fix the date
    sed -i.bak "s/\$(date '+%Y-%m-%d')/$(date '+%Y-%m-%d')/" "$TARGET/wiki/index.md" 2>/dev/null || \
    sed -i '' "s/\$(date '+%Y-%m-%d')/$(date '+%Y-%m-%d')/" "$TARGET/wiki/index.md"
    rm -f "$TARGET/wiki/index.md.bak"
fi

# tags.md
if [ ! -f "$TARGET/wiki/tags.md" ]; then
    cat > "$TARGET/wiki/tags.md" << 'TAGS'
---
title: Tag Index
---

# Tag Index

Maps tags to wiki pages for fast retrieval. Updated by the wiki-compiler agent.
TAGS
fi

# log.md
if [ ! -f "$TARGET/wiki/log.md" ]; then
    cat > "$TARGET/wiki/log.md" << EOF
# Wiki Log

## [$(date '+%Y-%m-%d %H:%M')] init | Wiki initialised
- Structure created by setup.sh
- Ready for first ingest
EOF
fi

# wip.md
if [ ! -f "$TARGET/wiki/wip.md" ]; then
    cat > "$TARGET/wiki/wip.md" << 'WIP'
# Work in Progress

Items here are decisions not yet finalised. The wiki compiler checks this file on each pass and flags items older than 14 days.

## Archived
WIP
fi

# Domain sub-indexes
for domain in architecture product principles; do
    idx="$TARGET/wiki/$domain/INDEX.md"
    if [ ! -f "$idx" ]; then
        cat > "$idx" << EOF
---
title: ${domain^} Index
---

# ${domain^}

No pages yet.
EOF
    fi
done

# ─── Done ────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}${GREEN}Done.${NC} Wiki installed at $TARGET/wiki/"
echo ""

if [ "$FORMAT" = "skills" ]; then
    CMD_COUNT=$(find "$TARGET/.claude/skills/wiki-"* -maxdepth 0 -type d 2>/dev/null | wc -l | tr -d ' ')
    echo -e "  ${GREEN}✓${NC} $CMD_COUNT wiki skills installed in .claude/skills/"
else
    CMD_COUNT=$(ls "$TARGET/.claude/commands/wiki-"* 2>/dev/null | wc -l | tr -d ' ')
    echo -e "  ${GREEN}✓${NC} $CMD_COUNT wiki commands installed in .claude/commands/"
fi
echo -e "  ${GREEN}✓${NC} Wiki directory structure created"
echo -e "  ${GREEN}✓${NC} index.md, log.md, wip.md, tags.md initialised"
echo -e "  ${GREEN}✓${NC} Domain sub-indexes created"
echo -e "  ${GREEN}✓${NC} Hooks configured"
echo ""

# ─── What's next ─────────────────────────────────────────────────

echo -e "${BOLD}What next?${NC}"
echo ""
echo -e "  ${BOLD}Start now${NC} -- open Claude Code in $TARGET and type:"
echo ""
echo "    /wiki-ingest CLAUDE.md"
echo ""
echo "  This seeds the wiki with your project's existing knowledge."
echo "  Then try:  /wiki-query what patterns have we established?"
echo ""
echo -e "  ${BOLD}Configure advanced features${NC} (optional, do any time):"
echo ""
echo -e "  ${DIM}Autonomous compilation${NC}  Daily cron compiles wiki/raw/inbox/ automatically."
echo "    See: wiki-kb/references/installation.md (section 4)"
echo ""
echo -e "  ${DIM}Encryption at rest${NC}      git-crypt for sensitive compartments."
echo "    See: wiki-kb/references/SECURITY.md"
echo ""
echo -e "  ${DIM}Web clipper${NC}             Clip web articles into the wiki from terminal."
echo "    Run: cp wiki-kb/references/web-clipper.sh ~/scripts/wiki-clip.sh && chmod +x ~/scripts/wiki-clip.sh"
echo ""
echo -e "  ${DIM}Confidence decay${NC}        Zero-token-cost decay via shell script."
echo "    Run: cp wiki-kb/references/confidence-decay.sh ~/scripts/wiki-decay.sh && chmod +x ~/scripts/wiki-decay.sh"
echo ""
echo -e "  ${DIM}Visual graph${NC}            Generate an interactive HTML graph of the wiki."
echo "    In Claude Code: /wiki-graph"
echo ""
echo -e "  ${DIM}Multi-project setup${NC}     Share one wiki across all your projects."
echo "    See: wiki-kb/SKILL.md (WIKI_ROOT section)"
echo ""
