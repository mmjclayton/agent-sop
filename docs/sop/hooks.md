# Hooks Guidance

Last updated: 2026-04-08

How to use Claude Code hooks to automate enforcement of the Agent SOP. Hooks turn manual checklists into automated gates that run every session without relying on the agent to remember.

---

## Why Hooks Matter

Manual checklists depend on the agent following them. Hooks do not. A hook fires every time a specific event occurs, regardless of what the agent is doing or whether it remembered to read the checklist. Automated enforcement is always more reliable than manual compliance.

Hooks live in `~/.claude/settings.json` (user scope) or `.claude/settings.json` (project scope). They execute shell commands in response to lifecycle events and tool calls.

---

## Hook Types

| Type | When it fires | Use for |
|------|---------------|---------|
| `PreToolUse` | Before a tool executes | Blocking gates: secret scanning, lint checks, push review |
| `PostToolUse` | After a tool executes | Logging, format checks, type checking |
| `SessionStart` | When a new session begins | Auto-loading context files, environment setup |
| `SessionEnd` | When a session terminates | Saving session state, cleanup |
| `PreCompact` | Before context compaction | Preserving state before memory is compressed |
| `Stop` | After the agent produces each response | Pattern extraction, batch formatting, notifications |

**Key constraints:**
- `PreToolUse` hooks can block execution (non-zero exit code stops the tool call)
- `PostToolUse` hooks cannot block but can warn
- `Stop` hooks run after every agent response, not just at session end
- Hooks receive JSON on stdin with context about the event
- Keep blocking hooks fast (under 200ms) to avoid degrading the session

---

## Reference Implementations

### a. SessionStart: Auto-read context files

Automates steps 1-3 of the session start checklist. When the session begins, this hook reads CLAUDE.md, agent-memory.md, and project_resume.md so the agent starts with full context.

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "cat CLAUDE.md docs/agent-memory.md 2>/dev/null; cat ~/.claude/projects/*/memory/project_resume.md 2>/dev/null; echo '--- Session context loaded ---'"
          }
        ],
        "description": "Auto-load CLAUDE.md, agent-memory.md, and project_resume.md at session start"
      }
    ]
  }
}
```

**What this does:** Feeds the content of the three core context files to the agent as the session starts. The agent still needs to run `git log` and read the Backlog item manually, but the heaviest context loading is automated.

**Customisation:** Replace the wildcard path for project_resume.md with the specific project hash path for your project if you want precision.

---

### b. SessionEnd / PreCompact: Trigger end-of-session checklist

Reminds the agent to run the session end checklist when the session ends or context compaction approaches. At 60% context capacity, the agent should wrap up and update tracking files.

```json
{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'IMPORTANT: Context compaction is about to occur. Run the session end checklist NOW: update Backlog.md, feature-map.md, agent-memory.md, build plan batch log, and project_resume.md. Commit docs/ changes with the work.'"
          }
        ],
        "description": "Remind agent to run session end checklist before context compaction"
      }
    ],
    "SessionEnd": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Session ending. Verify that the session end checklist was completed: Backlog, feature-map, agent-memory, build plan, project_resume all updated.'"
          }
        ],
        "description": "Session end verification reminder"
      }
    ]
  }
}
```

**Why PreCompact and not just SessionEnd:** Context compaction can happen mid-session when the window fills up. PreCompact fires before the compression, giving the agent a chance to persist state before older context is lost.

---

### c. Pre-commit quality gate

Blocks commits that contain lint errors, secrets, or debug statements. Runs as a `PreToolUse` hook on Bash commands that match commit patterns.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "echo \"$TOOL_INPUT\" | grep -qE 'git commit' && { git diff --cached --name-only | xargs grep -lE '(console\\.log|debugger|PRIVATE KEY|sk-[a-zA-Z0-9]{20,})' 2>/dev/null && echo 'BLOCKED: Found console.log, debugger statements, or potential secrets in staged files. Remove them before committing.' && exit 1; exit 0; } || exit 0"
          }
        ],
        "description": "Block commits containing console.log, debugger, or potential secrets"
      }
    ]
  }
}
```

**What it catches:**
- `console.log` statements left in committed code
- `debugger` statements
- Private keys and API key patterns (e.g. `sk-...`)

**What it does not catch:** This is a lightweight first pass. For thorough secret scanning, use a dedicated tool like `gitleaks` or `trufflehog` as part of your CI pipeline.

---

### d. Git push review reminder

Prompts the user to confirm before any `git push` executes. Prevents accidental pushes to wrong branches or before review is complete.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "echo \"$TOOL_INPUT\" | grep -qE 'git push' && echo 'REVIEW REMINDER: About to push to remote. Verify: correct branch, all tests passing, session end checklist complete.' || exit 0"
          }
        ],
        "description": "Review reminder before git push"
      }
    ]
  }
}
```

**Note:** This hook warns but does not block. To make it blocking, change the exit code to 1 after the echo. Blocking pushes is recommended for production branches.

---

### e. Post-edit type check

Runs `tsc --noEmit` after TypeScript file edits to catch type errors immediately rather than at commit time. Only applies to TypeScript projects.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "echo \"$TOOL_INPUT\" | grep -qE '\\.(ts|tsx)' && npx tsc --noEmit 2>&1 | head -20 || exit 0",
            "timeout": 30
          }
        ],
        "description": "Run TypeScript type check after editing .ts/.tsx files"
      }
    ]
  }
}
```

**Customisation for other languages:**
- Python: replace with `mypy` or `pyright`
- Rust: replace with `cargo check`
- Go: replace with `go vet`

---

### f. Pattern extraction on Stop

Evaluates each agent response for reusable decisions, gotchas, or patterns and appends them to `docs/agent-memory.md`. This is the simplest form of continuous learning (see SOP Section 12 for the full pattern).

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'If this response contained a reusable decision, data model invariant, gotcha, or named utility function, consider appending it to docs/agent-memory.md before the session ends.'",
            "async": true,
            "timeout": 5
          }
        ],
        "description": "Prompt for pattern extraction after each agent response"
      }
    ]
  }
}
```

**This is a prompt, not automation.** True automated extraction requires parsing the session transcript and classifying patterns, which is a more complex implementation. This hook serves as a lightweight reminder. See the continuous learning pattern in SOP Section 12 for the full approach.

---

## Combining Hooks

A complete SOP-aligned hooks configuration combines all six reference implementations:

```json
{
  "hooks": {
    "SessionStart": [
      { "matcher": "*", "hooks": [{ "type": "command", "command": "cat CLAUDE.md docs/agent-memory.md 2>/dev/null; echo '--- Context loaded ---'" }], "description": "Auto-load context" }
    ],
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": "..." }], "description": "Pre-commit quality gate" },
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": "..." }], "description": "Git push review" }
    ],
    "PostToolUse": [
      { "matcher": "Edit|Write", "hooks": [{ "type": "command", "command": "..." }], "description": "Post-edit type check" }
    ],
    "PreCompact": [
      { "matcher": "*", "hooks": [{ "type": "command", "command": "..." }], "description": "Session end checklist reminder" }
    ],
    "Stop": [
      { "matcher": "*", "hooks": [{ "type": "command", "command": "...", "async": true }], "description": "Pattern extraction prompt" }
    ],
    "SessionEnd": [
      { "matcher": "*", "hooks": [{ "type": "command", "command": "..." }], "description": "End verification" }
    ]
  }
}
```

**Placement:** User-scope hooks go in `~/.claude/settings.json`. Project-scope hooks go in `.claude/settings.json` (committed to git). User-scope hooks apply to all projects. Project-scope hooks are shared with all contributors.

**Security note:** Project-scope hooks from cloned repos execute in your environment. Review them before trusting a new project. See `docs/sop/security.md` for MCP and supply chain guidance.

---

## When to Use Hooks vs Manual Checklists

| Scenario | Use hooks | Use manual checklist |
|----------|-----------|---------------------|
| Secret scanning before commit | Yes | No |
| Loading context at session start | Yes | Fallback only |
| Reminding about session end updates | Yes | Always (hooks are a supplement) |
| Complex architectural decisions | No | Yes |
| First-time project setup | No | Yes |
| Type checking after edits | Yes (code projects) | No |

Hooks handle the repeatable, mechanical parts. Checklists handle the judgment calls. Both are needed.
