# Agent Audit Report — td-2b04e5

**Date:** 2026-03-01  
**Auditor:** senior-engineer  
**Task:** td-2b04e5 — Audit all agent permission blocks and prose for inconsistencies  
**Scope:** All 6 agent `.md` files in `.opencode/agents/`  
**Method:** Manual read-through + `node .opencode/scripts/audit-agents.mjs --strict --format markdown`

---

## Summary

6 agent files audited. **3 confirmed known issues** and **3 new issues** found.

The automated audit script (`audit-agents.mjs`) passes with 0 findings — this is expected because the script does not check:
- Whether model identifiers resolve to real/loadable models (only validates format)
- Prose documentation table vs YAML permission block consistency
- `bash: false` with non-empty bash permission entries (dead config)

All issues below were found via manual inspection.

---

## Findings Table

| Agent | Issue | Severity | Frontmatter Value | Prose Value | Recommendation |
|-------|-------|----------|-------------------|-------------|----------------|
| `qa-engineer.md` | Model `openai/gpt-5.3-codex` does not exist | P1 | `openai/gpt-5.3-codex` | N/A | Replace with a valid model (e.g. `anthropic/claude-sonnet-4-6`) |
| `senior-engineer.md` | `gh pr create*` is `ask` in permission block but prose says `deny` | P2 | `ask` | `deny (hard block)` | Change permission block to `deny` to match prose intent |
| `senior-engineer.md` | `gh pr merge*` is `ask` in permission block but prose says `deny` | P2 | `ask` | `deny (hard block)` | Change permission block to `deny` to match prose intent |
| `senior-engineer.md` | `gh pr edit*` is `ask` in permission block but prose says `deny` | P2 | `ask` | `deny (hard block)` | Change permission block to `deny` to match prose intent |
| `senior-engineer.md` | `hub pull-request*` is `ask` in permission block but prose says `deny` | P2 | `ask` | `deny (hard block)` | Change permission block to `deny` to match prose intent |
| `senior-engineer.md` | `git push*merge_request*` is `ask` in permission block but prose says `deny` | P2 | `ask` | `deny (hard block)` | Change permission block to `deny` to match prose intent |
| `senior-engineer.md` | `git add`, `git commit`, `git checkout`, `git merge`, `git rebase`, `git push`, `git pull`, `git fetch`, `git worktree`, `git tag` are `allow` in block but prose says `ask` | P2 | `allow` | `ask (confirmation required)` | Align block to `ask` or update prose to reflect `allow` intent |
| `staff-engineer.md` | `bash: false` but bash permission block has 13 entries (dead config) | P3 | `bash: false` + non-empty permission block | N/A | Remove bash permission entries or annotate as forward-compatible placeholder |
| All 6 agents | `external_directory` uses `~` tilde shorthand — tilde expansion support in OpenCode is unverified | P3 | `~/Development/...` | N/A | Verify tilde expansion support; replace with absolute paths if unsupported |
| `audit-agents.mjs` | Script does not detect invalid model identifiers, prose/block mismatches, or dead bash config | P2 (script gap) | N/A | N/A | Enhance script to cover these checks |

---

## Per-Agent Findings

### team-lead.md

- **model:** `anthropic/claude-sonnet-4-6` — **PASS** (valid, real model identifier)
- **Permission consistency:** No prose permission table in agent body. YAML block uses `"*": deny` with specific `allow` overrides for `ls*`, `cat*`, `grep*`. No inconsistency detectable (no prose to compare against).
- **bash: false issue:** N/A — `bash: true` is set; permission block is active.
- **Other issues:**
  - `external_directory` uses `~` shorthand (`~/Development/MoshPitLabs/worktrees/**`). Tilde expansion support in OpenCode is unverified. If not supported, worktree access will silently fail. **Severity: P3** (affects all 6 agents equally).
  - The agent body does not document its own permission table, making it harder to audit. Not a bug, but a documentation gap.
  - `task` permission block allows specific agent names (`product-manager`, `staff-engineer`, etc.) — no prose table to compare against, so no inconsistency found.

---

### senior-engineer.md

- **model:** `anthropic/claude-sonnet-4-6` — **PASS** (valid, real model identifier)
- **Permission consistency:** **FAIL** — Multiple mismatches between YAML permission block and prose documentation table.

  **PR lifecycle commands (YAML lines 43–47 vs prose table line 87):**

  | Command | YAML block | Prose table | Status |
  |---------|-----------|-------------|--------|
  | `gh pr create*` | `ask` | `deny (hard block)` | **MISMATCH** |
  | `gh pr merge*` | `ask` | `deny (hard block)` | **MISMATCH** |
  | `gh pr edit*` | `ask` | `deny (hard block)` | **MISMATCH** |
  | `hub pull-request*` | `ask` | `deny (hard block)` | **MISMATCH** |
  | `git push*merge_request*` | `ask` | `deny (hard block)` | **MISMATCH** |

  **State-changing git operations (YAML lines 49–60 vs prose table line 86):**

  | Command | YAML block | Prose table | Status |
  |---------|-----------|-------------|--------|
  | `git add*` | `allow` | `ask` | **MISMATCH** |
  | `git commit*` | `allow` | `ask` | **MISMATCH** |
  | `git checkout*` | `allow` | `ask` | **MISMATCH** |
  | `git switch*` | `ask` | `ask` | PASS |
  | `git merge*` | `allow` | `ask` | **MISMATCH** |
  | `git rebase*` | `allow` | `ask` | **MISMATCH** |
  | `git push*` | `allow` | `ask` | **MISMATCH** |
  | `git pull*` | `allow` | `ask` | **MISMATCH** |
  | `git fetch*` | `allow` | `ask` | **MISMATCH** |
  | `git stash*` | `ask` | `ask` | PASS |
  | `git worktree*` | `allow` | `ask` | **MISMATCH** |
  | `git tag*` | `allow` | `ask` | **MISMATCH** |

  **Note on state-changing git ops:** The prose table says these require `ask` (confirmation), but the YAML block grants `allow` (no prompt). This is a significant security/governance gap — the agent can commit, push, and merge without human confirmation. The prose intent is clearly `ask`; the YAML block was likely set to `allow` for operational convenience but was never reconciled with the prose.

- **bash: false issue:** N/A — `bash: true` is set.
- **Other issues:**
  - `external_directory` uses `~` shorthand (same as all agents, P3).

---

### qa-engineer.md

- **model:** `openai/gpt-5.3-codex` — **FAIL** — This model does not exist. `gpt-5.3-codex` is not a real OpenAI model identifier. The automated audit script passes this because it only validates the `provider/model` format, not whether the model is loadable. This will cause agent load failure at runtime.
  - **Recommended replacement:** `anthropic/claude-sonnet-4-6` (consistent with team-lead and senior-engineer) or `openai/gpt-4o` (if OpenAI is preferred for QA).
- **Permission consistency:** No prose permission table in agent body. YAML block uses `"*": deny` with specific `allow` overrides. No inconsistency detectable.
- **bash: false issue:** N/A — `bash: true` is set.
- **Other issues:**
  - `external_directory` uses `~` shorthand (same as all agents, P3).

---

### staff-engineer.md

- **model:** `anthropic/claude-opus-4-6` — **PASS** (valid, real model identifier)
- **Permission consistency:** No prose permission table in agent body. No inconsistency detectable.
- **bash: false issue:** **FAIL** — `tools.bash: false` is set (line 16), which disables the bash tool entirely. However, the `permission.bash` block (lines 20–34) contains 13 entries:
  ```yaml
  bash:
    "*": deny
    "ls*": allow
    "cat*": allow
    "grep*": allow
    "head*": allow
    "wc*": allow
    "git diff*": allow
    "git log*": allow
    "git show*": allow
    "git status*": allow
    "git rev-parse*": allow
    "git remote*": allow
    "node .opencode/scripts/audit-agents.mjs*": allow
  ```
  These entries are **dead config** — when `bash: false`, the permission block is never evaluated. This creates a false sense of security (readers may believe bash is restricted to read-only ops, when in fact bash is simply disabled). **Severity: P3** — no functional impact, but misleading.
- **Other issues:**
  - `external_directory` uses `~` shorthand (same as all agents, P3).

---

### product-manager.md

- **model:** `anthropic/claude-opus-4-6` — **PASS** (valid, real model identifier)
- **Permission consistency:** No prose permission table in agent body. YAML block uses `"*": deny` with `ls*`, `cat*`, `grep*` allows. No inconsistency detectable.
- **bash: false issue:** N/A — `bash: true` is set.
- **Other issues:**
  - `external_directory` uses `~` shorthand (same as all agents, P3).

---

### ux-designer.md

- **model:** `anthropic/claude-opus-4-6` — **PASS** (valid, real model identifier)
- **Permission consistency:** No prose permission table in agent body. YAML block uses `"*": deny` with `ls*`, `cat*`, `grep*` allows. No inconsistency detectable.
- **bash: false issue:** N/A — `bash: true` is set.
- **Other issues:**
  - `external_directory` uses `~` shorthand (same as all agents, P3).

---

## Automated Audit Script Results

```
# Agent Audit Report

- Agents scanned: 6
- Markdown files checked: 3
- Findings: 0

## Severity Summary

- critical: 0
- high: 0
- medium: 0
- low: 0

No findings. Audit passed.
```

**Script gap analysis:** The automated script passes with 0 findings because it does not check:
1. **Model existence** — only validates `provider/model` format. `openai/gpt-5.3-codex` passes format check but is not a real model.
2. **Prose vs YAML consistency** — no cross-referencing of permission block values against prose documentation tables.
3. **Dead bash config** — no check for `bash: false` with non-empty permission entries.

The script should be enhanced to cover these gaps (tracked separately).

---

## Known Issues Confirmed

| # | Known Issue | Confirmed? | Details |
|---|-------------|------------|---------|
| 1 | `qa-engineer.md`: model `openai/gpt-5.3-codex` — expected FAIL | ✅ **CONFIRMED** | Model does not exist; will fail at runtime |
| 2 | `senior-engineer.md`: `gh pr create*` is `ask` in permission block but prose says `deny` | ✅ **CONFIRMED** | All 5 PR lifecycle commands are `ask` in block vs `deny` in prose |
| 3 | `staff-engineer.md`: `bash: false` but has bash permission entries | ✅ **CONFIRMED** | 13 bash permission entries are dead config |

---

## New Issues Found

| # | Agent | Issue | Severity | Notes |
|---|-------|-------|----------|-------|
| 1 | `senior-engineer.md` | State-changing git ops (`git add`, `git commit`, `git checkout`, `git merge`, `git rebase`, `git push`, `git pull`, `git fetch`, `git worktree`, `git tag`) are `allow` in YAML block but prose says `ask` | P2 | Prose intent is `ask`; YAML grants `allow` (no confirmation). Significant governance gap. |
| 2 | All 6 agents | `external_directory` uses `~` tilde shorthand — tilde expansion support in OpenCode is unverified | P3 | If tilde is not expanded, worktree access will silently fail for all agents |
| 3 | `audit-agents.mjs` | Script does not detect invalid model identifiers, prose/block mismatches, or dead bash config | P2 (script gap) | Script passes with 0 findings despite 3 real issues; needs enhancement |

---

## Recommended Fix Priority

| Priority | Task | Linked TD |
|----------|------|-----------|
| P1 | Fix `qa-engineer.md` model to a valid identifier | td-b50226 |
| P2 | Fix `senior-engineer.md` PR lifecycle permissions from `ask` to `deny` | td-7d8cc4 |
| P2 | Fix `senior-engineer.md` state-changing git ops: reconcile `allow` vs `ask` (new issue) | — |
| P3 | Fix `staff-engineer.md` dead bash config annotation | td-939262 |
| P3 | Verify/fix `external_directory` tilde shorthand across all agents (new issue) | — |
| P3 | Enhance `audit-agents.mjs` to detect model validity, prose/block mismatches, dead config (new issue) | — |
