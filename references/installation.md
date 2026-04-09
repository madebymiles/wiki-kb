# Installation and Setup Guide

## Overview

Installs wiki-kb into your super-repo: 8 commands, 1 agent, tiered indexing, git-crypt encryption, cron automation, web clipper, and zero-token-cost confidence decay.

---

## 1. Get the skill

**Option A: Clone the repo**
```bash
cd ~/path/to/super-repo
git clone https://github.com/YOUR_USERNAME/wiki-kb.git wiki-kb
```

**Option B: Extract from archive**
```bash
cd ~/path/to/super-repo
mkdir -p wiki-kb
tar -xzf wiki-kb-publish.tar.gz -C wiki-kb
```

**Then install:**
```bash

# Install commands and agent
cp wiki-kb/commands/*.md .claude/commands/
cp wiki-kb/agents/*.md .claude/agents/

# Install references
mkdir -p .claude/references
cp wiki-kb/references/SECURITY.md .claude/references/

# Install scripts
mkdir -p ~/scripts
cp wiki-kb/references/web-clipper.sh ~/scripts/wiki-clip.sh
cp wiki-kb/references/confidence-decay.sh ~/scripts/wiki-decay.sh
chmod +x ~/scripts/wiki-clip.sh ~/scripts/wiki-decay.sh

# Shell aliases
echo 'alias wiki-clip="~/scripts/wiki-clip.sh"' >> ~/.zshrc
source ~/.zshrc
```

Restart Claude Code and verify: type `/wiki` and confirm 8 commands appear.

---

## 2. Merge hooks into settings.json

Add these to the existing arrays in `.claude/settings.json`. Keep all agentic-eng hooks.

**SessionStart array -- add:**
```json
{
  "type": "command",
  "command": "[ -f wiki/index.md ] && echo '[WIKI] Knowledge base loaded.' && head -20 wiki/index.md || echo '[WIKI] No wiki. Run /wiki-status to init.'",
  "timeout": 5
}
```

**Stop array -- add (after verification hook):**
```json
{
  "type": "command",
  "command": "echo \"[WIKI] Session ended. Project: $(basename $(pwd)) | $(date '+%Y-%m-%d-%H%M%S')\"",
  "timeout": 5
}
```

---

## 3. git-crypt

```bash
brew install git-crypt
cd ~/path/to/super-repo
git-crypt init
mkdir -p ~/keys
git-crypt export-key ~/keys/wiki-kb.key

cat >> .gitattributes << 'EOF'
wiki/**/inner-circle/** filter=git-crypt diff=git-crypt
wiki/**/regulated/** filter=git-crypt diff=git-crypt
EOF

# Optional: encrypt household if it contains children's names, schools, or medical data
# echo 'wiki/**/household/** filter=git-crypt diff=git-crypt' >> .gitattributes

git add .gitattributes
git commit -m "Configure git-crypt for wiki sensitive compartments"
```

---

## 4. Cron scripts

### Daily compilation (0530 AEST)

Create `~/scripts/wiki-compile.sh`:

```bash
#!/bin/bash
SUPER_REPO="$HOME/path/to/your/super-repo"
LOG_FILE="$SUPER_REPO/wiki/reports/cron.log"

cd "$SUPER_REPO" || exit 1

# Metadata-only confidence decay (zero token cost)
~/scripts/wiki-decay.sh "$SUPER_REPO/wiki" >> "$LOG_FILE" 2>&1

# Check inbox
INBOX_COUNT=$(find wiki/raw/inbox -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$INBOX_COUNT" -eq "0" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M')] No sources. Decay complete." >> "$LOG_FILE"
    exit 0
fi

echo "[$(date '+%Y-%m-%d %H:%M')] Compiling $INBOX_COUNT sources..." >> "$LOG_FILE"
claude --print "/wiki-compile" >> "$LOG_FILE" 2>&1
echo "[$(date '+%Y-%m-%d %H:%M')] Done." >> "$LOG_FILE"
```

### Weekly maintenance (Sunday 1800 AEST)

Create `~/scripts/wiki-weekly.sh`:

```bash
#!/bin/bash
SUPER_REPO="$HOME/path/to/your/super-repo"
LOG_FILE="$SUPER_REPO/wiki/reports/cron.log"

cd "$SUPER_REPO" || exit 1

# Log rotation (keep last 500 lines)
tail -500 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"

# Lint (incremental -- only modified pages + 10% sample)
echo "[$(date '+%Y-%m-%d %H:%M')] Weekly lint..." >> "$LOG_FILE"
claude --print "/wiki-lint" >> "$LOG_FILE" 2>&1

# Challenge (skip if quiet week)
WEEK_SOURCES=$(grep -c "compile\|ingest" "$LOG_FILE" 2>/dev/null | tail -1)
if [ "${WEEK_SOURCES:-0}" -ge 3 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M')] Weekly challenge..." >> "$LOG_FILE"
    claude --print "/wiki-challenge" >> "$LOG_FILE" 2>&1
else
    echo "[$(date '+%Y-%m-%d %H:%M')] Quiet week ($WEEK_SOURCES sources). Challenge skipped." >> "$LOG_FILE"
fi

# Report rotation (archive >90 days)
find "$SUPER_REPO/wiki/reports" -maxdepth 1 -name '*.md' -mtime +90 -exec mv {} "$SUPER_REPO/wiki/reports/archive/" \;

echo "[$(date '+%Y-%m-%d %H:%M')] Weekly complete." >> "$LOG_FILE"
```

```bash
chmod +x ~/scripts/wiki-compile.sh ~/scripts/wiki-weekly.sh
```

### launchd plists

Daily (`~/Library/LaunchAgents/com.wiki.compile.plist`):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>com.wiki.compile</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string><string>-l</string>
        <string>/Users/YOUR_USERNAME/scripts/wiki-compile.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict><key>Hour</key><integer>5</integer><key>Minute</key><integer>30</integer></dict>
    <key>StandardOutPath</key><string>/tmp/wiki-compile.out</string>
    <key>StandardErrorPath</key><string>/tmp/wiki-compile.err</string>
</dict>
</plist>
```

Weekly (`~/Library/LaunchAgents/com.wiki.weekly.plist`):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>com.wiki.weekly</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string><string>-l</string>
        <string>/Users/YOUR_USERNAME/scripts/wiki-weekly.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict><key>Weekday</key><integer>0</integer><key>Hour</key><integer>18</integer><key>Minute</key><integer>0</integer></dict>
    <key>StandardOutPath</key><string>/tmp/wiki-weekly.out</string>
    <key>StandardErrorPath</key><string>/tmp/wiki-weekly.err</string>
</dict>
</plist>
```

```bash
# Replace YOUR_USERNAME and super-repo path, then:
launchctl load ~/Library/LaunchAgents/com.wiki.compile.plist
launchctl load ~/Library/LaunchAgents/com.wiki.weekly.plist
launchctl list | grep wiki
```

---

## 5. Optional: VS Code graph view

Install the **Obsidian Visualizer** extension in VS Code for a lightweight graph view without Obsidian:

```
Cmd+Shift+X > Search "Obsidian Visualizer" > Install
```

Or use `/wiki-graph` to generate a standalone HTML graph.

---

## 6. Initialise and seed

See Step 2 of the Claude Code prompt below.

---

## Claude Code setup prompt

Open Claude Code in your super-repo root and paste this:

```
Read wiki-kb/SKILL.md and wiki-kb/references/installation.md.

Execute the full installation:

1. Create the wiki directory structure:
   wiki/raw/inbox, wiki/raw/processed, wiki/raw/processed/failed, wiki/raw/sessions, wiki/raw/docs, wiki/raw/articles
   wiki/architecture, wiki/product, wiki/principles, wiki/projects, wiki/reports, wiki/reports/archive, wiki/archive

2. Copy all 8 command files from wiki-kb/commands/ to .claude/commands/.

3. Copy wiki-kb/agents/wiki-compiler.md to .claude/agents/.

4. Copy wiki-kb/references/SECURITY.md to .claude/references/.

5. Merge the wiki hooks into the existing .claude/settings.json:
   - Add the wiki SessionStart hook to the existing SessionStart array
   - Add the wiki Stop hook to the existing Stop array
   Keep all existing agentic-eng hooks unchanged.

6. Run /wiki-status to initialise index.md, log.md, wip.md, tags.md, and domain sub-indexes.

7. Add this line to the end of the Guidelines section in .claude/commands/checkpoint.md:
   "After writing CHECKPOINT.md, suggest: Run /wiki-ingest CHECKPOINT.md to compile this session's decisions into the portfolio wiki."

8. Add this as step 0 in .claude/agents/architecture-explainer.md (before its existing process):
   "Check wiki/architecture/ and wiki/architecture/INDEX.md for relevant cross-project patterns. Reference existing wiki pages that relate to this project's architecture."

9. Ingest CLAUDE.md as the first wiki source:
   /wiki-ingest CLAUDE.md

10. Confirm by showing: all /wiki commands available, contents of wiki/index.md, contents of wiki/log.md, and the updated hooks in .claude/settings.json.

Do not modify files in wiki-kb/. That is the source archive. All installed files go into .claude/ and wiki/.
```

### Skills format (alternative)

If your Claude Code setup uses `.claude/skills/[name]/SKILL.md` directories instead of `.claude/commands/[name].md` flat files, replace step 2 in the prompt above with:

```
For each of the 8 wiki command files in wiki-kb/commands/, create a
skill directory under .claude/skills/:

  .claude/skills/wiki-ingest/SKILL.md
  .claude/skills/wiki-query/SKILL.md
  .claude/skills/wiki-compile/SKILL.md
  (and so on for all 8)

Each SKILL.md should have proper frontmatter (name, description) and
the full body content from the original command file.

Also install wiki-kb/SKILL.md as .claude/skills/wiki-kb/SKILL.md
(the umbrella skill).
```

Both formats work. Use whichever matches your existing setup.

### Multi-project setups

If the wiki lives in a central repo and serves multiple projects:

1. **Set WIKI_ROOT.** Export in your shell profile: `export WIKI_ROOT="$HOME/path/to/repo-with-wiki"`. All wiki commands resolve paths against this variable rather than assuming `wiki/` is in the current working directory.

2. **Distribute hooks.** Add the wiki hooks to every project's settings file (or settings template if you use a setup script). The SessionStart hook silently skips when `wiki/index.md` is not in the current directory, so it's safe to include everywhere.

3. **Symlink skills (if using skills format).** Make wiki skills available globally:
   ```bash
   for d in /path/to/repo/.claude/skills/wiki-*/; do
     ln -sf "$d" ~/.claude/skills/"$(basename "$d")"
   done
   ```

---

## After Claude Code finishes

Seed additional project documents:

```
/wiki-ingest your-project-prd.md --project alpha
/wiki-ingest your-project-setup-guide.md --project alpha
```

Then verify:
```
/wiki-status
```

---

## Quick reference

| Task | Command |
|---|---|
| Ingest a document | `/wiki-ingest [path]` |
| Ask the wiki | `/wiki-query [question]` |
| Save an answer back | `/wiki-query [question] --save` |
| Process inbox | `/wiki-compile` |
| Health check | `/wiki-lint` |
| Challenge decisions | `/wiki-challenge` |
| Wiki stats | `/wiki-status` |
| 30-day review | `/wiki-review` |
| Visual graph | `/wiki-graph` |
| Clip a web article | `wiki-clip [url]` (terminal) |
