#!/bin/bash
cd "$CLAUDE_PROJECT_DIR"

# === Markdown/documentation-only project ===
# No build system — validate markdown files are well-formed

# Check for broken markdown syntax (unclosed code blocks)
ERRORS=0
for md in $(find . -name "*.md" -not -path "./.git/*" 2>/dev/null); do
  # Count triple-backtick fences — should be even
  FENCES=$(grep -c '```' "$md" 2>/dev/null || echo 0)
  if [ $(( FENCES % 2 )) -ne 0 ]; then
    echo "ERROR: $md has unclosed code fence (found $FENCES backtick fences)" >&2
    ERRORS=$((ERRORS + 1))
  fi
done

if [ "$ERRORS" -gt 0 ]; then
  echo "Build check failed: $ERRORS markdown file(s) have issues." >&2
  exit 1
fi

echo "Build check passed: all markdown files valid."
exit 0
