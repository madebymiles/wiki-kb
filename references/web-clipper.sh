#!/bin/bash
# wiki-clip: Convert a URL to markdown and drop into wiki/raw/inbox/
# Replaces Obsidian Web Clipper. Requires: brew install pandoc
#
# Usage:
#   wiki-clip https://example.com/article
#   wiki-clip https://example.com/article --project beta --domain product

set -euo pipefail

URL="${1:?Usage: wiki-clip <url> [--project <abbr>] [--domain <name>]}"
PROJECT="unassigned"
DOMAIN="unassigned"

shift
while [[ $# -gt 0 ]]; do
    case "$1" in
        --project) PROJECT="$2"; shift 2 ;;
        --domain) DOMAIN="$2"; shift 2 ;;
        *) echo "Unknown: $1"; exit 1 ;;
    esac
done

WIKI_INBOX="${WIKI_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo "$HOME/super-repo")}/wiki/raw/inbox"
mkdir -p "$WIKI_INBOX"

SLUG=$(echo "$URL" | sed 's|https\?://||;s|[^a-zA-Z0-9]|-|g' | cut -c1-60)
DATE=$(date '+%Y-%m-%d')
FILENAME="article-${DATE}-${SLUG}.md"

if ! command -v pandoc &>/dev/null; then
    echo "Error: brew install pandoc"
    exit 1
fi

pandoc -f html -t markdown --wrap=none "$URL" -o "/tmp/wiki-clip-raw.md" 2>/dev/null
CONTENT=$(cat /tmp/wiki-clip-raw.md)
rm -f /tmp/wiki-clip-raw.md

cat > "${WIKI_INBOX}/${FILENAME}" <<EOF
---
title: $(echo "$URL" | sed 's|https\?://||;s|/.*||')
type: article
source_url: ${URL}
clipped: ${DATE}
project: ${PROJECT}
domain: ${DOMAIN}
compartment: professional
---

# Clipped from ${URL}

${CONTENT}
EOF

echo "Saved: ${WIKI_INBOX}/${FILENAME}"
echo "Compile with /wiki-compile or wait for cron."
