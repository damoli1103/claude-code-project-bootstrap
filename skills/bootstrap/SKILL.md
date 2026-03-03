---
name: bootstrap
description: Use when user wants to set up a new project from scratch with Claude Code guardrails, GitHub repo, README, hooks, and git workflow. Triggered by /bootstrap command.
argument-hint: [project-name or stack]
disable-model-invocation: true
---

# /bootstrap — Set Up a New Claude Code Project

You are bootstrapping a project for Claude Code development. Follow every step below in order. Do NOT skip steps. Ask the user when input is needed.

**REQUIRED REFERENCE:** Read the full `claude-code-project-bootstrap` skill for hook scripts, templates, and patterns. This command is the execution flow — that skill is the knowledge base.

## Step 1: Gather Context

Ask the user (use AskUserQuestion with up to 4 questions):

1. **Project name** — What should the repo/directory be called?
2. **Stack** — What language/framework? (Node/TS, Python, Rust, Go, Swift/Xcode, other)
3. **Visibility** — Public or private GitHub repo?
4. **Description** — One-line project description

If `$ARGUMENTS` is provided, infer what you can and only ask what's missing.

## Step 2: Git + GitHub Repo

Check current state and act accordingly:

```
IF no .git directory:
  → git init
IF no GitHub remote:
  → gh repo create <name> --<visibility> --source=. --push --description "<desc>"
IF already has repo + remote:
  → Skip, confirm to user
```

## Step 3: .gitignore

If no `.gitignore` exists, create one. Always include:

```gitignore
# Claude Code
.claude/settings.local.json

# Secrets
.env
.env.*
*.key
*.pem

# OS
.DS_Store
Thumbs.db
```

Add stack-specific entries based on Step 1 answer:
- **Node/TS:** `node_modules/`, `dist/`, `.next/`, `coverage/`
- **Python:** `__pycache__/`, `*.pyc`, `.venv/`, `*.egg-info/`
- **Rust:** `target/`, `Cargo.lock` (if library)
- **Go:** `bin/`, `vendor/` (if not using modules)
- **Xcode:** `build/`, `DerivedData/`, `*.xcuserdata/`

## Step 4: README.md

If no `README.md` exists, generate one with:
- Project name and description (from Step 1)
- Getting Started (prerequisites, install, dev, test)
- Project Structure (infer from existing files or use placeholder)
- Contributing section mentioning Claude Code guardrails
- License placeholder

If README exists, skip. Do NOT overwrite an existing README.

## Step 5: Hooks

Create `.claude/hooks/` with three scripts from the `claude-code-project-bootstrap` skill:

1. **validate-bash.sh** — blocks rm -rf, force push, reset --hard, checkout main, clean -f; gates commits behind build-check.sh
2. **protect-files.sh** — blocks writes to .env, credentials, keys, files outside project; uncomment stack-specific blocks based on Step 1
3. **build-check.sh** — uncomment the correct build command based on the stack from Step 1

Make all executable: `chmod +x .claude/hooks/*.sh`

## Step 6: settings.json

Create `.claude/settings.json` with PreToolUse hook wiring for Bash → validate-bash.sh and Write|Edit → protect-files.sh.

Do NOT create or modify `settings.local.json` — that's user-specific.

## Step 7: CLAUDE.md

Generate a `CLAUDE.md` tailored to the project:
- Project context (name, stack, description from Step 1)
- Architecture (infer from existing files or create sensible defaults)
- Change Protocol with the correct build/test commands for the stack
- Git Workflow (branch naming, conventional commits with project-relevant scopes)
- Post-Merge Protocol
- Critical Do/Don't rules relevant to the stack

## Step 8: Initial Commit + Push

```bash
git add .gitignore README.md CLAUDE.md .claude/hooks/ .claude/settings.json
git commit -m "chore(infra): bootstrap project with Claude Code hooks and workflow"
git push -u origin main
```

## Step 9: Summary

Print a summary:
- GitHub repo URL
- Files created
- Hooks installed and what they enforce
- Next steps (start a feature branch, install relevant skills, etc.)
