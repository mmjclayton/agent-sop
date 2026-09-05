<!-- SOP-Version: 2026-09-04 -->
# Harness Configuration Reference

Last updated: 2026-08-03

How to configure Claude Code's runtime — hooks and context primitives — to enforce the SOP automatically rather than relying on agent memory. Merges the former `hooks.md` and `context-management.md` on 2026-04-17 as part of the P32 trim.

---

## Core Rules

1. **Default settings are sufficient for most projects.** The SOP's 60% context threshold and manual checklists work without any harness configuration.
2. **Use hooks for repeatable, mechanical enforcement.** Secret scans, session-start context loading, type checks. Anything that should fire every time, regardless of whether the agent remembered.
3. **Use context primitives (clearing, compaction) only for long sessions.** Clearing: > 30 minutes, or once tool results reach ~15% of the context window. Compaction: > 60 minutes, or at the SOP's 60% threshold.
4. **Always exclude the memory tool from clearing.** Clearing memory tool results destroys the agent's ability to recall what it saved: `exclude_tools: ["memory"]`.
5. **Keep blocking hooks fast.** Under 200ms to avoid degrading the session.
6. **Treat project-scope hooks from cloned repos as untrusted.** Review before use — they execute in your environment. See `docs/sop/security.md`.
7. **Placement:** user-scope hooks in `~/.claude/settings.json`, project-scope in `.claude/settings.json`.
8. **Combine hooks with checklists, don't replace.** Hooks handle the mechanical; checklists handle judgment.
9. **Hooks must fail open.** A failing hook must never block the Claude Code session. Catch errors, log them, let the session continue. For blocking gates that genuinely must stop a bad action (secret scan, destructive command), fail closed with a clear error message — but add a circuit breaker (e.g. suppress after 3 consecutive failures in the same session) so a broken hook can't strand the agent.

---

## Hook Types

| Type | When it fires | Use for |
|------|---------------|---------|
| `PreToolUse` | Before a tool executes | Blocking gates: secret scanning, lint checks, push review |
| `PostToolUse` | After a tool executes | Logging, format checks, type checking |
| `SessionStart` | When a new session begins (`source`: startup, resume, clear, compact) | Auto-loading context files; stdout reaches the model |
| `UserPromptSubmit` | Before each user prompt is processed | Late context load after a `cd`; stdout reaches the model |
| `SessionEnd` | When a session terminates | Cleanup only; output never reaches the model |
| `PreCompact` | Before context compaction | Preserving state before memory is compressed |
| `Stop` | After the agent produces each response | Pattern extraction, notifications |

`PreToolUse` and `Stop` hooks block on exit 2, with stderr fed back to the model (`Stop` then continues the turn). `PostToolUse` hooks cannot block but can warn. Hooks receive JSON on stdin, including `cwd` (follows the session's `cd`) and `session_id`. Project-scope hooks load only from the directory Claude Code was launched in; anything that must fire for a session launched elsewhere belongs user-scope.

---

## Context Primitives

### Tool-result clearing (`clear_tool_uses_20250919`)

| Setting | Recommended | Notes |
|---------|-------------|-------|
| `keep` | 4 | Retains the 4 most recent tool results |
| `exclude_tools` | `["memory"]` | Never clear memory tool results |
| Trigger | Tool results at ~15% of the context window | Check periodically, not every turn |

### Compaction (`compact_20260112`)

| Setting | Recommended | Notes |
|---------|-------------|-------|
| Trigger | 60% of the model's context window | Aligns with SOP's 60% rule |
| Minimum | 25% of the context window | Below this, compaction removes too much |

**Express these as proportions, not absolute token counts.** Until 2026-08-03 this table read `120K tokens (60% of 200K)`, which was correct when written and wrong by 5x once Claude Opus 5 shipped with a 1M-token default window. The SOP's own threshold at `claude-agent-sop.md` is percentage-only for exactly this reason: it self-adjusts across model generations, whereas a worked example in absolute tokens silently rots. Resolve the absolute figure for the model in use with `/usage`.

**What survives:** architecture, current task, recent decisions. **What to preserve explicitly:** current task state, file paths being edited, test results, Common Mistakes entries.

**Interaction with SOP:** 60% threshold says "wrap up and run session end checklist." With compaction, EITHER wrap up manually OR compact and continue. Compaction extends the session but risks losing detail — the manual approach is safer for complex multi-file work.

### Memory tool (`memory_20250818`)

File-backed persistent notes. The API primitive behind `docs/agent-memory.md`. For Claude Code sessions use `agent-memory.md` (git-committed). For Managed Agents API use memory stores (see `docs/guides/managed-agents-integration.md`).

### Combined impact
- Compaction alone: ~50% peak context reduction
- Clearing alone: ~48% peak context reduction
- Both together: ~70% reduction (not additive — different content)

---

## Reference Implementations

### a. SessionStart + UserPromptSubmit — context load (shipped: `scripts/hooks/sop-session-context.sh`)

Installed user-scope by `scripts/install-hooks.sh`. Prints, once per session and project, the resume snapshot and recent sessions, plus — only when not the default — in-flight lines, `[IN PROGRESS]` Backlog items, commits since the last session record, dirty trackers, an outstanding ship gate, dirty sibling worktrees, and a stale upstream sync (P104: a clean repo prints no "(none)" lines). Covers what `/restart-sop` used to read; the Backlog item for the task is still a deliberate read.

Registered on both events because Claude Code adds hook stdout to the model's context only for `SessionStart`, `UserPromptSubmit`, `UserPromptExpansion` and `PostModelSwitch`, and because sessions launched outside the project only reach it after a `cd` — the first prompt inside the project is what loads it. `SessionStart` with `source` `compact` or `clear` reprints, since the earlier context is gone.

The resume file is resolved through `scripts/resolve-resume-path.sh`, never globbed. An earlier reference implementation here read `~/.claude/projects/*/memory/project_resume.md`, which matches every project's resume file on the machine — including the catch-all directory shared by home-launched sessions — and so could load another project's state as this session's context.

### b. Stop — session-end drift (shipped: `scripts/hooks/sop-stop-drift.sh`)

Replaces the earlier `PreCompact` / `SessionEnd` echo reminders, which the action-vs-ceremony test rules out: a print the agent can ignore is indistinguishable from no print, and `SessionEnd` output never reaches the model at all. The Stop hook instead exits 2 — which Claude Code feeds back to the model and continues the turn — only on a code project (P103) and only when a fact holds: commits after the newest `docs/recent-work/` entry, uncommitted tracker files, or a ship-sop auto-mode diff with code lines and no gate report naming an ancestor of HEAD. It fires once per commit state and stays silent otherwise.

Stdout from a `Stop` hook is written to the debug log and never shown to the model. A Stop hook that "injects a directive via stdout" does nothing; this is why ship-sop's project-scope hook produced no gate run in four months even after its wiring was fixed.

### b2. PreToolUse(Bash) — push gate (shipped: `scripts/hooks/sop-push-gate.sh`)

Refuses `git push` and `gh pr create` when ship-sop auto-mode applies on a code project and no report covers HEAD — matched on what would execute (simple command, `bash -c` / `sh -c` / `eval` body, command substitution), never on text inside a quoted argument. The only surface among the three that can actually refuse. `SOP_SKIP_GATE=1` in the command bypasses once and is appended to `.ship/bypass.log`.

All three resolve the repository from the hook's `cwd` input, not the launch directory, and stay silent outside SOP projects. Whether a project is code is one rule for every consumer — `sop_project_type` in `sop-lib.sh`, run as `scripts/hooks/sop-project-type.sh`: an explicit `**Project type:**` line in CLAUDE.md, else the heuristics in `compliance-checklist.md` — so the ship gate, the context block, `/update-sop` and `/ship` cannot disagree about it (P102). Fixture suite: `docs/benchmark/hook-fixtures/run-tests.sh`.

### c. Pre-commit quality gate

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "echo \"$TOOL_INPUT\" | grep -qE 'git commit' && { git diff --cached --name-only | xargs grep -lE '(console\\.log|debugger|PRIVATE KEY|sk-[a-zA-Z0-9]{20,})' 2>/dev/null && echo 'BLOCKED: debug or secret pattern detected.' && exit 1; exit 0; } || exit 0"
      }]
    }]
  }
}
```

Catches `console.log`, `debugger`, private keys, API key patterns. Lightweight first pass — use `gitleaks`/`trufflehog` in CI for thorough scanning.

### d. Git push review

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "echo \"$TOOL_INPUT\" | grep -qE 'git push' && echo 'REVIEW: correct branch, tests passing, session end checklist done?' || exit 0"
      }]
    }]
  }
}
```

Warns but does not block. Change exit code to 1 to make blocking (recommended for production branches).

### e. Post-edit type check

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "echo \"$TOOL_INPUT\" | grep -qE '\\.(ts|tsx)' && npx tsc --noEmit 2>&1 | head -20 || exit 0",
        "timeout": 30
      }]
    }]
  }
}
```

Swap `tsc` for `mypy`/`pyright` (Python), `cargo check` (Rust), `go vet` (Go).

### f. Learnings capture (PreCompact + Stop)

Captures ephemeral mid-session signal — surprises about the codebase, friction worth fixing, hook or skill recommendations — into `docs/agent-memory/learnings/`. Reviewed and archived by `/update-sop` Step 5. Distinct from durable decisions/gotchas: learnings are pre-decision signal that may turn into a Backlog item, a decision file, or get archived as no-longer-relevant.

```json
{
  "hooks": {
    "PreCompact": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "echo 'Context compaction imminent. If anything has surprised you about this codebase mid-session, write docs/agent-memory/learnings/YYYY-MM-DDTHH-MM_<agent-id>_<slug>.md with: (1) surprises about the codebase, (2) key learnings for future sessions, (3) hook or workflow recommendations, (4) skill recommendations. Skip if nothing noteworthy.'"
      }]
    }],
    "Stop": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "echo 'Session ending. If this session surfaced anything surprising about the codebase that did not crystallise into a decision/gotcha file, drop a learning at docs/agent-memory/learnings/YYYY-MM-DDTHH-MM_<agent-id>_<slug>.md. Skip if nothing noteworthy.'"
      }]
    }]
  }
}
```

**Why stdout, not `decision: block`.** PreCompact stdout injects into the post-compact session. Stop stdout injects into the next user turn if one occurs; if the session genuinely ends with no follow-up prompt, the stdout is lost. The SOP-side safety net is `/update-sop` Step 5 — captured-but-not-acted-on files (or sessions that captured nothing) are caught next time `/update-sop` reviews the folder.

The alternative — `decision: block` at Stop — has two distinct downsides. It forces an extra Claude turn after the user has signalled "I'm done", which is user-disruptive. And if the blocking hook itself triggers another Claude response that re-fires Stop, you can loop indefinitely without a `stop_hook_active` guard reading the input payload. We avoid both by staying stdout-only.

**Coexistence with other Stop hooks** (e.g. ship-sop's auto-ship-hook). Multiple entries in `.hooks.Stop[]` all fire. The learnings hook is non-blocking (exits 0 with stdout), so it never interferes with sibling Stop hooks. For the install pattern (idempotent jq-merge against an existing `.claude/settings.json`), see ship-sop's `setup.sh` — the same merge shape works for either hook. agent-sop itself does not install this hook; consumers wire the snippet above into their own settings.

**Filename and folder lifecycle:** see `docs/agent-memory/learnings/README.md`. Archived (never deleted) during `/update-sop` Step 5 per CLAUDE.md Rule 2.

**Boundary note:** the agent-sop project documents this hook pattern but does not install it. Consumers who want the capture flow wire it themselves into their own `.claude/settings.json`. The same applies to the older one-line "pattern extraction on Stop" sketch this section replaces (which prompted appends to `agent-memory.md` directly — superseded by the dedicated `learnings/` folder).

---

## When to Use Hooks vs Manual Checklists

| Scenario | Hook | Manual |
|----------|------|--------|
| Secret scanning before commit | Yes | No |
| Loading context at session start | Yes | Fallback |
| Reminding about session end | Yes | Always |
| Architectural decisions | No | Yes |
| First-time project setup | No | Yes |
| Type checking after edits | Yes | No |

Hooks handle mechanical. Checklists handle judgment.

---

Source: [Anthropic Context Engineering Cookbook](https://platform.claude.com/cookbook/tool-use-context-engineering-context-engineering-tools)
