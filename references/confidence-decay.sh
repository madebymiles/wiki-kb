#!/bin/bash
# wiki-decay: Metadata-only confidence decay. Zero token cost.
# Scans wiki page frontmatter for last_verified dates >90 days old.
# Downgrades confidence without reading page content or calling an LLM.
#
# Called by wiki-compile.sh cron or run manually.
# Usage: wiki-decay.sh [wiki-root]

set -euo pipefail

WIKI_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null)/wiki}"
TODAY=$(date '+%Y-%m-%d')
THRESHOLD_DATE=$(date -v-90d '+%Y-%m-%d' 2>/dev/null || date -d '90 days ago' '+%Y-%m-%d')
DECAY_COUNT=0
ARCHIVE_COUNT=0

if [ ! -d "$WIKI_ROOT" ]; then
    echo "Wiki not found at $WIKI_ROOT"
    exit 1
fi

# Process each .md file (excluding raw/, reports/, archive/, index, log, wip, tags)
find "$WIKI_ROOT" -name '*.md' \
    -not -path '*/raw/*' \
    -not -path '*/reports/*' \
    -not -path '*/archive/*' \
    -not -name 'index.md' \
    -not -name 'INDEX.md' \
    -not -name 'log.md' \
    -not -name 'wip.md' \
    -not -name 'tags.md' | while read -r PAGE; do

    # Extract last_verified from frontmatter
    LAST_VERIFIED=$(grep '^last_verified:' "$PAGE" | head -1 | awk '{print $2}' | tr -d '"' | tr -d "'")
    CONFIDENCE=$(grep '^confidence:' "$PAGE" | head -1 | awk '{print $2}' | tr -d '"' | tr -d "'")
    LAST_LINTED=$(grep '^last_linted:' "$PAGE" | head -1 | awk '{print $2}' | tr -d '"' | tr -d "'")

    if [ -z "$LAST_VERIFIED" ] || [ -z "$CONFIDENCE" ]; then
        continue
    fi

    # Check if older than 90 days
    if [[ "$LAST_VERIFIED" < "$THRESHOLD_DATE" ]]; then
        NEW_CONFIDENCE=""
        case "$CONFIDENCE" in
            high)   NEW_CONFIDENCE="medium" ;;
            medium) NEW_CONFIDENCE="low" ;;
            low)    NEW_CONFIDENCE="stale" ;;
            stale)
                # Check if stale for two consecutive lints (archival candidate)
                if [ -n "$LAST_LINTED" ]; then
                    STALE_THRESHOLD=$(date -v-180d '+%Y-%m-%d' 2>/dev/null || date -d '180 days ago' '+%Y-%m-%d')
                    if [[ "$LAST_VERIFIED" < "$STALE_THRESHOLD" ]]; then
                        # Move to archive
                        ARCHIVE_DIR="$WIKI_ROOT/archive"
                        mkdir -p "$ARCHIVE_DIR"
                        RELATIVE=$(echo "$PAGE" | sed "s|$WIKI_ROOT/||")
                        ARCHIVE_PATH="$ARCHIVE_DIR/$RELATIVE"
                        mkdir -p "$(dirname "$ARCHIVE_PATH")"
                        mv "$PAGE" "$ARCHIVE_PATH"
                        ARCHIVE_COUNT=$((ARCHIVE_COUNT + 1))
                        echo "ARCHIVED: $RELATIVE (stale >180 days)"
                        continue
                    fi
                fi
                ;;
        esac

        if [ -n "$NEW_CONFIDENCE" ]; then
            # Update confidence in frontmatter using sed
            sed -i.bak "s/^confidence: $CONFIDENCE/confidence: $NEW_CONFIDENCE/" "$PAGE"
            rm -f "${PAGE}.bak"
            DECAY_COUNT=$((DECAY_COUNT + 1))
            RELATIVE=$(echo "$PAGE" | sed "s|$WIKI_ROOT/||")
            echo "DECAY: $RELATIVE ($CONFIDENCE -> $NEW_CONFIDENCE)"
        fi
    fi
done

echo ""
echo "Decay complete: $DECAY_COUNT pages downgraded, $ARCHIVE_COUNT pages archived."
