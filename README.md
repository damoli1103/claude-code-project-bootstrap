# Claude Code Project Bootstrap

A skill pack for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that sets up guardrails, hooks, and git workflow automation for any development project.

## What It Does

- **Blocks destructive commands** — prevents dangerous git operations and file deletions
- **Gates commits behind passing builds and tests** — auto-detects your stack and runs the right commands
- **Protects sensitive files** — `.env`, credentials, keys, certs can't be accidentally written
- **Enforces git workflow** — feature branches, conventional commits, post-merge cleanup
- **Validates commit messages** — enforces conventional commit format before allowing commits
- **Validates branch names** — ensures branches follow naming convention (feature/, fix/, etc.)
- **Warns on large commits** — flags commits with >30 files or >1000 lines changed
- **Scans for secrets** — warns when API keys, tokens, or private keys appear in written files
- **Auto-formats code** — runs prettier, ruff, rustfmt, swiftformat, or gofmt after writes
- **Health checks on start** — verifies hooks and CLAUDE.md are present each session
- **Helpful error messages** — blocked actions include suggested alternatives
- **Generates project scaffolding** — README, CLAUDE.md, .gitignore, GitHub repo

Works with any stack: Node/TS, Python, Rust, Go, Swift/Xcode, and more.

## Skills Included

| Skill | Command | What It Does |
|-------|---------|-------------|
| `claude-code-project-bootstrap` | *(auto)* | Knowledge base with hook scripts, templates, patterns. Claude loads this automatically when relevant. |
| `bootstrap` | `/bootstrap` | Interactive setup wizard. Creates GitHub repo, README, hooks, CLAUDE.md from scratch. |
| `audit-project` | `/audit-project` | Audits an existing project against best practices. Reports PASS/WARN/FAIL and offers to fix gaps. |

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

## Usage

### Bootstrap a new project

Open Claude Code in your project directory and run:

```
/bootstrap
```

Claude will ask for your project name, stack, and visibility preference, then create everything:
- GitHub repo (public or private)
- `.gitignore` (stack-aware)
- `README.md`
- `.claude/hooks/` (6 hooks — see below)
- `.claude/settings.json` (hook wiring for PreToolUse, PostToolUse, SessionStart)
- `CLAUDE.md` (project instructions)

### Audit an existing project

Open Claude Code in any project and run:

```
/audit-project
```

Claude checks 45+ items across 7 areas:

| Area | What It Checks |
|------|---------------|
| Git & GitHub | Repo exists, remote configured, .gitignore complete |
| README | Exists, has description, install instructions, contributing guide |
| Hooks | All 6 hooks exist, are executable, have correct patterns and behaviors |
| settings.json | PreToolUse, PostToolUse, SessionStart hooks wired, portable paths, timeouts set |
| settings.local | Exists, not committed to git |
| CLAUDE.md | Has all required sections (context, architecture, change protocol, git workflow) |
| Security | No .env or credentials committed |

Reports results as a table and offers to fix everything it finds.

## What Gets Created

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
│   ├── settings.json             # hook wiring (shared with team)
│   └── settings.local.json       # user allow-list (NOT committed)
├── .gitignore
├── README.md
├── CLAUDE.md                      # project instructions for Claude
└── ...
```

## How Hooks Work

Claude Code hooks are shell scripts that run at specific points in the tool lifecycle:

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

## Supported Stacks

The build-check hook auto-detects your stack and runs the right commands:

| Stack | Build Command | Test Command |
|-------|--------------|-------------|
| Node/TS | `npm run build` | `npm test` |
| Python | `python -m py_compile` | `pytest` |
| Rust | `cargo build` | `cargo test` |
| Go | `go build ./...` | `go test ./...` |
| Swift/Xcode | `xcodebuild build -scheme ...` | *(configure in CLAUDE.md)* |


## Heads Up

- **Hooks only run inside Claude Code** — manual terminal commands and IDE commits are not affected. These are guardrails for AI-assisted development, not a full security system.
- **build-check.sh runs your full build on every commit** — this may be slow on large projects. Consider using a lighter check (e.g. `tsc --noEmit` instead of `npm run build`) or removing the build gate if it becomes a bottleneck.
- **validate-bash.sh blocks `git checkout main`** — this is by design to enforce feature-branch workflow. Use `git checkout -b <branch> origin/main` instead.
- **protect-files.sh blocks `.env` writes** — create your environment files manually before bootstrapping, or temporarily disable the hook.
- **scan-secrets.sh is non-blocking** — it only warns, never blocks. Review warnings and move secrets to environment variables.
- **auto-format.sh requires formatters to be installed** — it silently skips formatting if the formatter isn't available. Install prettier, ruff, rustfmt, etc. for your stack.
- **The generated CLAUDE.md instructs Claude to auto-commit** after successful builds. Edit or remove this instruction if you prefer manual commits.
- **These are accident prevention, not security** — anyone with terminal access can bypass the hooks. They prevent Claude from making destructive mistakes, not intentional actions.

## Contributing

Issues and PRs welcome. If you add support for a new stack or improve a hook pattern, please share it back.

## License

MIT
