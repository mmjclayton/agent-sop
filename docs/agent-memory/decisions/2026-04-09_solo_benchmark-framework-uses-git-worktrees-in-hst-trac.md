# Benchmark framework uses git worktrees in hst-tracker for isolation

**Date:** 2026-04-09
**Agent:** solo

Benchmark framework uses git worktrees in hst-tracker for isolation. Baseline condition strips CLAUDE.md (replaced with 4-line stub), removes docs/sop/, docs/agent-memory.md, .claude/agents/, .claude/commands/, .claude/skills/, brand-voice, style-guides. SOP condition is untouched. Both get identical task prompts. Scoring is blind (reviewer does not know which is which).
