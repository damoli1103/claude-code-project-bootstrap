# Claude Code Project Bootstrap — Claude Code Instructions

## Project Context
- A skill pack for Claude Code that sets up guardrails, hooks, and git workflow automation for any development project
- Markdown-only repo — no build step, no compiled code
- Contains: main skill (SKILL.md), slash commands (/bootstrap, /audit-project), hook templates, permission templates
- Published at: github.com/damoli1103/claude-code-project-bootstrap

## Architecture
```
.
├── SKILL.md                              # Main skill — knowledge base with all hook scripts, templates, patterns
├── README.md                             # GitHub-facing documentation
├── LICENSE                               # MIT
├── CLAUDE.md                             # This file
├── .gitignore
├── .claude/
│   ├── hooks/                            # Hooks for THIS repo (eating our own dog food)
│   │   ├── validate-bash.sh
│   │   ├── protect-files.sh
│   │   ├── build-check.sh               # Validates markdown (unclosed code fences)
│   │   ├── scan-secrets.sh
│   │   ├── session-check.sh
│   │   └── auto-format.sh
│   └── settings.json                     # Hook wiring
└── skills/
    ├── audit-project/SKILL.md            # /audit-project slash command
    ├── bootstrap/SKILL.md                # /bootstrap slash command
    └── claude-code-project-bootstrap/    # Nested copy for install-skill compatibility
        └── SKILL.md
```

## Change Protocol
- After modifying any `.md` file, verify code fences are balanced (even number of triple backticks)
- The `build-check.sh` hook validates this automatically before commits
- Keep the nested `skills/claude-code-project-bootstrap/SKILL.md` in sync with root `SKILL.md`
- Auto-commit after successful validation

## Git Workflow
- Never checkout main directly. Branch from origin/main.
- Branch naming: feature/<desc>, fix/<desc>, docs/<desc>, refactor/<desc>, chore/<desc>
- Conventional commits: <type>(<scope>): <subject>
  - Types: feat, fix, docs, refactor, chore
  - Scopes: skill, hooks, permissions, bootstrap, audit, readme

## Post-Merge Protocol
1. git fetch origin main
2. git checkout -b <next-branch> origin/main
3. git branch -d <merged-branch>

## Critical Rules
### Do
- Keep root SKILL.md and skills/claude-code-project-bootstrap/SKILL.md in sync
- Update README.md when permission templates or hook behavior changes
- Update /bootstrap and /audit-project slash commands when adding new hooks or tiers
- Test hook scripts are executable after creating them (chmod +x)

### Don't
- Don't work directly on main — always use feature branches
- Don't force push to main — use PRs
- Don't add real API keys or secrets in examples (use placeholders like `sk-...`)
- Don't break the three-tier permission structure (Minimal → Balanced → Full Auto-Accept)
