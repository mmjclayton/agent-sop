# Agent Security Guidance

Last updated: 2026-04-08

Security guidance for Claude Code agent sessions. This document covers the threats that are specific to agentic workflows and the practical controls that reduce risk.

---

## Why This Matters

Agents sit in the middle of multiple trusted paths at once. They read files, execute shell commands, call external APIs, and write code. A single malicious input that the model interprets as an instruction can become shell execution, secret exposure, or quiet data exfiltration.

This is not theoretical. In February 2026, Check Point Research published Claude Code disclosures (CVE-2025-59536, CVE-2026-21852) showing that project-contained config could execute before the user accepted the trust dialog, and that API traffic could be redirected through an attacker-controlled endpoint. Snyk's ToxicSkills study scanned 3,984 public skills and found prompt injection in 36% of them.

The attack surface grows with every service the agent connects to. Every MCP server, every external document, every PR review is a potential injection vector.

---

## 1. Prompt Injection Awareness

Everything an LLM reads is executable context. There is no reliable distinction between "data" and "instructions" once text enters the context window.

**High-risk inputs:**
- Pull request bodies, diff comments, issue descriptions, linked docs
- PDF attachments, screenshots, DOCX files, HTML content
- MCP tool responses and tool descriptions
- External web content fetched during a session
- Repository files in cloned or forked repos (especially `.claude/`, hooks, rules)
- Email content processed by connected services

**Practical controls:**
- Treat all external content as untrusted by default
- When processing attachments, extract text only and strip metadata, comments, and hidden elements
- Separate parsing from action: one agent reads the document, another acts on the cleaned summary
- Scan for hidden Unicode characters, zero-width spaces, and bidi overrides in reviewed content
- If linked content can change without your approval, it can become an injection source later

**Detection scans:**

```bash
# Zero-width and bidi control characters
rg -nP '[\x{200B}\x{200C}\x{200D}\x{2060}\x{FEFF}\x{202A}-\x{202E}]'

# Hidden HTML or suspicious embedded content
rg -n '<!--|<script|data:text/html|base64,'

# Outbound commands and permission overrides
rg -n 'curl|wget|nc|scp|ssh|ANTHROPIC_BASE_URL'
```

---

## 2. Secret Scanning

Secrets in committed code are the most common high-severity mistake in agent workflows. Agents generate and edit code quickly. Without a gate, API keys, connection strings, and tokens end up in git history.

**Rule: scan for secrets before every commit. Never commit files containing secrets. Warn the user if asked to.**

**What to scan for:**
- `.env` files, `credentials.json`, `serviceAccountKey.json`
- Hardcoded API keys, tokens, passwords, connection strings in source
- Private keys (`-----BEGIN RSA PRIVATE KEY-----`)
- Files matching `*secret*`, `*credential*`, `*token*` patterns

**Pre-commit check pattern:**

```bash
# Scan staged files for common secret patterns
git diff --cached --name-only | xargs grep -lE \
  '(PRIVATE KEY|sk-[a-zA-Z0-9]{20,}|password\s*=\s*["\x27][^"\x27]+|API_KEY\s*=\s*["\x27][^"\x27]+)' \
  2>/dev/null
```

**Controls:**
- Add `.env`, `*.pem`, `credentials.json` to `.gitignore` at project setup
- Use environment variables for all secrets, never inline values
- If a secret is accidentally committed, rotate it immediately (git history preserves the exposure even after removal)
- Use `.env.example` with placeholder values for documentation

---

## 3. MCP Trust Boundaries

MCP servers extend the agent's capabilities but also extend the attack surface. A tool can exfiltrate data while appearing to provide context. OWASP now has an MCP Top 10 covering tool poisoning, prompt injection via tool responses, command injection, and secret exposure.

**Rules:**
- Document all active MCP servers in the project's CLAUDE.md or `.mcp.json`
- Keep the number of active MCP servers under 10 per project
- Assess each MCP server's trust level before enabling it
- Treat MCP tool descriptions and responses as untrusted content
- Review MCP server source code or documentation before granting broad permissions

**Trust assessment:**

| Trust level | Criteria | Example |
|-------------|----------|---------|
| High | First-party, open source, audited | Official GitHub MCP |
| Medium | Known vendor, closed source | Third-party SaaS integration |
| Low | Community-contributed, unaudited | Random npm MCP package |
| Untrusted | Unknown provenance | Anything recommended in a Discord without verification |

**Controls:**
- Disable MCP servers you are not actively using
- Restrict MCP server permissions to the minimum required scope
- Monitor MCP tool calls in session logs for unexpected behaviour
- Never auto-approve project-scoped MCP servers from cloned repos without review

---

## 4. Sandbox Guidance

For autonomous or overnight agent runs, isolation is the primary defence. If the agent is compromised, the blast radius must be small.

**Identity separation:**
- Do not give the agent your personal accounts (email, Slack, GitHub)
- Use dedicated bot accounts or short-lived scoped tokens
- If the agent has the same credentials you do, a compromised agent is you

**Runtime isolation:**
- Run untrusted repos in containers, devcontainers, or VMs
- Use `--network=none` for tasks that do not need internet access
- Restrict filesystem access to the workspace directory only
- Drop all capabilities and disable privilege escalation

```yaml
# Docker Compose example for isolated agent work
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

**Tool permissions:**
- Deny reads from sensitive paths (`~/.ssh/`, `~/.aws/`, `**/.env*`)
- Deny outbound network commands (`curl`, `wget`, `nc`, `scp`, `ssh`) unless explicitly needed
- If a workflow only needs to read a repo and run tests, do not let it access your home directory

**Kill switches:**
- For unattended runs, implement a heartbeat check (agent checks in every 30 seconds)
- Kill the process group, not just the parent process, if the heartbeat stalls
- Log all tool calls and network attempts for post-run audit

---

## 5. Memory Hygiene for Untrusted Work

Persistent memory is useful but also a persistence mechanism for attackers. A malicious payload does not have to succeed in one shot. It can plant fragments in memory that activate in a later session.

**Rules:**
- Reset auto-memory after running agents on untrusted repos
- Do not store secrets in any memory file (auto-memory or `docs/agent-memory.md`)
- Separate project memory from user-global memory
- Disable long-lived memory entirely for high-risk workflows (foreign document processing, email attachment parsing)

**After untrusted work:**

```bash
# Review what was stored
ls ~/.claude/projects/*/memory/

# Remove memory files from the untrusted project
rm ~/.claude/projects/[untrusted-project-hash]/memory/*.md
```

---

## 6. Minimum Bar Checklist

If you are running agents autonomously, these controls are the minimum:

- [ ] Agent identities are separate from personal accounts
- [ ] Credentials are short-lived and scoped to the task
- [ ] Untrusted work runs in containers or sandboxes
- [ ] Outbound network is denied by default
- [ ] Reads from secret-bearing paths are restricted
- [ ] Attachments and external content are sanitised before the agent sees them
- [ ] Shell execution, network egress, and deployment require approval
- [ ] Tool calls, approvals, and network attempts are logged
- [ ] Kill switches and heartbeat monitors are in place for unattended runs
- [ ] Memory is reset after untrusted work
- [ ] Skills, hooks, MCP configs, and agent definitions are scanned like supply chain artifacts
- [ ] Secrets are scanned before every commit

---

## Integration with the SOP

- Reference this document from `CLAUDE.md` under a Security section or in the Key Documents table
- Add secret scanning to pre-commit hooks (see `docs/sop/hooks.md`)
- Include security reviewer agent in `.claude/agents/` for code projects (see `.claude/agents/security-reviewer.md`)
- The compliance checklist includes checks for security document presence and secret-free commits
