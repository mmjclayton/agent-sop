# Review and continuity hardening

Date: 2026-09-08

## Diff summary

Reviewed `20927997f2428613ef9896d74ef97a67cb5d5030..9e6b192b1c4583d8d9b085af37b9854e3891cf29` on `fix/review-continuity-hardening`. Implements structured review evidence, stable context recovery, local session coordination and observable reviewer execution. Both packages were upgraded together.

Coverage combines complete full-range source analysis from every configured reviewer with a fresh review of the correction diff at the final HEAD. The ranges are contiguous and pinned in `review_chain` for each reviewer. The later review covers the corrections; the earlier review covers the preceding range. Earlier findings were corrected in the new range; both original and correction outputs appear below. Reviewer definitions and policy were unchanged between these two stages.

Severity: NONE

## Findings

No unresolved issues remain after the three configured correction reviews. The parent executed tests. Concrete anchors include `scripts/resolve-resume-path.sh`, the receipt contract and its regression fixtures. Full-range findings and correction output are reproduced below.

Verdict: PASS

## Verification

PASS: all nine docs/benchmark/*-fixtures/run-tests.sh suites; ShellCheck warning level for hooks, resolver, validator and synchroniser; five simultaneous overlapping claim races each yielded one owner; state transitions and Claude/Codex replication checks; pre-change validator accepted the declared transitions.

## Earlier findings and dispositions

| Finding | Disposition |
|---|---|
| Markdown BLOCK stamps, malformed policy and executable instruction changes accepted as coverage | Structured validation and instruction rename regressions added. |
| Claims split by subdirectory, ambiguous paths and unreadable registry records | Common-directory ownership, path validation and explicit errors verified. |
| Target-controlled resolver or handoff symlinks read outside intended boundaries | Trusted installed resolver and symlink rejection verified. |
| Hash failures, conflicting main snapshots, next-close conflicts and external Git directories | Stable identity, explicit reconciliation, archived legacy generations and atomic migration verified. |
| Resolver errors became successful drift skips | Caller now propagates unsafe resolution failures. |
| Expired presence accumulated; identity/schema errors became successful fallbacks | Locked pruning, batch parsing and explicit error handling verified. |
| Multi-document results lost failures; timeout descendants survived; telemetry failures were hidden | Strict single-document input, process-group termination and explicit telemetry status verified. |
| Claude close-out retained obsolete Markdown-only review instructions | Installed close-out routes through the receipt-producing ship workflow. |
| Symlinked legacy directories or invalid enumerated snapshots were skipped; doctor omitted dependencies | Starting-directory symlinks are followed, every enumerated snapshot is validated, and doctor checks all installed runtime dependencies. |

Earlier BLOCK results and model-capacity failures were not counted as passes. Fixes were committed and new independent reviews were run. Raw local execution evidence remains under `.ship/reviews`; historical review replies remain in `/tmp/sop-hardening-reviews`.

## Final reviewer telemetry

| Reviewer | Elapsed seconds | Input tokens | Cached input tokens | Output tokens |
|---|---:|---:|---:|---:|
| code-reviewer | 49 | 177609 | 144896 | 788 |
| security-reviewer | 38 | 122354 | 93440 | 604 |
| silent-failure-hunter | 31 | 120846 | 94592 | 519 |

CLI-reported usage, not billed cost. Cached input is reported separately; do not add it to input totals. Model remains runtime-default-unresolved. This table covers final correction reviews only and excludes full-range and earlier fix/review iterations.

## Limits and remaining decisions

Claims are cooperative and local to linked worktrees. Use one writer per worktree; they do not coordinate separate clones or machines. Installation diagnostics do not prove execution in every fresh runtime session. Local receipts are not an adversarial boundary against their author. No fresh native-model benchmark or total-cost advantage is claimed. Publication and the budgeted comparison pilot remain separate next steps.

## code-reviewer full-range output

Review evidence: /Users/matt_clayton/Projects/agent-sop/.ship/reviews/20260908T074607Z-code-reviewer.23lIeV
## Review Summary

| Severity | Count | Status |
|----------|-------|--------|
| CRITICAL | 0 | pass |
| HIGH | 0 | pass |
| MEDIUM | 0 | pass |
| LOW | 0 | pass |

## Findings

No issues - source analysis of `20927997..a6d947d` found no high-confidence defects. Reviewed `sop_receipt_valid`, instruction coverage invalidation, resume migration, worktree claims and installation integration. Enforcement changes are explicitly declared under P110.

Static ShellCheck passed. Fixture execution remains with the parent. No files or artifacts written.

Verdict: PASS

## code-reviewer correction output

Review evidence: /Users/matt_clayton/Projects/agent-sop/.ship/reviews/20260908T075435Z-code-reviewer.hM9Kej
## Review Summary

| Severity | Count | Status |
|----------|-------|--------|
| CRITICAL | 0 | pass |
| HIGH | 0 | pass |
| MEDIUM | 0 | pass |
| LOW | 0 | pass |

## Findings

No issues found in the requested range.

- `scripts/hooks/sop-doctor.sh:36` checks required installed dependencies and uses the installed resolver.
- `scripts/resolve-resume-path.sh:190` follows symlinked legacy directories and validates enumerated snapshots before copying.
- Regression fixtures cover incomplete installations, symlinked storage and broken snapshots.

Source analysis completed. Bash syntax checks passed for all three changed files. Test execution remains with the parent.

Verdict: PASS

## security-reviewer full-range output

Review evidence: /Users/matt_clayton/Projects/agent-sop/.ship/reviews/20260908T074750Z-security-reviewer.dE9uai
Source analysis completed for `20927997..a6d947d`. No actionable security findings identified.

Reviewed receipt validation, policy enforcement, trusted resolver selection, migration, registry handling, symlink protections, installation changes and CI permissions. Secret scans found only review instructions. No dependency manifests requiring an npm audit were present.

Tests remain with the parent as requested. No files were changed or artifacts written.

Verdict: PASS

## security-reviewer correction output

Review evidence: /Users/matt_clayton/Projects/agent-sop/.ship/reviews/20260908T075524Z-security-reviewer.Em3CqD
Source analysis completed for `a6d947d..9e6b192`.

No security findings identified. Reviewed all three changed files and surrounding resolver, migration and installation logic. No secrets or dependency changes were found; npm audit was not applicable.

Test execution remains with the parent, as requested. No suites were run or artefacts written.

Verdict: PASS

## silent-failure-hunter full-range output

Review evidence: /Users/matt_clayton/Projects/agent-sop/.ship/reviews/20260908T074913Z-silent-failure-hunter.C4MeCY
- **MEDIUM | scripts/resolve-resume-path.sh:208,213**  
  **Issue:** Both migration loops silently skip enumerated entries that fail `-f`, including dangling snapshot symlinks. Migration then prints the destination and exits successfully.  
  **Impact:** An incomplete migration appears successful, leaving continuity records unavailable without a diagnostic.  
  **Fix:** Validate every enumerated snapshot before copying. Report invalid or unreadable entries and exit non-zero.

- **MEDIUM | scripts/hooks/sop-doctor.sh:36,49**  
  **Issue:** `hooks_installed` checks only three files, omitting the Codex adapter, context hook and trusted resolver. Resume diagnostics use the doctor’s source resolver rather than checking the installed dependency.  
  **Impact:** A partial installation can report installed, registered and current even when configured hooks cannot execute.  
  **Fix:** Check all runtime dependencies for readability, report missing files explicitly and distinguish source-resolver diagnostics from installed-resolver health.

Source analysis completed. No suites run or artifacts written.

Verdict: BLOCK

## silent-failure-hunter correction output

Review evidence: /Users/matt_clayton/Projects/agent-sop/.ship/reviews/20260908T075602Z-silent-failure-hunter.xGUS29
No actionable silent-failure findings in the specified diff. Reviewed all three changed files and surrounding error handling. Test execution remains with the parent, as requested.

Verdict: PASS

