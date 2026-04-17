<!-- SOP-Version: 2026-04-17 -->
# Multi-Agent Context Routing

Applies when multiple agents work in parallel on the same project. Routing the right context to each agent based on task type saves 15-25% of token spend while maintaining quality on the tasks that matter.

Extracted from SOP Section 16 on 2026-04-17 as part of the P32 trim. For single-agent work, this guide is not needed — the core SOP covers it.

## Context tiers

| Task type | Context needed | What to load |
|-----------|---------------|-------------|
| Bug fix (multi-file) | Full | CLAUDE.md + agent-memory.md + build plan |
| Feature (multi-file) | Full | CLAUDE.md + agent-memory.md + build plan |
| Refactor (cross-cutting) | Full | CLAUDE.md + agent-memory.md |
| CSS fix (single property) | Partial | CLAUDE.md Common Mistakes + Design System only |
| Test writing | Minimal | Source file under test only. CLAUDE.md optional. |
| Utility creation | Minimal | CLAUDE.md Common Mistakes only (for naming conventions) |
| Documentation | Minimal | Backlog item only |

## Routing rules

1. **Default to full context.** When in doubt, load everything. The cost of unnecessary context (~5K tokens) is lower than the cost of a wrong turn (rework, production bugs).
2. **Use minimal context only when the task is tagged `[ok-for-automation]`** or is explicitly a single-file, self-contained change.
3. **Test-writing agents should NOT read CLAUDE.md.** Benchmark data shows SOP context adds no quality to test writing and may introduce caution that weakens assertions.
4. **Every agent, regardless of tier, must follow the session end checklist** if it modifies committed files.

## Conflict avoidance

- Each agent works on a **separate branch** and merges sequentially.
- Agents on the same codebase must not modify the same files. Assign files explicitly in the task prompt.
- If two agents need to modify the same file, run them sequentially, not in parallel.
- Documentation conflicts (agent-memory.md, Backlog.md) resolve by appending both entries.
- Code conflicts require human review. Flag in agent-memory.md Gotchas.

## Managed Agents API implementation

When using the Claude Managed Agents API (`api.anthropic.com/v1/agents`), the context routing table maps directly to agent configurations.

**Coordinator agent** (full context):
```json
{
  "name": "Engineering Lead",
  "model": "claude-sonnet-4-6",
  "system": "[Full CLAUDE.md content including Common Mistakes, Dispatch, Definition of Done]",
  "tools": [{"type": "agent_toolset_20260401"}],
  "callable_agents": [
    {"type": "agent", "id": "REVIEWER_ID", "version": 1},
    {"type": "agent", "id": "TEST_WRITER_ID", "version": 1},
    {"type": "agent", "id": "RESEARCHER_ID", "version": 1}
  ]
}
```

**Code reviewer** (read-only, partial context):
```json
{
  "name": "Code Reviewer",
  "model": "claude-sonnet-4-6",
  "system": "[Common Mistakes + Design System + Definition of Done rubrics only]",
  "tools": [{
    "type": "agent_toolset_20260401",
    "default_config": {"enabled": false},
    "configs": [
      {"name": "read", "enabled": true},
      {"name": "grep", "enabled": true},
      {"name": "glob", "enabled": true},
      {"name": "bash", "enabled": true}
    ]
  }]
}
```

**Test writer** (minimal context, write access):
```json
{
  "name": "Test Writer",
  "model": "claude-sonnet-4-6",
  "system": "Write tests. Read the source file under test first. Follow existing test patterns.",
  "tools": [{"type": "agent_toolset_20260401"}]
}
```

**Key patterns:**
- The coordinator has `callable_agents` — specialists do not (only one level of delegation).
- All agents share the same container and filesystem but run in isolated threads with separate context.
- Threads are persistent: the coordinator can send follow-up messages to a specialist that retains its prior context.
- Attach `memory_store` resources for persistent cross-session learnings. Map `docs/agent-memory.md` sections to memory store paths: Common Mistakes → read-only store, Decisions Made → read-write store.
- Use `user.define_outcome` with rubrics from the Definition of Done section for quality-gated work — a separate grader evaluates the output and sends feedback for iteration.

See `docs/guides/managed-agents-integration.md` (deferred — P33) for the full Managed Agents reference.
