---
name: audit-project
description: Use when user wants to check an existing project against Claude Code workflow best practices, find missing hooks, weak guardrails, or gaps in CLAUDE.md configuration. Triggered by /audit-project command.
disable-model-invocation: true
---

# /audit-project — Audit Claude Code Project Configuration

You are auditing the current project's Claude Code setup against best practices from the `claude-code-project-bootstrap` skill. Check every item, report findings, and offer to fix gaps.

## Audit Checklist

Run through ALL checks below. For each, report one of:
- **PASS** — meets best practice
- **WARN** — exists but could be improved (explain what)
- **FAIL** — missing or broken (explain what's needed)

### 1. Git & GitHub

- [ ] `.git/` directory exists (project is a git repo)
- [ ] Has a GitHub remote (`git remote -v`)
- [ ] Not on `main` branch directly (should be on a feature branch)
- [ ] `.gitignore` exists
- [ ] `.gitignore` includes `.claude/settings.local.json`
- [ ] `.gitignore` includes `.env` and secret patterns (`*.key`, `*.pem`)
- [ ] `.gitignore` includes OS files (`.DS_Store`, `Thumbs.db`)
- [ ] `.gitignore` includes stack-specific entries (node_modules, __pycache__, target/, etc.)

### 2. README

- [ ] `README.md` exists
- [ ] Has project description
- [ ] Has getting started / installation instructions
- [ ] Has contributing section (ideally mentioning Claude Code guardrails)

### 3. Claude Code Hooks

Check `.claude/hooks/` directory:

- [ ] `validate-bash.sh` exists and is executable
  - [ ] Blocks `rm -rf`
  - [ ] Blocks `git push --force`
  - [ ] Blocks `git reset --hard`
  - [ ] Blocks `git checkout main`
  - [ ] Blocks `git clean -f`
  - [ ] Gates commits behind build check
- [ ] `protect-files.sh` exists and is executable
  - [ ] Blocks writes outside project directory
  - [ ] Blocks `.env*` files
  - [ ] Blocks credential files (`credentials.json`, `secrets.json`, `*.key`, `*.pem`)
  - [ ] Has stack-specific blocks enabled (if applicable)
- [ ] `build-check.sh` exists and is executable
  - [ ] Has a build command uncommented (not just the fallback "no build system" message)
  - [ ] Build command matches the actual project stack

### 4. settings.json

Check `.claude/settings.json`:

- [ ] File exists
- [ ] Has `PreToolUse` hook for `Bash` → `validate-bash.sh`
- [ ] Has `PreToolUse` hook for `Write|Edit` → `protect-files.sh`
- [ ] Paths use `$CLAUDE_PROJECT_DIR` (portable, not hardcoded)
- [ ] Timeouts are set (recommended: 10s)

### 5. settings.local.json

- [ ] File exists (user permissions)
- [ ] Is NOT committed to git (`git ls-files .claude/settings.local.json` should return empty)
- [ ] Has basic git operations in allow-list

### 6. CLAUDE.md

Check `CLAUDE.md` at project root:

- [ ] File exists
- [ ] Has **Project Context** section (what the project is, stack, target)
- [ ] Has **Architecture** section (directory structure, dependency direction)
- [ ] Has **Change Protocol** section with:
  - [ ] Build command specified
  - [ ] Test command specified
  - [ ] Auto-commit instruction
  - [ ] "Never commit if build fails" instruction
- [ ] Has **Git Workflow** section with:
  - [ ] Branch naming convention
  - [ ] Conventional commit types and scopes
- [ ] Has **Post-Merge Protocol** (fetch, new branch, delete old)
- [ ] Has **Critical Rules** (Do / Don't lists)

### 7. Security Scan

Quick check for common security issues:

- [ ] No `.env` files committed (`git ls-files '*.env*'` should return empty)
- [ ] No credential files committed (`git ls-files '*credentials*' '*secrets*' '*.key' '*.pem'`)
- [ ] No hardcoded secrets visible in CLAUDE.md or settings files

## Report Format

After running all checks, present results as a table:

```
## Audit Results

| Area            | Status | Details                          |
|-----------------|--------|----------------------------------|
| Git & GitHub    | PASS   | Repo configured, .gitignore good |
| README          | WARN   | Missing contributing section     |
| Hooks           | FAIL   | No build-check.sh found         |
| settings.json   | PASS   | All hooks wired                  |
| settings.local  | PASS   | Not committed                    |
| CLAUDE.md       | WARN   | Missing post-merge protocol      |
| Security        | PASS   | No secrets in git                |
```

## Offer Fixes

After the report, ask the user:

> I found N issues (X FAIL, Y WARN). Want me to fix them?

If yes, fix all FAIL items first, then WARN items. For each fix:
1. Explain what you're creating/changing
2. Create or edit the file
3. Confirm the fix

After all fixes, re-run the audit to verify everything passes.
