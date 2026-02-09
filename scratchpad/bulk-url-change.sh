#!/bin/bash

# ============ CONFIG =============
OLD_WORD="SilverInit"
NEW_WORD="infra-bootstrap"
BASE_DIR="$HOME/git"
DRY_RUN=true
# ================================

echo "======================================"
echo " Git Repo Keyword Replacement Script "
echo "======================================"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "⚠️  DRY RUN MODE — NO FILES MODIFIED"
else
  echo "⚠️  LIVE MODE — FILES WILL BE MODIFIED"
fi

echo ""

for repo in "$BASE_DIR"/*; do
  if [ -d "$repo/.git" ]; then
    echo "🔍 Scanning repo: $repo"

    files=$(grep -rl "$OLD_WORD" "$repo" --exclude-dir=.git)

    if [ -z "$files" ]; then
      echo "✅ No matches found"
      echo ""
      continue
    fi

    echo "⚠️ Found keyword in:"
    echo "$files"
    echo ""

    if [ "$DRY_RUN" = true ]; then
      echo "Would update:"
      echo "$files"
    else
      # Backup folder
      mkdir -p "$repo/.backup_before_keyword_change"

      while read -r f; do
        cp "$f" "$repo/.backup_before_keyword_change/$(basename "$f").bak"
        sed -i "s|$OLD_WORD|$NEW_WORD|g" "$f"
      done <<< "$files"

      echo "✅ Files updated + backups created"
    fi

    echo ""
  fi
done

echo "✅ Script finished"
