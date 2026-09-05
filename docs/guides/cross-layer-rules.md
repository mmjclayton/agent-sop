<!-- SOP-Version: 2026-05-28 -->
# Cross-Layer Rules — unify-first, parity-fixture as fallback

> Project-agnostic pattern for logic that lives in more than one runtime, layer, or side (e.g. client + server, mobile + web, foreground + background worker). The pattern exists to prevent the bug class where two implementations of the same rule drift silently.

This pattern emerged from three bug classes that recurred in the same shape in a single project across May 2026:
- A week-type rule duplicated on client + server diverged after one side was fixed (chip-suppression bug shipped).
- A `normalizeName` function on both sides diverged on `/` handling, causing copy-from to break identity matching.
- A composer's display-name builder on both sides diverged on a grip-width edge case, almost shipping until a code review caught it.

All three are the same shape: duplicate implementations of one logical rule diverging silently. Local tests on each side pass independently; production hits the diverged path; behaviour breaks.

The pattern below addresses it structurally, in the order you should apply it.

---

## Tier 0 — grep before you change either side

**Always the first step.** Before editing any rule that *might* exist in more than one place, run a sibling search:

- Grep for the function name and any obvious synonyms.
- Grep for modules imported in three or more places.
- Grep for the CSS class, React component, or symbol you're about to change.

The grep itself takes 30 seconds. Each of the three May 2026 incidents would have been prevented by it. The Tier A / Tier B distinction below only matters *after* you've discovered the duplication.

If the grep finds a sibling and the rule is not already on the Duplicated-Logic Inventory (§ Inventory below), **stop and add it** before editing. You've discovered an unsafe row.

---

## The Duplicated-Logic Inventory — the load-bearing artifact

Maintain a markdown table in `docs/process-improvements.md` (or any equivalent living document) listing every rule that has, has had, or might have, more than one implementation across runtimes/layers. The inventory is the single artifact that makes the at-risk surface area visible.

Copy-paste-ready template:

```markdown
## Duplicated-Logic Inventory

Status snapshot. Update when adding or removing implementations.

| Logic | Status | Site A | Site B | Notes |
|-------|--------|--------|--------|-------|
| <rule name> | ✓ unified | <shared module path> | <shared module path> | One source; both sides import. |
| <rule name> | ✗ parity-tested | <impl path A> | <impl path B> | Fixture: `<path>`. Reason unification is infeasible: <one line>. |
| <rule name> | ⚠ unsafe | <impl path A> | <impl path B> | Backlog item to migrate to ✓ or ✗: <link>. |
```

Status values define the tier transitions:
- **✓ unified** — Tier A. One module, both sides import. Divergence structurally impossible.
- **✗ parity-tested** — Tier B. Two implementations, pinned to a shared JSON fixture both sides test against. Divergence fails both tests simultaneously.
- **⚠ unsafe** — discovered duplication that has neither unification nor a parity fixture yet. Every `⚠` row is a future bug; file a Backlog task to move it to ✓ or ✗.

Anything missing from the inventory is also a future bug; the inventory's value is *making visible what's at risk*. New projects should add the table on day 1, even when empty.

---

## Tier A (preferred) — unify

**When the rule is a pure function over inputs and both runtimes can import the same module, unify.**

Put the rule in a shared directory both runtimes can resolve (e.g. `shared/rules/<rule>.<ext>`). Both sides import via a path alias or equivalent module-resolution config; the project's existing build system decides the mechanism (Vite alias, Jest moduleNameMapper, Go workspaces, Rust workspace crate, Java multi-module, etc.).

What "pure function over inputs" means here:
- No platform-only dependencies (no React, no fetch, no Node `fs`, no browser DOM).
- No DB access, no network calls, no clock reads, no random.
- Outputs determined solely by inputs.

Authoring rules for unified modules:
1. **One file per rule family.** Don't dump unrelated rules into one file.
2. **Every rule has a fixture.** Both sides run the same fixture against the shared module. Same fixture file, two test entry points (`<runtime-a>/__tests__/<rule>.test.*` and `<runtime-b>/__tests__/<rule>.test.*`).
3. **Mirror, don't duplicate.** When extracting an existing rule from one runtime, make the original file re-export from the shared module rather than leaving two source-of-truth copies. Inventory status updates from ⚠ to ✓ only after the re-export is in place.
4. **Coverage threshold.** Shared rules deserve a tighter threshold than UI code — projects typically gate at 90-95% line / 85-90% branch.

Tier A is strictly stronger than Tier B because the implementations literally cannot diverge. Prefer it whenever the purity constraint can be met.

---

## Tier B (fallback) — parity fixture

**When unification adds more friction than it solves, keep two implementations and pin their equivalence with a shared JSON fixture.**

When is unification infeasible? Real cases:
- The runtimes use mutually-incompatible toolchains for the module in question (e.g. a parser that has a browser-side build and a Node-side build via different package entry points).
- Per-runtime ergonomic adaptations would require unsafe wrappers (e.g. a function that's idiomatic Promise-returning on one side and idiomatic synchronous on the other; forcing one shape on both adds bugs).
- The shared module would require lifting a heavy dependency into a layer that doesn't otherwise need it.

These are the only valid reasons. "Two slightly different shapes for ergonomics" is not infeasibility; that's a refactor.

The pattern:
1. **One JSON fixture per rule** at `docs/fixtures/<rule>-parity.json` (or any single shared location both sides can read).
2. **Each fixture entry has `input` and `expected`** at minimum. Add a `notes` field for non-obvious cases.
3. **Both sides consume the same fixture.** Server test at `<runtime-a>/__tests__/<rule>Parity.test.*`, client test at `<runtime-b>/__tests__/<rule>Parity.test.*`. Different test files, same fixture data.
4. **Both tests must pass.** Divergence fails both tests simultaneously — the JSON fixture is the spec; the two implementations are the test subjects.
5. **One source of truth for cases.** When the rule gains a new edge case, add it to the JSON first; then both implementations follow.

When a `✗ parity-tested` row later becomes unifiable (toolchains converge, dependency lands in a shared layer, ergonomic constraint disappears), migrate the fixture cases to the shared rule's fixture and remove the parity file. Migration only ever goes ✗ → ✓, never the other way.

---

## Worked example — parity fixture

A `normalizeName` function exists on both sides. Server uses one parser; client uses a different one (browser-incompatible vs Node-incompatible build entry points). Both must agree byte-for-byte on every input.

Fixture at `docs/fixtures/normalize-parity.json`:

```json
[
  {
    "input": "Foo / Bar",
    "expected": "foo-bar",
    "notes": "slash-with-spaces becomes single hyphen"
  },
  {
    "input": "  TRIM  ",
    "expected": "trim",
    "notes": "whitespace collapsed, lowercased"
  },
  {
    "input": "Edge—Case",
    "expected": "edge-case",
    "notes": "em-dash treated as hyphen (regression: 2026-04-22)"
  }
]
```

Server test stub (`<runtime-a>/__tests__/normalizeParity.test.*`):
```pseudocode
load fixture from docs/fixtures/normalize-parity.json
for each entry:
  assert normalizeName(entry.input) === entry.expected
```

Client test stub (`<runtime-b>/__tests__/normalizeParity.test.*`):
```pseudocode
load fixture from docs/fixtures/normalize-parity.json (same file)
for each entry:
  assert normalizeName(entry.input) === entry.expected
```

When a new edge case is discovered (e.g. the em-dash regression on 2026-04-22), the order is: add the fixture row first, watch both tests fail, fix both implementations, re-run, both pass. The order matters — if you fix the code before adding the fixture row, you've prevented the next regression but documented nothing.

---

## Anti-patterns

- **Skipping the inventory.** "I know about both sites" is not an inventory. Future maintainers (and future-you in three months) need the table.
- **Per-side fixtures.** Two JSON files for the same rule defeats the pattern. One file, two consumers.
- **Random / time / DB / network input in fixtures.** Fixtures are pure-function checks. If your rule depends on a clock or a DB row, the fixture pins the wrong thing.
- **"Just add a TODO" instead of an inventory row.** TODOs rot; inventory rows are load-bearing. Use the inventory.
- **Adding a parity fixture before deciding whether to unify instead.** Re-read § Tier A. The shared-rules pattern is structurally stronger; reach for parity only when unification's friction is real and documented in the Notes column.
- **Letting `⚠ unsafe` rows linger.** Every `⚠` is a known future bug. File a Backlog task with the row.

---

## When to update this guide

When a project encounters a cross-layer divergence bug that this guide didn't anticipate, file a Backlog item to add a new anti-pattern or worked example. The guide should grow with the bug classes it catches.

---

## See also

- `docs/sop/claude-agent-sop.md` § 3 step 2 — the reviewer-turn gate that often catches cross-layer divergence at PR time (one of the May 2026 incidents was caught here).
- `docs/guides/sop-common-mistakes.md` — the "Editing one site of a multi-site rule" mistake links here.
