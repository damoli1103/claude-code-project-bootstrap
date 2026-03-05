# Planning Format Reference

Templates for files in the `.planning/` directory. Claude reads this when generating actual project files.

## PLAN.md Format

Plans live in `.planning/phases/NN-phase-name/NN-PP-PLAN.md`.

### Frontmatter

```yaml
---
phase: 01-feature-name
plan: 01
title: Short descriptive title
wave: 1                        # Plans in same wave with different files_modified run in parallel
depends_on: []                 # Plan IDs (e.g., ["01-01"]) that must complete first
files_modified:                # For parallel conflict detection
  - path/to/file-a.swift
  - path/to/file-b.swift
requirements:                  # REQ-IDs this plan satisfies
  - REQ-01
  - REQ-02

must_haves:
  truths:                      # Observable statements that must be TRUE after execution
    - "X replaces Y in all call sites"
    - "Build passes with zero warnings"
    - "Tests cover the new behavior"
  artifacts:                   # Files that must exist with specific content
    - path: "src/model.swift"
      provides: "SyncOrigin enum"
      contains: "enum SyncOrigin"
    - path: "tests/model_tests.swift"
      provides: "SyncOrigin tests"
      contains: "func testSyncOrigin"
  key_links:                   # Connections between components that must be wired
    - from: "GestureHandler"
      to: "appModel.syncOrigin"
      via: "set to .gesture before writing"
    - from: "ControlPanel"
      to: "appModel.selectedEntity"
      via: "reads current selection for UI display"
---
```

### Body Structure

```xml
<objective>
One sentence: what this plan achieves and why.
</objective>

<context>
Background information the executing agent needs. Include:
- What exists already (current state)
- Why this change is needed
- Relevant architectural constraints
</context>

<interfaces>
Types, protocols, or APIs this plan must conform to:
- Input types and their shapes
- Output types and their shapes
- Protocols to implement
</interfaces>

<tasks>
<task id="1" name="Short name">
  <action>
  Specific implementation steps. Include file paths and code patterns.
  </action>
  <verify>
  How to verify this task is done correctly.
  </verify>
  <done>
  Observable outcome when complete.
  </done>
</task>

<task id="2" name="Short name" depends="1">
  <action>
  Steps for task 2.
  </action>
  <verify>
  Verification steps.
  </verify>
  <done>
  Observable outcome.
  </done>
</task>
</tasks>

<verification>
Final verification after all tasks complete:
1. Build passes: [command]
2. Tests pass: [command]
3. Must_haves truths confirmed
4. Must_haves artifacts exist
5. Must_haves key_links wired
</verification>

<success_criteria>
- [ ] [Criterion 1 — maps to a must_haves truth]
- [ ] [Criterion 2 — maps to a must_haves artifact]
- [ ] [Criterion 3 — maps to a must_haves key_link]
</success_criteria>
```

## SUMMARY.md Format

Post-execution summaries live in `.planning/phases/NN-phase-name/NN-PP-SUMMARY.md`.

```yaml
---
phase: 01-feature-name
plan: 01
title: Short descriptive title
status: completed
duration: "~X minutes"
---
```

```markdown
## What Was Done
- [Key changes made]

## Files Changed
| File | Change |
|------|--------|
| path/to/file.swift | Added X, modified Y |

## Key Decisions
- [Decisions made during execution and why]

## Gotchas
- [Unexpected issues and how they were resolved]

## Must-Haves Verification
- [x] Truth: "X replaces Y in all call sites" — confirmed
- [x] Artifact: src/model.swift provides SyncOrigin enum — exists
- [x] Key link: GestureHandler -> appModel.syncOrigin — wired
```

## VERIFICATION.md Format

Phase-level verification lives in `.planning/phases/NN-phase-name/NN-VERIFICATION.md`.

```markdown
# Phase [NN] Verification: [Phase Name]

## Truth Table

| # | Truth Statement | Verified | Evidence |
|---|----------------|----------|----------|
| 1 | [From must_haves.truths across all plans] | [ ] | |
| 2 | [Next truth] | [ ] | |

## Artifact Check

| # | Path | Must Provide | Must Contain | Exists | Correct |
|---|------|-------------|-------------|--------|---------|
| 1 | src/model.swift | SyncOrigin enum | `enum SyncOrigin` | [ ] | [ ] |

## Key Link Verification

| # | From | To | Via | Wired |
|---|------|----|----|-------|
| 1 | GestureHandler | appModel.syncOrigin | set to .gesture before writing | [ ] |

## Build & Test

| Check | Command | Result |
|-------|---------|--------|
| Build | `[build command]` | [ ] pass |
| Tests | `[test command]` | [ ] pass |

## Phase Result

- **Status:** [ ] PASS / [ ] FAIL
- **Notes:** [Any observations]
- **Ready for next phase:** [ ] yes / [ ] no
```

## STATE.md Format

```markdown
# State

## Current Position
- **Phase:** [NN] [name]
- **Plan:** [NN-PP] [name]
- **Status:** [in progress / blocked / complete]

## Velocity
- **Plans completed:** [N] / [total]
- **Phases completed:** [N] / [total]

## Decisions
- [Key decisions accumulated across the project]

## Blockers
- [Current blockers, if any]
```

## .continue-here.md Format

```markdown
# Continue Here

## Last Workflow
[Which superpowers skill or manual workflow was running]

## Status
[What was completed, what remains]

## Completed
- [List of completed items in current work]

## Remaining
- [List of remaining items]

## Next Action
[Specific next step to take — be precise enough to resume without re-reading everything]
```

## config.json Schema

```json
{
  "parallel_agents": true,
  "pause_between_phases": true,
  "verification_after_phases": true,
  "auto_commit_after_build": true
}
```

| Key | Default | Description |
|-----|---------|-------------|
| `parallel_agents` | `true` | Spawn parallel agents for plans in the same wave with non-overlapping files |
| `pause_between_phases` | `true` | Stop and wait for user confirmation between phases |
| `verification_after_phases` | `true` | Run VERIFICATION.md checks after each phase |
| `auto_commit_after_build` | `true` | Auto-commit after successful build+test |
