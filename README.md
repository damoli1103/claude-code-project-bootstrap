# Claude Code Project Bootstrap

A skill pack for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that sets up guardrails, hooks, and git workflow automation for any development project.

**Claude Code** is Anthropic's CLI tool that lets Claude work directly in your terminal — reading files, running commands, editing code. This skill pack adds safety rails so Claude can work autonomously without accidentally breaking things.

- Blocks destructive commands (force push, `rm -rf`, `git reset --hard`)
- Gates commits behind passing builds and tests
- Protects sensitive files (`.env`, credentials, keys)
- Enforces git conventions (feature branches, conventional commits)
- Scans for hardcoded secrets in every written file
- Auto-formats code after writes (prettier, ruff, rustfmt, etc.)

Works with any stack: Node/TS, Python, Rust, Go, Swift/Xcode, and more.

## Quick Start

Install the skill pack:

```bash
claude install-skill damoli1103/claude-code-project-bootstrap
```

Then open Claude Code in your project directory and run:

```
/bootstrap
```

Claude asks for your project name, stack, and visibility, then creates a GitHub repo with hooks, guardrails, and a `CLAUDE.md` — ready to go.

## Skills Included

| Skill | Command | What It Does |
|-------|---------|-------------|
| `claude-code-project-bootstrap` | *(auto-loaded)* | Knowledge base with hook scripts, templates, and patterns. Claude reads this automatically when relevant. |
| `bootstrap` | `/bootstrap` | Interactive setup wizard. Creates GitHub repo, hooks, CLAUDE.md from scratch. |
| `audit-project` | `/audit-project` | Audits an existing project against best practices. Reports PASS/WARN/FAIL and offers to fix gaps. |
| `init-planning` | `/init-planning` | Sets up structured `.planning/` directory with project definition, codebase analysis, requirements, and roadmap for multi-phase projects. |

## What Gets Created

### /bootstrap output

```
your-project/
├── .claude/
│   ├── hooks/
│   │   ├── validate-bash.sh      # blocks destructive commands, gates commits, validates messages + branches
│   │   ├── protect-files.sh      # blocks writes to sensitive files
│   │   ├── build-check.sh        # auto-detects stack, runs build + tests
│   │   ├── scan-secrets.sh       # warns on hardcoded secrets in written files
│   │   ├── session-check.sh      # verifies hooks setup on session start
│   │   └── auto-format.sh        # formats files after write (if formatters installed)
│   ├── statusline.sh             # context window monitor (progressive color)
│   ├── settings.json             # hook wiring + statusline (committed to git)
│   └── settings.local.json       # user allow-list (NOT committed)
├── .gitignore
├── README.md
├── CLAUDE.md                      # project instructions for Claude
└── ...
```

### /init-planning output

```
.planning/
├── PROJECT.md                 # What we're building, core value, constraints
├── REQUIREMENTS.md            # REQ-IDs with phase traceability
├── ROADMAP.md                 # Phases, plans, success criteria, progress
├── STATE.md                   # Current position, velocity, decisions, blockers
├── .continue-here.md          # Session resume point
├── config.json                # Workflow preferences
├── codebase/                  # Brownfield analysis (7 docs)
│   ├── ARCHITECTURE.md        # Layers, patterns, data flow
│   ├── STRUCTURE.md           # Directory layout, file purposes
│   ├── STACK.md               # Languages, frameworks, deps
│   ├── CONVENTIONS.md         # Naming, code style, patterns
│   ├── TESTING.md             # Test framework, coverage, strategy
│   ├── CONCERNS.md            # Tech debt, risks, fragile areas
│   └── INTEGRATIONS.md        # APIs, data storage, external services
└── phases/
    └── NN-phase-name/
        ├── NN-CONTEXT.md      # Phase decisions + boundary
        ├── NN-PP-PLAN.md      # Executable plan with must_haves
        ├── NN-PP-SUMMARY.md   # Post-execution summary
        └── NN-VERIFICATION.md # Phase quality gate
```

## Commands

### /bootstrap — Set Up a New Project

The bootstrap wizard walks you through creating a fully-configured Claude Code project. It:

1. **Asks you** for project name, stack (Node/TS, Python, Rust, Go, Swift/Xcode), visibility (public/private), and description
2. **Creates a GitHub repo** (or uses your existing one)
3. **Generates** `.gitignore`, `README.md`, and `CLAUDE.md` tailored to your stack
4. **Installs 6 hooks** in `.claude/hooks/` (see Hook Reference below)
5. **Wires hooks** in `.claude/settings.json`
6. **Explains permission tiers** and lets you choose a level
7. **Commits and pushes** the initial setup

If the project already has a git repo, README, or other files, the wizard skips those steps instead of overwriting.

### /audit-project — Check Your Setup

Run this on any existing project to verify its Claude Code setup against best practices. Checks 45+ items across 7 areas:

| Area | What It Checks |
|------|---------------|
| Git & GitHub | Repo exists, remote configured, .gitignore complete |
| README | Exists, has description, install instructions, contributing guide |
| Hooks | All 6 hooks exist, are executable, have correct patterns and behaviors |
| settings.json | PreToolUse, PostToolUse, SessionStart hooks wired, portable paths, timeouts set |
| settings.local | Exists, not committed to git |
| CLAUDE.md | Has all required sections (context, architecture, change protocol, git workflow) |
| Security | No .env or credentials committed |

Reports results as a PASS/WARN/FAIL table and offers to fix everything it finds.

### /init-planning — Structured Project Planning

Use this for multi-phase projects that need organized planning. It:

1. **Detects** whether you're in a brownfield (existing code) or greenfield project
2. **Maps the codebase** (brownfield only) — creates 7 analysis documents covering architecture, stack, conventions, testing, concerns, integrations, and structure
3. **Deep questions** (2-4 rounds) to understand goals, priorities, constraints, and scope
4. **Creates planning files** — PROJECT.md, REQUIREMENTS.md, ROADMAP.md, STATE.md
5. **Saves workflow preferences** in config.json (parallel agents, pause between phases, auto-commit)

**The `must_haves` system:** Each plan declares observable truths, required artifacts, and key links that must be verified after execution. This gives executing agents unambiguous success criteria — no guessing about what "done" means.

**Session continuity:** When `.planning/.continue-here.md` exists, Claude reads it at session start and resumes where the last session left off. STATE.md tracks decisions and blockers across sessions.

**Wave-based parallel execution:** Plans in the same wave with non-overlapping files can run in parallel via multiple agents. After all agents complete, a single build verification confirms everything works together.

**Integration with superpowers skills:** init-planning creates project-level structure; superpowers skills (brainstorming, writing-plans, dispatching-parallel-agents, etc.) handle task-level execution within that structure.

## How Hooks Work

Claude Code hooks are shell scripts that run at specific points in the tool lifecycle. They read JSON from stdin and control execution via exit codes:

| Hook Event | When It Runs | Scripts |
|------------|-------------|---------|
| `PreToolUse` | Before a tool executes | validate-bash.sh (Bash), protect-files.sh (Write/Edit) |
| `PostToolUse` | After a tool executes | scan-secrets.sh (Write/Edit), auto-format.sh (Write/Edit) |
| `SessionStart` | When a session begins | session-check.sh |

Exit codes control execution:

| Exit Code | Meaning |
|-----------|---------|
| `0` | Allow — tool proceeds |
| `1` | Soft block — Claude sees error, may retry |
| `2` | Hard block — tool execution denied |

The hooks are registered in `.claude/settings.json` (committed to git, shared with team). The `settings.local.json` (per-user permission allow-list) is NOT committed.

## Hook Reference

| Hook | Trigger | Blocking? | What It Does |
|------|---------|-----------|-------------|
| `validate-bash.sh` | PreToolUse (Bash) | Yes (exit 2) | Blocks `rm -rf`, force push, `git reset --hard`, `git checkout main`, `git clean -f`. Validates branch names and commit messages. Gates commits behind build-check.sh. Warns on large diffs (>30 files or >1000 lines). Blocks Bash file writes (`cp`, `mv`, `tee`, redirects) to sensitive paths. |
| `protect-files.sh` | PreToolUse (Write/Edit) | Yes (exit 2) | Blocks writes to `.env`, `credentials.json`, `secrets.yaml`, `*.key`, `*.pem`. Blocks writes outside the project directory. Allows `.claude/` paths. |
| `build-check.sh` | Called by validate-bash.sh | Yes (exit 1) | Auto-detects stack (Node, Rust, Go, Python, Xcode) and runs the appropriate build + test commands. Only runs on `git commit`. |
| `scan-secrets.sh` | PostToolUse (Write/Edit) | No (exit 0) | Scans written files for API keys, tokens, private keys, JWTs, and hardcoded secret assignments. Warns but never blocks. |
| `session-check.sh` | SessionStart | No (exit 0) | Verifies hooks directory, CLAUDE.md, and all 6 hook scripts exist and are executable. Suggests `/audit-project` if anything is missing. |
| `auto-format.sh` | PostToolUse (Write/Edit) | No (exit 0) | Runs available formatters: prettier (JS/TS), ruff or black (Python), rustfmt (Rust), swiftformat (Swift), gofmt (Go). Silently skips if formatter not installed. |

## Supported Stacks

The build-check hook auto-detects your stack and runs the right commands:

| Stack | Build Command | Test Command |
|-------|--------------|-------------|
| Node/TS | `npm run build` | `npm test` |
| Python | `python -m py_compile` | `pytest` |
| Rust | `cargo build` | `cargo test` |
| Go | `go build ./...` | `go test ./...` |
| Swift/Xcode | `xcodebuild build -scheme ...` | *(configure in CLAUDE.md)* |

## Permissions (settings.local.json)

The `settings.local.json` file controls which actions Claude can auto-approve without prompting. It's per-user and NOT committed to git.

Three tiers are available:

- **Minimal (conservative)** — Only auto-approves git operations (`git add`, `git commit`, `git push`, `gh pr`) and `ls`. You'll be prompted for everything else. Best for new users getting comfortable with Claude.

- **Balanced (recommended)** — Full autonomy within the project: reads anywhere, writes to `~/.claude/` (memory, plans), git and GitHub CLI operations. Destructive commands (`rm`, `cp`, `mv`) and writes outside the project still prompt for approval. Deny rules block reading `~/.ssh`, `~/.aws`, `~/.gnupg`, `~/.config/gh`. This is the sweet spot for most users.

- **Full Auto-Accept (power user)** — Broad read/write/bash permissions everywhere except deny-listed paths. Claude can read, write, and delete files **anywhere on your machine**. Bash commands execute without confirmation. Only use this after you're comfortable with the hooks and understand that `protect-files.sh` guards Write/Edit calls but Bash file operations (`cp`, `mv`, `rm`) bypass it.

Here's the recommended Balanced configuration:

```json
{
  "permissions": {
    "allow": [
      "WebSearch", "WebFetch",
      "Read",
      "Write(~/.claude/**)", "Edit(~/.claude/**)",
      "Bash(git *)", "Bash(gh *)",
      "Bash(ls *)", "Bash(mkdir *)"
    ],
    "deny": [
      "Read(~/.ssh/**)", "Read(~/.aws/**)",
      "Read(~/.gnupg/**)", "Read(~/.config/gh/**)"
    ]
  }
}
```

Adapt the `allow` list to your stack — add `Bash(npm *)`, `Bash(cargo *)`, `Bash(go *)`, `Bash(xcodebuild *)`, etc.

For full JSON templates for all three tiers, see the main SKILL.md (which Claude reads automatically when configuring permissions).

## Context Window Monitor (Status Line)

A persistent status bar showing how much of Claude's context window is used, with progressive color coding:

| Usage | Color | Meaning |
|-------|-------|---------|
| 0-49% | Green | Plenty of room |
| 50-74% | Yellow | Getting there |
| 75-89% | Red | Running low |
| 90-100% | Bold Red + warning | Clear soon |

The status line is created at `.claude/statusline.sh` (or `~/.claude/statusline.sh` for global use) and configured in `settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

The `/bootstrap` wizard sets this up automatically.

## Installation

### Option 1: Install from GitHub (recommended)

```bash
claude install-skill damoli1103/claude-code-project-bootstrap
```

### Option 2: Manual install

Clone this repo and copy the skills to your personal skills directory:

```bash
git clone https://github.com/damoli1103/claude-code-project-bootstrap.git
cp -r claude-code-project-bootstrap/skills/* ~/.claude/skills/
```

## Important Notes

- **Hooks only run inside Claude Code** — manual terminal commands and IDE commits are not affected. These are guardrails for AI-assisted development, not a full security system.
- **These are accident prevention, not security** — anyone with terminal access can bypass the hooks. They prevent Claude from making destructive mistakes, not intentional actions.
- **build-check.sh runs your full build on every commit** — this may be slow on large projects. Consider using a lighter check (e.g. `tsc --noEmit` instead of `npm run build`) or removing the build gate if it becomes a bottleneck.
- **validate-bash.sh blocks `git checkout main`** — this is by design to enforce feature-branch workflow. Use `git checkout -b <branch-name> origin/main` instead.
- **protect-files.sh blocks `.env` writes** — create your environment files manually before bootstrapping, or temporarily disable the hook.
- **scan-secrets.sh is non-blocking** — it only warns, never blocks. Review warnings and move secrets to environment variables.
- **auto-format.sh requires formatters to be installed** — it silently skips formatting if the formatter isn't available. Install prettier, ruff, rustfmt, etc. for your stack.
- **The generated CLAUDE.md instructs Claude to auto-commit** after successful builds. Edit or remove this instruction if you prefer manual commits.
- **`.planning/` is optional** — only use `/init-planning` for multi-phase projects. For simple features, jump straight into coding with hooks and guardrails.

## FAQ

**Can I use this on an existing project?**
Yes. Run `/audit-project` to check your current setup, then let it fix any gaps. Or run `/bootstrap` — it skips steps that are already done (existing repo, README, etc.).

**Do hooks affect my terminal?**
No. Hooks only run inside Claude Code sessions. Your manual git commands, IDE, and terminal are completely unaffected.

**What if build-check is too slow?**
Edit `.claude/hooks/build-check.sh` to use a lighter check (e.g. `tsc --noEmit` instead of `npm run build`), or remove the build gate from `validate-bash.sh` by commenting out the `build-check.sh` call.

**Do I need all 6 hooks?**
No. Remove any hook from `.claude/settings.json` to disable it. The hooks are independent — removing one doesn't affect the others.

**What's the difference between SKILL.md and README?**
SKILL.md is what Claude reads when it needs to create hooks, configure settings, or reference patterns. README (this file) is documentation for humans browsing the repo.

**When should I use /init-planning vs just coding?**
Use `/init-planning` for multi-phase milestones with 3+ phases, brownfield projects needing systematic analysis, or work spanning multiple sessions. For single features or quick fixes, skip it — hooks and guardrails work fine on their own.

## Contributing

Issues and PRs welcome. If you add support for a new stack or improve a hook pattern, please share it back.

## License

MIT
