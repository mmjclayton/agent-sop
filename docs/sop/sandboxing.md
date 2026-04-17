<!-- SOP-Version: 2026-04-17 -->
# Sandboxing — Autonomous / Overnight Agent Runs

Applies when agents run without a human in the loop — autonomous loops, overnight automation, untrusted repo review. For interactive sessions, `security.md` alone is sufficient; this file is additive.

Split out from `security.md` on 2026-04-17 as part of the P32 trim.

---

## Why Sandboxing

If the agent is compromised during an unattended run, the blast radius must be small. You won't notice in real time, so containment is the only defence.

---

## Identity Separation

- Do not give the agent your personal accounts (email, Slack, GitHub).
- Use dedicated bot accounts or short-lived scoped tokens.
- If the agent has the same credentials you do, a compromised agent is you.

---

## Runtime Isolation

- Run untrusted repos in containers, devcontainers, or VMs.
- Use `--network=none` for tasks that do not need internet access.
- Restrict filesystem access to the workspace directory only.
- Drop all capabilities and disable privilege escalation.

```yaml
# Docker Compose — isolated agent work
services:
  agent:
    build: .
    user: "1000:1000"
    working_dir: /workspace
    volumes:
      - ./workspace:/workspace:rw
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    networks:
      - agent-internal

networks:
  agent-internal:
    internal: true   # No egress
```

---

## Tool Permissions

- Deny reads from sensitive paths: `~/.ssh/`, `~/.aws/`, `**/.env*`.
- Deny outbound network commands (`curl`, `wget`, `nc`, `scp`, `ssh`) unless explicitly needed.
- If the workflow only needs to read a repo and run tests, do not let it access your home directory.

---

## Kill Switches

- Heartbeat check: agent checks in every 30 seconds. Kill the process group (not just the parent) if it stalls.
- Log all tool calls and network attempts for post-run audit.
- Disable long-lived memory entirely for high-risk workflows (foreign document processing, email attachment parsing).

---

## Minimum Bar for Unattended Runs

- [ ] Agent identities separate from personal accounts
- [ ] Credentials short-lived and scoped to the task
- [ ] Container or sandbox for untrusted work
- [ ] Outbound network denied by default
- [ ] Reads from secret-bearing paths restricted
- [ ] Attachments and external content sanitised before the agent sees them
- [ ] Shell execution, network egress, and deployment require approval
- [ ] Tool calls, approvals, and network attempts logged
- [ ] Heartbeat monitor + kill switch
- [ ] Memory reset after untrusted work
- [ ] Skills, hooks, MCP configs, and agent definitions scanned like supply chain artifacts
- [ ] Secrets scanned before every commit
