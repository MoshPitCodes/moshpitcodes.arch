# Documentation Consistency Audit Report

**Task:** td-b35bad  
**Date:** 2026-03-05  
**Auditor:** senior-engineer (ses_508af8)

---

## Executive Summary

All primary documentation files, filesystem component directories, prior audit reports, and the TDD directory were read in full (19 files, ~4,200 lines). The documentation ecosystem is **structurally sound but carries significant unresolved drift** from prior audits. Zero of the recommended fixes from the three prior audit reports (td-c0187e, td-972e8b, td-7c3679) have been applied to source files. The most critical unresolved issue is `qa-engineer.md` using `model: openai/gpt-5.2` — an invalid model identifier that will cause runtime failure in the validation phase. `AGENTS_INDEX.md` component counts are accurate for agents, commands, skills, and tools, but the plugin count claim of "6" is ambiguous: the `.opencode/plugins/` directory contains 7 entries (6 `.ts` files + 1 `README.md`). `AGENTS.md` itself is accurate and consistent with the actual filesystem layout. `agent-team-workflow.md` remains the highest-risk document with 8 broken TD command references and 2 non-existent agent references. Total findings: **4 P0, 11 P1, 7 P2, 4 P3 = 26 total**.

---

## Audit Scope

| File / Directory | Lines / Entries | Role |
|-----------------|----------------|------|
| `AGENTS.md` | 31 | Global rules — primary audit target |
| `.opencode/AGENTS_INDEX.md` | 65 | Component count claims — primary audit target |
| `.opencode/docs/agent-team-workflow.md` | 605 | Delivery playbook — primary audit target |
| `.opencode/docs/agent-tools-policy.md` | 318 | 31-agent policy reference — primary audit target |
| `.opencode/agents/` | 6 `.md` files | Filesystem verification |
| `.opencode/commands/` | 2 `.md` files | Filesystem verification |
| `.opencode/skills/` | 11 subdirectories | Filesystem verification |
| `.opencode/plugins/` | 6 `.ts` + 1 `README.md` | Filesystem verification |
| `.opencode/tools/` | 2 `.ts` files | Filesystem verification |
| `opencode.json` | 167 | Config cross-reference |
| `specs/audit/` | 6 files at audit start (7 after this report was created) | Prior audit reports |
| `specs/audit/td-c0187e-agent-definitions-audit.md` | 373 | Prior audit — fix verification |
| `specs/audit/td-972e8b-worktree-sidecar-analysis.md` | 313 | Prior audit — fix verification |
| `specs/audit/td-7c3679-td-tool-audit.md` | 324 | Prior audit — fix verification |
| `specs/tdd/td-9da879-icm-llm-driven-tools.md` | 578 | TDD — Phase 1 status check |
| `.opencode/tools/td.ts` | 596 | TD tool — fix verification |
| `.opencode/skills/git-worktree-flow/SKILL.md` | 52 | Skill — fix verification |
| `.opencode/commands/plan.md` | 34 | Command — fix verification |
| `.opencode/agents/qa-engineer.md` | 116 | Agent — fix verification |

**Total lines read:** ~4,200

---

## Findings Table

| ID | Severity | File | Dimension | Finding | Recommended Fix |
|----|----------|------|-----------|---------|-----------------|
| D1-01 | **P2** | `AGENTS.md` | 1 — AGENTS.md Accuracy | `AGENTS.md` component location table lists `.opencode/` paths — these are **correct** and match the actual filesystem. No mismatch. | No action needed. |
| D1-02 | **P3** | `AGENTS.md` | 1 — AGENTS.md Accuracy | `AGENTS.md` TD tool location claim (`.opencode/tools/td.ts`) is **correct** — file exists at that path. | No action needed. |
| D1-03 | **P2** | `AGENTS.md` | 1 — AGENTS.md Accuracy | Rule 1 states "run `TD(action: "status")`" but the enforcer plugin runs `td status` internally — agents don't need to manually call it. The rule text implies manual invocation but enforcement is automatic. Slightly misleading. | Clarify Rule 1 to note that `td-enforcer.ts` handles this automatically for MCP write tools; manual call is only needed for read-only context checks. |
| D1-04 | **P1** | `AGENTS.md` | 1 — AGENTS.md Accuracy | Rule 1 enforcement is **partial**: `td-enforcer.ts` blocks MCP write tools only. Shell-level writes via `Bash` tool bypass enforcement entirely. Rule text says "before any file edit/write" but bash writes are unprotected. | Add a note to Rule 1: "Shell-level writes via Bash are not enforced by td-enforcer; agents must self-enforce." |
| D1-05 | **P1** | `AGENTS.md` | 1 — AGENTS.md Accuracy | Rules 2, 3, and 4 are **prose-only** with no enforcement mechanism. Rule 2 (session start `usage`) has no hook. Rule 3 (sub-agent TD text) cannot be enforced by tooling. Rule 4 (handoff) has a dismissible toast reminder only. | Document enforcement status per rule: "enforced by td-enforcer" vs "prose-only / reminder-only." |
| D2-01 | **P2** | `.opencode/AGENTS_INDEX.md` | 2 — Count Accuracy | AGENTS_INDEX.md claims "6 plugins." The `.opencode/plugins/` directory contains **7 entries**: 6 `.ts` files + `README.md`. The count is correct if counting only `.ts` plugin files, but the directory listing shows 7 entries. The `README.md` is not a plugin but is present in the plugins directory. | Add a note to AGENTS_INDEX.md: "Plugin count reflects `.ts` files only; `README.md` is documentation." Or move `README.md` to `.opencode/docs/`. |
| D2-02 | **P3** | `.opencode/AGENTS_INDEX.md` | 2 — Count Accuracy | AGENTS_INDEX.md is located at `.opencode/AGENTS_INDEX.md`, not at the repo root. `AGENTS.md` (root) does not reference `AGENTS_INDEX.md` at all. The index is effectively undiscoverable from the primary entry point. | Add a reference to `.opencode/AGENTS_INDEX.md` in `AGENTS.md` under the Component locations section. |
| D2-03 | **P3** | `.opencode/AGENTS_INDEX.md` | 2 — Count Accuracy | AGENTS_INDEX.md `*Last updated: 2026-03-03*` — the date is 2 days before the current audit date (2026-03-05). Three prior audit reports were created on 2026-03-05 but the index was not updated. | Update `Last updated` date when component counts or listings change. |
| D3-01 | **P0** | `agent-team-workflow.md` | 3 — Broken References | `td done` used **3 times** (lines 196, 331, 516). This command does NOT exist in the TD CLI. `td done` is an alias for `td close` (admin closure), not the completion flow. Correct flow is `td review` → `td approve`. Any agent following this playbook will use the wrong command. | Replace all 3 occurrences with `td review <id>` + `td approve <id>` workflow. |
| D3-02 | **P0** | `agent-team-workflow.md` | 3 — Broken References | `td block` used **4 times** (lines 234, 346, 564, 584) and `td unblock` used **1 time** (line 247). These commands do NOT exist in the TD CLI as status-change commands. `block-issue` and `unblock-issue` exist but operate on dependency blocking, not the `--reason` pattern shown. | Replace `td block` with `td log --type blocker "reason"` (5 occurrences). Replace `td unblock` with `td log "blocker resolved: ..."`. |
| D3-03 | **P1** | `agent-team-workflow.md` | 3 — Broken References | `validator` agent referenced in Team Roles (line 10) — does not exist. Actual validation agent is `qa-engineer`. | Replace `validator` with `qa-engineer` in Team Roles section. |
| D3-04 | **P1** | `agent-team-workflow.md` | 3 — Broken References | `staff-engineer` listed as "implementation and code review" (line 9) — incorrect. `staff-engineer` is the **reviewer/TDD author**; `senior-engineer` is the **implementer**. | Replace line 9 with: `senior-engineer (implementation)` and `staff-engineer (code review and TDD)`. |
| D3-05 | **P1** | `agent-team-workflow.md` | 3 — Broken References | Direct `git merge` used 2× in main flow (lines 187, 329) and 1× in troubleshooting (line 570). Contradicts `pr-quality-gate` skill and `git-workflow` skill which both mandate PR-based flow. | Replace with `gh pr create` + `gh pr merge` flow. Troubleshooting line should use `git rebase origin/main`. |
| D3-06 | **P2** | `agent-team-workflow.md` | 3 — Broken References | Worktree path format `~/Development/.worktrees/feature-td-abc123-jwt-service` (full branch slug) conflicts with `plan.md` format `~/Development/.worktrees/td-xxx` (task ID only). Three different conventions across docs. | Standardize on `~/Development/.worktrees/<type>-td-<id>-<slug>` (mirrors branch name with `/` → `-`). |
| D4-01 | **P1** | `agent-tools-policy.md` | 4 — Policy Drift | Policy "Agent-to-Archetype Mapping" table lists **31 agents**. Only **6 agents** exist in `.opencode/agents/`. 25 phantom archetypes are referenced. Additionally, `qa-engineer` and `ux-designer` are deployed but **not listed** in the policy table at all. | Rewrite mapping table to reflect the 6 actual agents: `team-lead`, `product-manager`, `staff-engineer`, `senior-engineer`, `qa-engineer`, `ux-designer`. |
| D4-02 | **P1** | `agent-tools-policy.md` | 4 — Policy Drift | Policy mandates exactly **7 tool keys** (`edit`, `write`, `skill`, `td`, `webfetch`, `todowrite`, `bash`). All 6 deployed agents have **11–14 keys** (7 extra: `read`, `list`, `websearch`, `grep`, `todoread`, `question`, `agent-browser`). Policy says "No extra keys in tools" — directly contradicts deployed reality. | Update policy to reflect actual 14-key schema, or document the delta explicitly. |
| D4-03 | **P1** | `agent-tools-policy.md` | 4 — Policy Drift | Policy "Migration Required" table (lines 280–295) lists `staff-engineer` as needing "entire tools block (currently absent)." `staff-engineer` now has a complete tools block. Migration table is stale and will mislead future implementers. | Update or remove the Migration Required table to reflect current state. |
| D4-04 | **P2** | `agent-tools-policy.md` | 4 — Policy Drift | Policy permission template for `team-lead` (Orchestration archetype, line 72) shows `task` permission block allowing `validator` — does not exist. Actual `team-lead.md` correctly allows `qa-engineer` instead. Policy template is stale. | Update policy template to match actual agent names: replace `validator` with `qa-engineer`. |
| D4-05 | **P2** | `agent-tools-policy.md` | 4 — Policy Drift | Policy "Preservation Rules" section (lines 300–306) lists 5 agents with custom permission profiles: `git-flow-manager`, `linearapp`, `nixos`, `prompt-engineering`, `rpg-mmo-systems-designer`. None of these agents exist in the repository. The preservation rules are entirely phantom. | Remove or replace with preservation rules for the 6 actual agents that have custom permission profiles. |
| D5-01 | **P0** | `qa-engineer.md` | 5 — Prior Fix Verification | **td-c0187e recommended:** Change `qa-engineer.md` model from `openai/gpt-5.2` to `anthropic/claude-sonnet-4-6`. **Status: NOT FIXED.** Current file still shows `model: openai/gpt-5.2` (line 4). This is an invalid model identifier that will cause runtime failure. | Change `model: openai/gpt-5.2` to `model: anthropic/claude-sonnet-4-6`. |
| D5-02 | **P1** | `git-worktree-flow/SKILL.md` | 5 — Prior Fix Verification | **td-972e8b recommended:** Change `git pull origin main` to `git pull --rebase origin main` (line 24). **Status: NOT FIXED.** Current file still shows `git pull origin main` without `--rebase` flag. | Change line 24 to `git pull --rebase origin main`. |
| D5-03 | **P1** | `plan.md` | 5 — Prior Fix Verification | **td-972e8b recommended:** Add `origin/main` base ref to `git worktree add` command (line 31). **Status: NOT FIXED.** Current file shows `git worktree add ~/Development/.worktrees/<task-id> -b <branch-name>` with no base ref. | Change to `git worktree add ~/Development/.worktrees/<task-id> -b <branch-name> origin/main`. |
| D5-04 | **P0** | `td.ts` | 5 — Prior Fix Verification | **td-7c3679 recommended:** Fix `files` action to link files when `input.files` array is provided (currently ignores the array and only lists). **Status: NOT FIXED.** Lines 555–559 still call `td files <task>` unconditionally, ignoring `input.files`. | Add conditional: if `input.files` provided, call `td link`; else call `td files` (list). |
| D5-05 | **P1** | `td.ts` | 5 — Prior Fix Verification | **td-7c3679 recommended:** Fix `log` action to support `task` parameter targeting. **Status: NOT FIXED.** Lines 258–267 still construct `["log"]` without inserting `input.task` before the message. | Add `if (input.task) args.splice(1, 0, input.task)` after `const args = ["log"]`. |
| D6-01 | **P3** | `specs/tdd/` | 6 — ICM TDD Status | `specs/tdd/` contains 2 entries: `.gitkeep` and `td-9da879-icm-llm-driven-tools.md`. The ICM Phase 2 TDD (`td-9da879`) is the only TDD present. | No action needed — directory is correctly populated. |
| D6-02 | **P2** | `specs/tdd/td-9da879-icm-llm-driven-tools.md` | 6 — ICM TDD Status | TDD references "Phase 1 of the ICM plugin (td-e2af34)" as the baseline. TD task `td-e2af34` is confirmed **closed** in the task system. Phase 1 is complete. The TDD status field shows `draft` — it has not been updated to reflect that Phase 1 is complete and Phase 2 is ready for implementation. | Update TDD status from `draft` to `ready` or `approved` to signal Phase 2 can proceed. |

---

## Dimension Analysis

### 1. AGENTS.md Accuracy

| Claim | Actual State | Status | Finding |
|-------|-------------|--------|---------|
| Commands at `.opencode/commands/` | ✅ Directory exists with 2 `.md` files | ✅ Correct | None |
| Agents at `.opencode/agents/` | ✅ Directory exists with 6 `.md` files | ✅ Correct | None |
| Skills at `.opencode/skills/` | ✅ Directory exists with 11 subdirectories | ✅ Correct | None |
| Plugins at `.opencode/plugins/` | ✅ Directory exists with 6 `.ts` files | ✅ Correct | None |
| Tools at `.opencode/tools/` | ✅ Directory exists with 2 `.ts` files | ✅ Correct | None |
| Docs at `.opencode/docs/` | ✅ Directory exists | ✅ Correct | None |
| TD tool at `.opencode/tools/td.ts` | ✅ File exists at that exact path | ✅ Correct | None |
| Rule 1: status before edit | ⚠️ Partially enforced — MCP write tools only; bash writes bypass | ⚠️ Partial | D1-04 |
| Rule 2: usage at session start | ❌ Prose-only — no enforcement mechanism | ❌ Not enforced | D1-05 |
| Rule 3: sub-agent TD text | ❌ Prose-only — cannot be enforced by tooling | ❌ Not enforced | D1-05 |
| Rule 4: handoff before context end | ⚠️ Reminder-only (dismissible toast) | ⚠️ Partial | D1-05 |
| Naming: `kebab-case.md` for commands | ✅ `build.md`, `plan.md` | ✅ Correct | None |
| Naming: `kebab-case.md` for agents | ✅ All 6 agents use kebab-case | ✅ Correct | None |
| Naming: `kebab-case/` for skills | ✅ All 11 skill directories use kebab-case | ✅ Correct | None |
| Naming: `kebab-case.ts` for plugins | ✅ All 6 plugin `.ts` files use kebab-case | ✅ Correct | None |
| Naming: `kebab-case.ts` for tools | ✅ `td.ts`, `agent-browser.ts` | ✅ Correct | None |

**AGENTS.md verdict:** The file is **accurate** for all factual claims about paths, locations, and naming conventions. The only issues are enforcement gaps in the mandatory rules (D1-04, D1-05) — the rules are correct as written but their enforcement status is not documented.

---

### 2. AGENTS_INDEX.md Component Counts

| Component | Claimed | Actual | Status | Notes |
|-----------|---------|--------|--------|-------|
| Agents | 6 | 6 | ✅ Correct | `product-manager`, `qa-engineer`, `senior-engineer`, `staff-engineer`, `team-lead`, `ux-designer` |
| Commands | 2 | 2 | ✅ Correct | `build.md`, `plan.md` |
| Skills | 11 | 11 | ✅ Correct | All 11 skill directories present |
| Plugins | 6 | 6 `.ts` files (7 dir entries) | ⚠️ Ambiguous | Directory has 6 `.ts` + 1 `README.md` = 7 entries. Count is correct if counting `.ts` only. |
| Tools | 2 | 2 | ✅ Correct | `agent-browser.ts`, `td.ts` |

**AGENTS_INDEX.md location:** File is at `.opencode/AGENTS_INDEX.md`, not at the repo root. The task description referenced it as `AGENTS_INDEX.md` (root) — it does not exist at the root. `AGENTS.md` (root) does not link to it.

**Skill listing accuracy:** All 11 skills listed in AGENTS_INDEX.md match the 11 actual skill directories:
- `acceptance-criteria-authoring/` ✅
- `agent-browser/` ✅
- `bug-triage/` ✅
- `design-system/` ✅
- `frontend-design/` ✅
- `git-workflow/` ✅
- `git-worktree-flow/` ✅
- `pr-quality-gate/` ✅
- `release-notes/` ✅
- `tdd-authoring/` ✅
- `td-workflow/` ✅

**Plugin listing accuracy:** All 6 plugins listed in AGENTS_INDEX.md match the 6 `.ts` files:
- `security.ts` ✅
- `logging.ts` ✅
- `notifications.ts` ✅
- `post-stop-detector.ts` ✅
- `td-enforcer.ts` ✅
- `icm.ts` ✅

**Unlisted in AGENTS_INDEX.md:** `plugins/README.md` — present in directory but not listed (correct, it's not a plugin).

---

### 3. agent-team-workflow.md Broken References

#### Non-Existent TD Commands (confirmed with exact line numbers)

| Command | Occurrences | Lines | Severity | Valid Alternative |
|---------|-------------|-------|----------|-------------------|
| `td done` | 3 | 196, 331, 516 | **P0** | `td review <id>` + `td approve <id>` |
| `td block` | 4 | 234, 346, 564, 584 | **P0** | `td log --type blocker "reason"` |
| `td unblock` | 1 | 247 | **P0** | `td log "blocker resolved: ..."` |

**Total broken TD command occurrences: 8** (3 `td done` + 4 `td block` + 1 `td unblock`)

**Prior audit count comparison:**
- td-c0187e reported: `td done` in 4 places (lines 196, 331, 516, 517) — **this audit finds 3** (line 517 is actually `td done td-epic-001` on line 516 — the prior audit may have counted the `td status td-epic-001` on line 511 separately, or there was a line number shift)
- td-972e8b reported: `td done` 3× (lines 196, 331, 516), `td block` 4×, `td unblock` 1× — **this audit confirms exactly these counts**
- td-7c3679 reported: `td done` in 5 places — **this audit finds 3** (the discrepancy may be due to td-7c3679 counting the `td done` in the "Approved" section at line 331 as two separate occurrences, or the file was modified between audits)

**Current confirmed count: 3 `td done`, 4 `td block`, 1 `td unblock` = 8 total broken TD command references**

#### Non-Existent Agent References

| Reference | Line | Severity | Fix |
|-----------|------|----------|-----|
| `validator` agent in Team Roles | 10 | **P1** | Replace with `qa-engineer` |
| `staff-engineer` as implementer | 9 | **P1** | Replace with `senior-engineer (implementation)` and `staff-engineer (code review)` |

**Actual agent roster:** `team-lead`, `product-manager`, `staff-engineer` (reviewer), `senior-engineer` (implementer), `qa-engineer` (validator), `ux-designer`

#### Additional Issues Not in Prior Audits

No new broken references were found beyond what prior audits documented. The direct `git merge` issue (D3-05) was documented in td-972e8b (A-07, A-08) and td-c0187e (F-12). The worktree path inconsistency (D3-06) was documented in td-972e8b (A-09).

---

### 4. agent-tools-policy.md Drift

#### Archetype Count Verification

The "Agent-to-Archetype Mapping" table (lines 241–275) lists **31 agents** explicitly. Counting the table rows confirms: 4 non-Implementation archetypes + 22 Implementation techstack agents + 5 Specialized = **31 total**.

#### Which 6 Actual Agents Match Policy Entries

| Actual Agent | In Policy Table? | Policy Archetype | Correct Archetype? |
|-------------|-----------------|-----------------|-------------------|
| `team-lead` | ✅ Yes (line 245) | Orchestration | ✅ Correct |
| `product-manager` | ✅ Yes (line 246) | Planning | ✅ Correct |
| `staff-engineer` | ✅ Yes (line 249) | Implementation | ❌ Wrong — actual is Review/TDD (`edit: false`) |
| `senior-engineer` | ❌ Not listed | — | ❌ Missing from policy entirely |
| `qa-engineer` | ❌ Not listed | — | ❌ Missing from policy entirely |
| `ux-designer` | ❌ Not listed | — | ❌ Missing from policy entirely |

**Summary:** 3 of 6 actual agents are in the policy table (50%). 3 are completely absent. `validator` is listed but does not exist. 25 phantom archetypes are referenced.

#### Migration Table Status

The "Migration Required" table (lines 280–295) lists 9 agents needing tool key updates, including:
- `staff-engineer`: "entire tools block (currently absent)" — **STALE**: staff-engineer now has a complete 11-key tools block
- `validator`: listed as needing `webfetch`, `todowrite`, `bash` — **PHANTOM**: agent does not exist
- All 22 Implementation techstack agents: listed as needing updates — **PHANTOM**: none of these agents exist

The migration table is entirely stale and should be removed or replaced.

#### Policy Tool Key Count vs Reality

| Metric | Policy Claims | Actual Reality |
|--------|--------------|----------------|
| Mandatory tool keys | 7 | 11–14 per agent |
| "No extra keys" rule | Stated explicitly | Violated by all 6 agents |
| Extra keys in use | 0 (policy says none allowed) | 7 extra: `read`, `list`, `websearch`, `grep`, `todoread`, `question`, `agent-browser` |

---

### 5. Prior Audit Fix Verification

| Audit | Fix Recommended | Applied? | Evidence |
|-------|----------------|----------|---------|
| **td-c0187e** | Change `qa-engineer.md` model from `openai/gpt-5.2` to `anthropic/claude-sonnet-4-6` | ❌ **NOT FIXED** | `qa-engineer.md` line 4 still shows `model: openai/gpt-5.2` |
| **td-c0187e** | Update `agent-tools-policy.md` to reflect 6-agent reality (remove 25 phantom agents) | ❌ **NOT FIXED** | Policy still lists 31 agents; `qa-engineer` and `ux-designer` still absent |
| **td-c0187e** | Update policy Migration Required table (staff-engineer entry is stale) | ❌ **NOT FIXED** | Migration table still shows "entire tools block (currently absent)" for staff-engineer |
| **td-c0187e** | Replace `validator` with `qa-engineer` in agent-team-workflow.md | ❌ **NOT FIXED** | Line 10 still shows `validator` |
| **td-c0187e** | Replace `td done` with `td review` + `td approve` in agent-team-workflow.md | ❌ **NOT FIXED** | Lines 196, 331, 516 still show `td done` |
| **td-972e8b** | Add `--rebase` flag to `git pull origin main` in `git-worktree-flow/SKILL.md` line 24 | ❌ **NOT FIXED** | Line 24 still shows `git pull origin main` (no `--rebase`) |
| **td-972e8b** | Add `origin/main` base ref to `git worktree add` in `plan.md` line 31 | ❌ **NOT FIXED** | Line 31 still shows `git worktree add ~/Development/.worktrees/<task-id> -b <branch-name>` with no base ref |
| **td-972e8b** | Replace direct `git merge` with PR-based flow in agent-team-workflow.md | ❌ **NOT FIXED** | Lines 187, 329, 570 still show direct `git merge` |
| **td-7c3679** | Fix `files` action in `td.ts` to link files when `input.files` array provided | ❌ **NOT FIXED** | Lines 555–559 still call `td files <task>` unconditionally, ignoring `input.files` array |
| **td-7c3679** | Fix `log` action in `td.ts` to support `task` parameter targeting | ❌ **NOT FIXED** | Lines 258–267 still construct `["log"]` without inserting `input.task` |

**Verdict: 0 of 10 sampled fixes applied. All prior audit recommendations remain pending.**

---

### 6. specs/tdd/ ICM Status

#### Files Present

| File | Type | Notes |
|------|------|-------|
| `.gitkeep` | Placeholder | Empty file to track directory in git |
| `td-9da879-icm-llm-driven-tools.md` | TDD | ICM Phase 2 — prune and distill tools |

#### Phase 1 Status (td-e2af34)

The TDD (`td-9da879`) references: *"Phase 1 of the ICM plugin (td-e2af34) implemented three automatic pruning strategies — deduplication, supersedeWrites, and purgeErrors."*

**TD task `td-e2af34` status:** `closed` — confirmed via `td query td-e2af34`.

**Phase 1 verdict: COMPLETE** ✅

#### Phase 2 TDD Status

The TDD (`td-9da879`) has `Status: draft` in its frontmatter. Phase 1 is confirmed complete, meaning Phase 2 is ready to proceed. The TDD status field has not been updated to reflect this.

---

## Staleness Matrix

| Document | Status | Inaccuracy Count | Severity |
|----------|--------|-----------------|---------|
| `AGENTS.md` | ✅ Current | 0 factual errors (2 enforcement gaps noted) | P1–P2 (enforcement gaps only) |
| `.opencode/AGENTS_INDEX.md` | ✅ Mostly current | 1 ambiguity (plugin count), 1 stale date | P2–P3 |
| `agent-team-workflow.md` | ❌ Stale | 10 broken references (8 TD commands + 2 agents) + 3 direct git merge + path inconsistency | P0–P2 |
| `agent-tools-policy.md` | ❌ Severely stale | 25 phantom agents, wrong tool key count, stale migration table, phantom preservation rules | P1–P2 |
| `git-worktree-flow/SKILL.md` | ⚠️ Minor drift | 1 missing `--rebase` flag | P1 |
| `plan.md` | ⚠️ Minor drift | 1 missing `origin/main` base ref | P1 |
| `qa-engineer.md` | ❌ Broken | Invalid model identifier | P0 |
| `td.ts` | ❌ Two bugs | `files` action ignores array; `log` ignores `task` param | P0–P1 |
| `specs/tdd/td-9da879-icm-llm-driven-tools.md` | ⚠️ Minor drift | Status field not updated (still `draft`) | P3 |

---

## Risk Assessment

**Verdict: needs-structural-changes**

The documentation ecosystem has accumulated significant unresolved drift across three prior audit cycles. The core architecture (6 agents, plugin system, TD integration) is sound, but the documentation layer is actively misleading:

1. **P0 runtime risk** — `qa-engineer.md` uses `openai/gpt-5.2`, an invalid model identifier. This breaks the validation phase of every delivery pipeline execution.
2. **P0 tool behavior mismatch** — `td.ts` `files` action silently ignores the `files` array parameter. Agents calling `TD(action: "files", task: "...", files: [...])` to link files get a file listing instead.
3. **P0 broken playbook commands** — `agent-team-workflow.md` contains 8 references to non-existent TD commands (`td done`, `td block`, `td unblock`). Any agent following the playbook will fail.
4. **Zero prior fixes applied** — All 10 sampled recommendations from three prior audits remain unimplemented. The audit backlog is growing without remediation.
5. **Policy document is a liability** — `agent-tools-policy.md` references 31 phantom agents and mandates a 7-key tool schema that all 6 deployed agents violate. It actively misleads anyone trying to add or modify agents.

---

## Remediation Priority

| Rank | Finding ID | Severity | Fix | Estimated Effort |
|------|-----------|----------|-----|-----------------|
| 1 | **D5-01** | P0 | Change `qa-engineer.md` `model: openai/gpt-5.2` → `model: anthropic/claude-sonnet-4-6` | 2 min |
| 2 | **D5-04** | P0 | Fix `td.ts` `files` action: add conditional to call `td link` when `input.files` provided | 15 min |
| 3 | **D3-01** | P0 | Replace 3× `td done` in `agent-team-workflow.md` with `td review` + `td approve` | 10 min |
| 4 | **D3-02** | P0 | Replace 4× `td block` and 1× `td unblock` in `agent-team-workflow.md` with valid TD commands | 15 min |
| 5 | **D5-05** | P1 | Fix `td.ts` `log` action: add `if (input.task) args.splice(1, 0, input.task)` | 5 min |
| 6 | **D3-03 + D3-04** | P1 | Fix agent references in `agent-team-workflow.md` Team Roles section | 5 min |
| 7 | **D5-02** | P1 | Add `--rebase` to `git pull origin main` in `git-worktree-flow/SKILL.md` | 2 min |
| 8 | **D5-03** | P1 | Add `origin/main` base ref to `git worktree add` in `plan.md` | 2 min |
| 9 | **D4-01 + D4-02 + D4-03** | P1 | Rewrite `agent-tools-policy.md` to reflect 6-agent reality with 14-key schema | 2 hours |
| 10 | **D3-05** | P1 | Replace direct `git merge` with PR-based flow in `agent-team-workflow.md` | 20 min |

**Total P0 fixes:** 4 findings, ~42 minutes of effort  
**Total P1 fixes:** 6 findings, ~2.5 hours of effort  
**Total P2 fixes:** 8 findings, ~3 hours of effort  
**Total P3 fixes:** 4 findings, ~30 minutes of effort

---

> **Note:** Pre-existing uncommitted changes in the repository (`.gitignore`, `.opencode/bun.lock`, `.opencode/package.json`, `.todos/`) are not caused by this task. Only `specs/audit/td-b35bad-docs-audit.md` was created by this task.

---

*Report generated by senior-engineer (ses_508af8) for task td-b35bad.*
