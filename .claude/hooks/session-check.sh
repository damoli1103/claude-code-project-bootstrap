#!/bin/bash
HOOKS_DIR="$CLAUDE_PROJECT_DIR/.claude/hooks"
MISSING=()

# Check hooks directory
[ ! -d "$HOOKS_DIR" ] && MISSING+=("hooks directory (.claude/hooks/)")

# Check CLAUDE.md
[ ! -f "$CLAUDE_PROJECT_DIR/CLAUDE.md" ] && MISSING+=("CLAUDE.md")

# Check each hook exists and is executable
for HOOK in validate-bash.sh protect-files.sh build-check.sh scan-secrets.sh auto-format.sh session-check.sh; do
  if [ ! -f "$HOOKS_DIR/$HOOK" ]; then
    MISSING+=("$HOOK")
  elif [ ! -x "$HOOKS_DIR/$HOOK" ]; then
    MISSING+=("$HOOK (not executable)")
  fi
done

if [ ${#MISSING[@]} -eq 0 ]; then
  echo "Session check: all hooks present and executable, CLAUDE.md found."
else
  echo "WARNING: Missing or misconfigured items: ${MISSING[*]}" >&2
  echo "Run /audit-project to diagnose and fix." >&2
fi

exit 0
