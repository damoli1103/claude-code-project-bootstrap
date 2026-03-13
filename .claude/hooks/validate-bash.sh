#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$COMMAND" ] && exit 0

# === Universal blocks (with helpful alternatives) ===
if echo "$COMMAND" | grep -qE 'rm\s+(-rf|--recursive\s+--force)'; then
  echo "BLOCKED: recursive forced deletion is not allowed. Use 'git clean -n' to preview, or remove specific files individually." >&2
  exit 2
fi
if echo "$COMMAND" | grep -qE 'git\s+push\s+(-f|--force)'; then
  echo "BLOCKED: force push is not allowed. Use 'git push --force-with-lease' if you must overwrite, or better: create a new commit." >&2
  exit 2
fi
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  echo "BLOCKED: hard reset discards all changes permanently. Use 'git stash' to save work, or 'git reset --soft' to keep changes staged." >&2
  exit 2
fi
if echo "$COMMAND" | grep -qE 'git\s+checkout\s+(main|master)(\s|$)'; then
  echo "BLOCKED: checking out main directly is not allowed. Use: git checkout -b <branch-name> origin/main" >&2
  exit 2
fi
if echo "$COMMAND" | grep -qE 'git\s+clean\s+-f'; then
  echo "BLOCKED: clean with force flag permanently deletes untracked files. Use 'git clean -n' to preview what would be deleted first." >&2
  exit 2
fi

# === Bash file-write protection ===
check_path() {
  local TARGET="$1"
  [ -z "$TARGET" ] && return 0

  # Resolve relative paths
  [[ "$TARGET" != /* ]] && TARGET="$CLAUDE_PROJECT_DIR/$TARGET"

  # Allow Claude memory and .claude directories (plans, hooks, config)
  [[ "$TARGET" == "$HOME/.claude/"* ]] && return 0
  [[ "$TARGET" == *"/.claude/"* ]] && return 0

  # Block sensitive directories
  for SENSITIVE_DIR in "$HOME/.ssh" "$HOME/.aws" "$HOME/.gnupg" "$HOME/.config/gh"; do
    if [[ "$TARGET" == "$SENSITIVE_DIR"* ]]; then
      echo "BLOCKED: '$TARGET' is in a sensitive directory ($SENSITIVE_DIR). Do not read or write credentials." >&2
      exit 2
    fi
  done

  # Block outside project
  [[ "$TARGET" != "$CLAUDE_PROJECT_DIR"* ]] && echo "BLOCKED: '$TARGET' is outside the project directory. Use Write/Edit tool for in-project files, or ask the user." >&2 && exit 2

  # Block secrets by filename
  local BASENAME
  BASENAME=$(basename "$TARGET")
  case "$BASENAME" in
    .env|.env.local|.env.production|.env.staging|.env.development) echo "BLOCKED: cannot write to env file '$BASENAME' via Bash." >&2; exit 2;;
    credentials.json|secrets.json|secrets.yaml) echo "BLOCKED: cannot write to credentials file '$BASENAME' via Bash." >&2; exit 2;;
    *.key|*.pem|*.p12|*.pfx) echo "BLOCKED: cannot write to key/cert file '$BASENAME' via Bash." >&2; exit 2;;
  esac

  return 0
}

# Check cp/mv destination (last argument)
if echo "$COMMAND" | grep -qE '^\s*(cp|mv)\s'; then
  DEST=$(echo "$COMMAND" | awk '{print $NF}')
  check_path "$DEST"
fi

# Check tee target
if echo "$COMMAND" | grep -qE '\btee\s'; then
  TEE_TARGET=$(echo "$COMMAND" | sed -n 's/.*tee\s\+\(-a\s\+\)\?\([^ |;>&]*\).*/\2/p')
  check_path "$TEE_TARGET"
fi

# Check output redirects (> and >>)
if echo "$COMMAND" | grep -qE '>\s*/|>\s*~'; then
  REDIR_TARGET=$(echo "$COMMAND" | grep -oE '>{1,2}\s*[^ ;|&]+' | tail -1 | sed 's/>{1,2}\s*//')
  check_path "$REDIR_TARGET"
fi

# === Branch name validation ===
# Skip if command is gh/curl/etc. that may contain git examples in body text
if echo "$COMMAND" | grep -qE 'git\s+checkout\s+-b\s+' && ! echo "$COMMAND" | grep -qE '^(gh|curl|echo|cat|printf)\s'; then
  BRANCH_NAME=$(echo "$COMMAND" | sed -n 's/.*git checkout -b \([^ ]*\).*/\1/p')
  if [ -n "$BRANCH_NAME" ] && ! echo "$BRANCH_NAME" | grep -qE '^(feature|fix|test|refactor|docs|chore|perf)/'; then
    echo "BLOCKED: branch name '$BRANCH_NAME' does not follow convention. Use one of: feature/, fix/, test/, refactor/, docs/, chore/, perf/" >&2
    exit 2
  fi
fi

# === Pre-commit gates ===
# Skip if command is gh/curl/etc. that may contain git examples in body text
if echo "$COMMAND" | grep -qE 'git\s+commit' && ! echo "$COMMAND" | grep -qE '^(gh|curl|echo|cat|printf)\s'; then

  # Build gate
  "$CLAUDE_PROJECT_DIR"/.claude/hooks/build-check.sh || { echo "BLOCKED: build or tests failed — fix before committing." >&2; exit 2; }

  # Commit message validation
  COMMIT_MSG=$(echo "$COMMAND" | sed -n "s/.*-m[[:space:]]*[\"']\([^\"']*\)[\"'].*/\1/p")
  if [ -n "$COMMIT_MSG" ]; then
    if ! echo "$COMMIT_MSG" | grep -qE '^(feat|fix|test|docs|refactor|chore|perf|ci)(\(.+\))?: .+'; then
      echo "BLOCKED: commit message does not follow conventional format." >&2
      echo "  Expected: <type>(<scope>): <subject>" >&2
      echo "  Types: feat, fix, test, docs, refactor, chore, perf, ci" >&2
      echo "  Example: docs(skill): update permission templates" >&2
      exit 2
    fi
  fi

  # Diff size warning — non-blocking
  DIFF_STAT=$(git diff --cached --shortstat 2>/dev/null)
  if [ -n "$DIFF_STAT" ]; then
    FILE_COUNT=$(echo "$DIFF_STAT" | grep -oE '[0-9]+ file' | grep -oE '[0-9]+')
    LINE_CHANGES=$(echo "$DIFF_STAT" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+')
    LINE_DELETIONS=$(echo "$DIFF_STAT" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+')
    TOTAL_LINES=$(( ${LINE_CHANGES:-0} + ${LINE_DELETIONS:-0} ))
    if [ "${FILE_COUNT:-0}" -gt 30 ] || [ "$TOTAL_LINES" -gt 1000 ]; then
      echo "WARNING: Large commit detected — $DIFF_STAT. Consider splitting into smaller commits." >&2
    fi
  fi

  # Success feedback
  echo "All pre-commit checks passed: build OK, message valid, ready to commit."
fi

# === Post-merge guard ===
# After gh pr merge, auto-transition to a clean state
if echo "$COMMAND" | grep -qE 'gh\s+pr\s+merge'; then
  echo "PR merged. Post-merge cleanup will be needed after this command completes."
  echo "Run: git fetch origin main && git checkout -b <next-branch> origin/main"
fi

# === Stale branch detection ===
# Block git push on branches whose remote tracking branch no longer exists
# Only triggers when upstream tracks the branch's own remote (not origin/main)
if echo "$COMMAND" | grep -qE 'git\s+push(\s|$)'; then
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$CURRENT_BRANCH" ] && [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)
    if [ -n "$UPSTREAM" ]; then
      # Extract the remote branch name from upstream (e.g., "origin/feature/foo" → "feature/foo")
      UPSTREAM_BRANCH="${UPSTREAM#origin/}"
      # Only check if upstream tracks this branch's own remote (not main/master)
      if [ "$UPSTREAM_BRANCH" = "$CURRENT_BRANCH" ]; then
        REMOTE_REF="refs/remotes/$UPSTREAM"
        if ! git show-ref --verify --quiet "$REMOTE_REF" 2>/dev/null; then
          echo "BLOCKED: remote branch '$UPSTREAM' no longer exists (likely deleted after PR merge)." >&2
          echo "" >&2
          echo "Post-merge cleanup:" >&2
          echo "  1. git fetch origin main" >&2
          echo "  2. git checkout -b <next-branch> origin/main" >&2
          echo "  3. git branch -D $CURRENT_BRANCH" >&2
          exit 2
        fi
      fi
    fi
  fi
fi

# === Post-merge: allow git branch -D for old merged branches ===
# git branch -D is normally risky, but safe for cleaning up merged branches
if echo "$COMMAND" | grep -qE 'git\s+branch\s+-[dD]\s+'; then
  BRANCH_TO_DELETE=$(echo "$COMMAND" | sed -n 's/.*git branch -[dD] \([^ ]*\).*/\1/p')
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  # If the command chains checkout-then-delete, the checkout will switch away first — allow it
  CHAINS_CHECKOUT=false
  if echo "$COMMAND" | grep -qE 'git\s+checkout\s+-b\s+.*&&.*git\s+branch\s+-[dD]'; then
    CHAINS_CHECKOUT=true
  fi
  if [ "$BRANCH_TO_DELETE" = "$CURRENT_BRANCH" ] && [ "$CHAINS_CHECKOUT" = "false" ]; then
    echo "BLOCKED: cannot delete the branch you're currently on. Switch to a new branch first." >&2
    echo "  git checkout -b <next-branch> origin/main" >&2
    exit 2
  fi
  # Allow deletion of merged branches (non-blocking)
  if git branch --merged origin/main 2>/dev/null | grep -qE "^\s+$BRANCH_TO_DELETE\$"; then
    echo "Branch '$BRANCH_TO_DELETE' is merged — safe to delete."
  fi
fi

exit 0
