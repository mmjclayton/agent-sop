# Context Management Reference

API-level primitives for managing context window usage in Claude Code sessions. These augment the SOP's 60% context threshold rule with surgical control.

## Primitives

### Tool-Result Clearing (`clear_tool_uses_20250919`)

Replaces old tool results (file reads, API responses) with placeholders, freeing context for new work.

| Setting | Recommended value | Notes |
|---------|-------------------|-------|
| `keep` | 4 | Retains the 4 most recent tool results |
| `exclude_tools` | `["memory"]` | Never clear memory tool results |
| Trigger | ~30K tokens of tool results | Check periodically, not every turn |

**When to use:** Long sessions with many file reads. A session that reads 20 files accumulates ~40K tokens of tool results. Clearing keeps the 4 most recent and frees the rest.

**When NOT to use:** Short tasks (< 10 tool calls). The overhead of clearing is not worth it.

### Compaction (`compact_20260112`)

Summarises earlier conversation turns into a condensed form, preserving high-level context while freeing token space.

| Setting | Recommended value | Notes |
|---------|-------------------|-------|
| Trigger threshold | 120K tokens (60% of 200K) | Aligns with SOP's 60% context rule |
| Minimum | 50K tokens | Below this, compaction removes too much |

**What survives compaction:** High-level facts (project architecture, current task, recent decisions). Testing showed 3/3 high-level facts survive vs 0/3 obscure details.

**What to preserve explicitly:** Current task state, file paths being edited, test results, Common Mistakes entries.

**Interaction with SOP:** The SOP's 60% threshold rule says "wrap up and run session end checklist." With compaction, you can EITHER wrap up (manual) OR compact and continue (automatic). Compaction extends the session but risks losing detail. The SOP's manual approach is safer for complex multi-file work. Compaction is better for long single-file sessions.

### Memory Tool (`memory_20250818`)

File-backed persistent notes with view/create/replace/delete operations. The model decides what to save.

**Relationship to agent-memory.md:** The `memory_20250818` tool is the API primitive. The SOP's `docs/agent-memory.md` is the manual equivalent. For Claude Code sessions, use agent-memory.md (committed to git, visible to all contributors). For Managed Agents API sessions, use memory stores (see SOP Section 17).

**Key rule:** When using tool-result clearing, always add the memory tool to the `exclude_tools` list. Clearing memory tool results destroys the agent's ability to recall what it saved.

## Composition

All three primitives can run simultaneously. Measured impact:
- Compaction alone: ~50% peak context reduction
- Clearing alone: ~48% peak context reduction
- Both together: ~70% peak context reduction (not additive — they target different content)

## When to configure these

- **Default (most projects):** The SOP's 60% threshold rule is sufficient. No API configuration needed.
- **Long sessions (> 30 minutes):** Enable tool-result clearing with `keep: 4`.
- **Very long sessions (> 60 minutes):** Enable both clearing and compaction.
- **Managed Agents API:** Compaction is built into the harness. Focus on clearing and memory stores.

Source: [Anthropic Context Engineering Cookbook](https://platform.claude.com/cookbook/tool-use-context-engineering-context-engineering-tools)
