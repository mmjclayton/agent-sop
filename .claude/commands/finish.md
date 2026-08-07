---
description: End-to-end verify the work, run /simplify, then ship — update Backlog, run /update-sop, open a PR. Three phases, hard-blocking.
sop_version: "2026-07-06"
---

`/finish` is the "I'm done" wrapper. It exists to keep Claude honest: code only ships after Claude has actually exercised it end-to-end (not just compiled it), simplified the diff, and produced a reviewable PR with the SOP trail intact.

Three phases. Each phase is hard-blocking — do not advance with failures.

## Phase 1 — Verify end-to-end

The point: prove the change actually works against the real surface, not just that types/tests pass. Detect the surface, then run the matching verification path.

### 1a. Detect surface

Inspect the diff and the project root. Pick the **first** matching surface from the list below; if more than one matches (e.g. monorepo with backend + frontend changes), run each matching path. Print the detection result before proceeding.

```bash
BASE=$(git merge-base origin/main HEAD 2>/dev/null || git merge-base origin/master HEAD 2>/dev/null || echo HEAD~1)
CHANGED=$(git diff --name-only "$BASE"...HEAD)
echo "$CHANGED"
```

Detection heuristics (apply in order, multiple may match):

| Surface | Signals |
|---------|---------|
| **Backend service** | Diff touches files matching `(server|api|backend|routes?|handlers?|controllers?|functions/)` AND project has a start script (`package.json` `scripts.start` / `scripts.dev`, `Cargo.toml` `[[bin]]`, `main.go`, `manage.py`, `app.py`, `Procfile`, `wrangler.toml`, etc.). |
| **Frontend / web UI** | Diff touches `*.tsx`, `*.jsx`, `*.vue`, `*.svelte`, `*.astro`, `*.html`, or files under `src/components/`, `src/pages/`, `app/`, `pages/`, `public/`. Has a dev script (`vite`, `next dev`, `astro dev`, `npm run dev`). |
| **Desktop / native app** | Diff touches Swift/Kotlin/Electron/Tauri/Flutter source. Has a launchable build artifact. |
| **CLI / library** | No server, no UI. Diff is in a published package surface (`src/`, `lib/`, `cmd/`). |
| **Docs-only** | Every changed file matches `^docs/`, `\.md$`, `^README`, or `\.mdx?$`. |

If detection is ambiguous or nothing matches, **ask the user which surface to verify** before continuing — do not silently fall through.

### 1b. Run the matching path

#### Backend (bash)

1. Identify the start command (read `package.json` / `Cargo.toml` / `Makefile` / `pyproject.toml` / `wrangler.toml`). If unsure, ask.
2. Identify the listening port and at least one entrypoint endpoint touched by the diff. If the diff touches no routed endpoint, pick a known healthcheck (`/health`, `/`, `/api/version`).
3. Boot the service in the background, wait for the port to bind, then exercise it with `curl` (or the project's HTTP client) against the affected endpoint(s). Hit both happy and known-failure paths where the diff mandates them (e.g. auth-required route → both authed and unauthed).
4. Tear the service down before exiting the phase. Capture and surface the relevant log lines.

```bash
# Pattern — adapt to the actual stack
PORT=${PORT:-3000}
npm run dev > "${TMPDIR:-/tmp}/finish-server.log" 2>&1 &
SERVER_PID=$!
trap 'kill $SERVER_PID 2>/dev/null' EXIT
until curl -fsS "http://localhost:${PORT}/" >/dev/null 2>&1; do sleep 0.5; done

# Exercise the diff
curl -fsS "http://localhost:${PORT}/api/<endpoint-from-diff>" | tee "${TMPDIR:-/tmp}/finish-response.json"

kill "$SERVER_PID"
```

If the server fails to boot, the request fails, or the response shape doesn't match the diff's intent, this phase **fails**. Fix and re-run before advancing.

#### Frontend (browser via Claude Chrome extension)

1. Boot the dev server (`npm run dev` / `pnpm dev` / `astro dev` etc.) in the background and confirm it's serving.
2. Use the **Claude Chrome extension** to drive the browser:
   - Navigate to the affected route(s).
   - Walk the user-facing flow the diff changed — click the new button, submit the new form, scroll the new section, toggle the new state.
   - Verify the visible result matches the diff's intent on at least desktop (1440) and mobile (375) breakpoints.
   - Check the browser console for new errors.
3. If the diff touches multiple surfaces (e.g. a marketing page and a dashboard), exercise each.
4. Note: do **not** rely on screenshots from a tool other than the extension — the point is to drive the real browser. If the extension is unavailable, surface that and ask the user whether to fall back to a Playwright run or pause.

#### Desktop / native (computer use)

1. Build and launch the app.
2. Use computer-use tooling to drive the affected screens — click through the flow, confirm visible state changes, check for crashes.
3. If the change affects window chrome / OS integration / accessibility, exercise those explicitly.

#### CLI / library

1. Run the tool / call the public API surface against a real input that exercises the diff.
2. Parse the output and assert it matches the change.

```bash
# Pattern — replace with the real binary / module
node ./bin/cli.js <flag-from-diff> <input>
# or
python -c "from pkg import fn; print(fn(<input>))"
```

#### Docs-only

Skip Phase 1 — there is nothing to exercise. State this explicitly in the Phase 1 summary.

### 1c. Phase 1 output

Before leaving Phase 1, print a one-block summary:

```
Phase 1 — End-to-end verification
  Surface(s):     backend, frontend
  Backend:        PASS — POST /api/foo → 200, body matches schema
  Frontend:       PASS — /pricing flow exercised at 1440 + 375, no console errors
  Notes:          <anything the user should see>
```

**Hard block:** if any matched surface fails, stop. Do not advance to Phase 2.

## Phase 2 — Simplify

Run the `/simplify` skill against the diff.

- Goal: reuse, clarity, dead-code removal, and removal of speculative abstractions introduced during the build.
- Scope: only files in the session diff (`git diff "$BASE"...HEAD --name-only`). Do not let `/simplify` wander into untouched code.
- After applying suggested simplifications, **re-run Phase 1** if any production code changed. Tooling-only or comment-only edits don't require a re-run; behaviour-affecting edits do.

If `/simplify` is unavailable (older harness), substitute: read the diff, look for repeated logic, premature abstractions, dead branches, leftover scaffolding, and unused exports. Apply minimal cleanups.

Version note: `/simplify` was renamed to `/code-review` in Claude Code 2.1.147, then restored in 2.1.152 as an alias that invokes `/code-review --fix`. Behaviour is equivalent for this phase's purpose; the fallback above covers harnesses in the 2.1.147-2.1.151 window.

**Hard block:** Phase 1 must still pass after simplification.

## Phase 3 — Ship

Three sub-steps, in order. Each updates real artifacts; do not skip.

### 3a. Backlog hygiene

Open `Backlog.md`. For every P-number worked on this session:

- Flip status tags in place (`[OPEN]` → `[IN PROGRESS]` → `[SHIPPED - YYYY-MM-DD]`). Never delete.
- Append any new items discovered during the work as `[OPEN]`.
- Confirm tag order: status first, type second.

### 3b. `/update-sop`

Run the full `/update-sop` checklist (`docs/sop/claude-agent-sop.md` Section 12 / `.claude/commands/update-sop.md`). This handles:

- Reviewer turn for over-threshold Features/Refactors (Step 1b).
- Tests pass (Step 2).
- P-number collision check (Step 2a).
- Backlog state-transition validation (Step 3c).
- Drift check (Step 3d).
- `feature-map.md`, `agent-memory.md`, build-plan Batch Log.
- `project_resume_<agent-id>.md` snapshot, written to the path `scripts/resolve-resume-path.sh` returns.
- `docs/recent-work/` session entry + rollup refresh.
- Final commit.

If `/update-sop` hard-blocks (collision, transition violation, drift), resolve the underlying issue and re-run — do not bypass.

### 3c. PR

Push the branch and open a PR via `/prp-pr` (or `gh pr create` directly):

```bash
git push -u origin "$(git branch --show-current)"
gh pr create --title "<type>: <terse summary>" --body "$(cat <<'EOF'
## Summary
- <what shipped>
- <why it shipped>

## Verification
- Phase 1: <surfaces exercised>
- Phase 2: /simplify applied (or no changes)
- Phase 3: /update-sop clean

## Test plan
- [ ] <reviewer step 1>
- [ ] <reviewer step 2>
EOF
)"
```

Title rules: conventional commit prefix, under 70 chars, no marketing copy.

If a PR already exists for this branch, push the new commits and add a PR comment summarising what's new since the last review — do not open a duplicate.

## Output

End the run with a single block:

```
/finish complete
  Phase 1 (verify):  PASS
  Phase 2 (simplify): PASS — N file(s) touched
  Phase 3 (ship):
    Backlog:    P<n> → [SHIPPED - YYYY-MM-DD]
    /update-sop: clean
    PR:         #<num> — <url>
```

If any phase failed and was resolved, note the failure in the summary so the user sees what was caught. If `/finish` was halted before reaching Phase 3, state which phase blocked and what needs human attention.

## When not to use `/finish`

- Mid-task checkpoints — use `/checkpoint` or commit directly.
- Pure exploration / spike branches that aren't shipping.
- Hotfixes where the verification surface is a production system you can't safely exercise locally — escalate to the user instead of inventing a verification path.
