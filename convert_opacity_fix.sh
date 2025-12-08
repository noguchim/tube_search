#!/bin/bash

# === 設定 ======================
TARGET_BRANCH="convert_warn"  # ← 変換したいブランチ名
SEARCH_DIR="./lib"                   # ← Dart ソースのルート
# ==============================

echo "🚀 Starting opacity conversion"
echo "▶ Switching to branch: $TARGET_BRANCH"

git checkout "$TARGET_BRANCH" || {
  echo "❌ ERROR: Branch $TARGET_BRANCH not found."
  exit 1
}

echo "🔍 Finding Dart files in $SEARCH_DIR ..."
FILES=$(find "$SEARCH_DIR" -type f -name "*.dart")

if [ -z "$FILES" ]; then
  echo "⚠ No Dart files found. Exiting."
  exit 0
fi

echo "🛠 Converting .withOpacity(x) → .withValues(alpha: x)"
for file in $FILES; do
  echo "  - Converting: $file"
  sed -E -i '' 's/\.withOpacity\(([0-9.]+)\)/\.withValues(alpha: \1)/g' "$file"
done

echo "📦 Adding changes to Git..."
git add .

echo "📝 Creating commit..."
git commit -m "Replace deprecated withOpacity() with withValues(alpha: x)"

echo "✅ Conversion completed (commit only — no push performed)"

