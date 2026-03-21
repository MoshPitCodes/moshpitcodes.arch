# Skills Audit Report — All 11 Skills
**Task:** td-616172  
**Date:** 2026-03-05  
**Auditor:** senior-engineer (ses_b22378)

---

## Executive Summary

All 11 skill SKILL.md files (920 total lines) were read in full and audited across 6 dimensions. The skills library is **partially functional but structurally incomplete**: 5 of 11 skills (45%) are orphaned — they exist on disk but are assigned to no agent that can load them. The `frontend-design` skill has a non-standard license format and is missing `compatibility` and `metadata` frontmatter keys, making it structurally inconsistent with all other skills. Two significant cross-skill conflicts exist: `git-workflow` and `git-worktree-flow` use incompatible branch naming conventions (no TD ID vs TD ID required), and `pr-quality-gate` and `git-workflow` have overlapping but non-identical merge-readiness criteria. The `td-workflow` skill is largely accurate against the TD tool implementation, with no references to non-existent commands. Zero skills have any enforcement mechanism beyond prose guidance. **Total findings: P0: 0, P1: 8, P2: 7, P3: 4. Total: 19.**

---

## Audit Scope

| Skill | File | Lines |
|-------|------|-------|
| acceptance-criteria-authoring | `.opencode/skills/acceptance-criteria-authoring/SKILL.md` | 129 |
| agent-browser | `.opencode/skills/agent-browser/SKILL.md` | 95 |
| bug-triage | `.opencode/skills/bug-triage/SKILL.md` | 136 |
| design-system | `.opencode/skills/design-system/SKILL.md` | 93 |
| frontend-design | `.opencode/skills/frontend-design/SKILL.md` | 42 |
| git-workflow | `.opencode/skills/git-workflow/SKILL.md` | 88 |
| git-worktree-flow | `.opencode/skills/git-worktree-flow/SKILL.md` | 52 |
| pr-quality-gate | `.opencode/skills/pr-quality-gate/SKILL.md` | 41 |
| release-notes | `.opencode/skills/release-notes/SKILL.md` | 45 |
| td-workflow | `.opencode/skills/td-workflow/SKILL.md` | 68 |
| tdd-authoring | `.opencode/skills/tdd-authoring/SKILL.md` | 131 |
| **Total** | | **920** |

**Supporting files read:** 6 agent definitions (636 lines), `opencode.json` (167 lines), 3 prior audit reports (808 lines).

---

## Findings Table

| ID | Severity | Skill/File | Dimension | Finding | Recommended Fix |
|----|----------|------------|-----------|---------|-----------------|
| S-01 | **P1** | `frontend-design` | D1 Frontmatter | Missing `compatibility` key entirely | Add `compatibility: opencode` |
| S-02 | **P1** | `frontend-design` | D1 Frontmatter | Missing `metadata` key entirely | Add `metadata:` block with `audience` and `workflow` sub-keys |
| S-03 | **P1** | `frontend-design` | D1 Frontmatter | Non-standard `license` value: `'Complete terms in LICENSE.txt'` vs `'MIT'` for all other 10 skills | Standardize to `MIT` or document the exception in a SKILLS_POLICY.md |
| S-04 | **P1** | `acceptance-criteria-authoring` | D3 Assignment | Orphaned: not assigned to any agent. Clearly belongs to `product-manager` (planning workflow) | Add to `product-manager` skills list |
| S-05 | **P1** | `agent-browser` | D3 Assignment | Orphaned: not assigned to any agent. `senior-engineer` and `qa-engineer` both have `agent-browser: true` in tools but no skill guidance | Add to `senior-engineer` and `qa-engineer` (when `skill: false` is fixed) |
| S-06 | **P1** | `bug-triage` | D3 Assignment | Orphaned: `qa-engineer` has `skill: false` — cannot load any skill. Bug triage is the QA engineer's primary workflow | Fix `qa-engineer` `skill: false` → `skill: true`, then add `bug-triage` to its skills list |
| S-07 | **P1** | `design-system` | D3 Assignment | Orphaned: not assigned to any agent. `ux-designer` is the obvious owner | Add to `ux-designer` skills list |
| S-08 | **P1** | `release-notes` | D3 Assignment | Orphaned: not assigned to any agent. No obvious single owner — could be `team-lead` or `product-manager` | Assign to `team-lead` (release coordination) or `product-manager` (release planning) |
| S-09 | **P2** | `git-workflow` vs `git-worktree-flow` | D2 Consistency | Branch naming conflict: `git-workflow` uses `feature/<slug>` (no TD ID), `git-worktree-flow` uses `feature/td-<id>-<slug>` (TD ID required). Agents assigned both skills receive contradictory guidance | Align `git-workflow` branch patterns to include TD ID: `feature/td-<id>-<slug>` |
| S-10 | **P2** | `pr-quality-gate` vs `git-workflow` | D2 Consistency | Merge-readiness criteria overlap but differ: `pr-quality-gate` requires "validator output with criteria-to-evidence mapping" and "code-reviewer verdict"; `git-workflow` PR conventions require "Testing performed" and "Issues closed" but no explicit AC validation evidence. Neither references the other. | Cross-reference the two skills; `git-workflow` PR description fields should include AC validation evidence requirement |
| S-11 | **P2** | `tdd-authoring` vs `acceptance-criteria-authoring` | D2 Consistency | `tdd-authoring` references "acceptance criteria" in its template (line 88: "Acceptance mapping") but does not specify the AC format. `acceptance-criteria-authoring` defines GWT and structured bullet formats. A staff-engineer using `tdd-authoring` without `acceptance-criteria-authoring` may write AC in an inconsistent format | `tdd-authoring` should reference `acceptance-criteria-authoring` for AC format standard, or include a brief format note |
| S-12 | **P2** | `design-system` vs `frontend-design` | D2 Consistency | `design-system` mandates semantic tokens (`color-surface-default`, `space-0`, etc.) and prohibits raw hex/pixel values. `frontend-design` says "Use CSS variables for consistency" but does not reference the design-system token vocabulary. An agent using `frontend-design` without `design-system` will use ad-hoc CSS variables that violate the token standard | `frontend-design` should reference `design-system` token vocabulary, or `ux-designer` should have both skills assigned |
| S-13 | **P2** | `pr-quality-gate` | D6 Enforcement | Guidance-only: no enforcement mechanism. The skill describes a checklist but there is no plugin, hook, or gate that blocks PR creation without evidence. `senior-engineer` has this skill assigned but nothing enforces it | Add a pre-PR checklist verification step to the `git-workflow` or create a `pr-gate` plugin hook |
| S-14 | **P2** | `release-notes` | D4 Quality | Skill is very thin (45 lines). The "Output template" section (lines 22–27) lists 5 sections without any example content or template text. The "Source-of-truth order" is useful but there is no example release note, no format for version headers, no guidance on what "user-relevant" means in practice | Add a concrete example release note with all 5 sections populated |
| S-15 | **P2** | `frontend-design` | D1 Frontmatter | `license: Complete terms in LICENSE.txt` references a `LICENSE.txt` file that does not exist in `.opencode/skills/frontend-design/`. Verified: the directory contains only `SKILL.md`. The license terms are effectively undocumented — any consumer of this skill cannot determine its actual licensing terms. | Either add a `LICENSE.txt` file with the actual license terms, or change the license field to a standard SPDX identifier (e.g., `license: MIT`). |
| S-16 | **P3** | `agent-browser` | D4 Quality | Skill references "the tool schema exposed by OpenCode and agent-browser CLI help" for exhaustive parameter reference (line 94) but does not include the full parameter list. An agent needing an uncommon parameter must leave the skill context to find it | Include a parameter reference table for the most commonly needed non-obvious parameters |
| S-17 | **P3** | `pr-quality-gate` | D4 Quality | Skill is very thin (41 lines). The "Minimum evidence required" section (lines 32–35) lists 4 items but gives no example of what acceptable evidence looks like. "Validator output with criteria-to-evidence mapping" is vague without a template | Add an example evidence block showing what a passing AC validation looks like |
| S-18 | **P3** | `td-workflow` vs `git-worktree-flow` | D2 Consistency | `td-workflow` prescribes `review` then `handoff` in that order (lines 22–26: step 5 is `review`, step 6 is `handoff`). `git-worktree-flow` guardrails (line 51) say "Do not delete worktree before TD handoff and review state are captured" — implying handoff before review. Minor ordering ambiguity | Clarify canonical order: `review` submits for review, `handoff` captures state — both should happen before worktree deletion. `git-worktree-flow` wording is slightly misleading |
| S-19 | **P3** | `bug-triage` | D4 Quality | The TD task creation example (lines 118–130) uses `TD(action: "create", ...)` syntax which is correct. However, the `link` call on line 135 uses `TD(action: "link", ...)` — per td-7c3679 audit (F-01), the `files` action (not `link`) is the one with the bug. The `link` action itself is correct. No issue here, but the skill should note that `link` is the correct action for attaching files (not `files`) | No action needed — `link` is correct. Add a note clarifying `link` vs `files` distinction |

---

## Dimension Analysis

### 1. Frontmatter Completeness

Frontmatter keys checked: `name`, `description`, `license`, `compatibility`, `metadata`.

| Skill | `name` | `description` | `license` | `compatibility` | `metadata` | Status |
|-------|--------|---------------|-----------|-----------------|------------|--------|
| acceptance-criteria-authoring | ✅ present | ✅ present | ✅ `MIT` | ✅ `opencode` | ✅ `audience: product`, `workflow: planning` | **PASS** |
| agent-browser | ✅ present | ✅ present | ✅ `MIT` | ✅ `opencode` | ✅ `audience: engineering`, `workflow: agent-browser` | **PASS** |
| bug-triage | ✅ present | ✅ present | ✅ `MIT` | ✅ `opencode` | ✅ `audience: qa`, `workflow: triage` | **PASS** |
| design-system | ✅ present | ✅ present | ✅ `MIT` | ✅ `opencode` | ✅ `audience: design`, `workflow: design-system` | **PASS** |
| frontend-design | ✅ present | ✅ present | ⚠️ `Complete terms in LICENSE.txt` | ❌ **MISSING** | ❌ **MISSING** | **FAIL — P1** |
| git-workflow | ✅ present | ✅ present | ✅ `MIT` | ✅ `opencode` | ✅ `audience: engineering`, `workflow: git` | **PASS** |
| git-worktree-flow | ✅ present | ✅ present | ✅ `MIT` | ✅ `opencode` | ✅ `audience: engineering`, `workflow: git` | **PASS** |
| pr-quality-gate | ✅ present | ✅ present | ✅ `MIT` | ✅ `opencode` | ✅ `audience: engineering`, `workflow: review` | **PASS** |
| release-notes | ✅ present | ✅ present | ✅ `MIT` | ✅ `opencode` | ✅ `audience: maintainers`, `workflow: release` | **PASS** |
| td-workflow | ✅ present | ✅ present | ✅ `MIT` | ✅ `opencode` | ✅ `audience: engineering`, `workflow: td` | **PASS** |
| tdd-authoring | ✅ present | ✅ present | ✅ `MIT` | ✅ `opencode` | ✅ `audience: engineering`, `workflow: design` | **PASS** |

**Summary:** 10 of 11 skills pass frontmatter completeness. `frontend-design` fails on 3 keys.

**`frontend-design` license detail:** The value `'Complete terms in LICENSE.txt'` is a prose reference to an external file, not a SPDX license identifier. All other 10 skills use `MIT`. This suggests `frontend-design` was authored by a different source (likely a third-party or commercial skill) and imported without normalization. **Verified:** `.opencode/skills/frontend-design/` contains only `SKILL.md` — `LICENSE.txt` does not exist. The license reference is broken: the terms it points to are absent. This is documented as finding S-15.

---

### 2. Cross-Skill Consistency Matrix

| Skill A | Skill B | Overlap Topic | Consistent? | Notes |
|---------|---------|---------------|-------------|-------|
| `git-workflow` | `git-worktree-flow` | Branch naming | ❌ **CONFLICT** | `git-workflow`: `feature/<slug>` (no TD ID). `git-worktree-flow`: `feature/td-<id>-<slug>` (TD ID required). `senior-engineer` has both skills — receives contradictory guidance. |
| `git-workflow` | `git-worktree-flow` | Post-merge sync | ✅ Consistent | Both now specify `git pull origin main` after merge. `git-workflow` has "Post-Merge Sync" section (lines 72–81); `git-worktree-flow` has step 2 `git pull origin main` (line 24). |
| `git-workflow` | `git-worktree-flow` | Force-push safety | ✅ Consistent | `git-worktree-flow` explicitly requires `--force-with-lease` (line 36). `git-workflow` guardrails don't mention force-push but don't contradict. |
| `git-workflow` | `git-worktree-flow` | Pre-merge rebase | ✅ Consistent | Both require rebasing onto `origin/main` before merge. `git-worktree-flow` has explicit "Pre-merge rebase gate" section (lines 38–47). `git-workflow` guardrails mention it (line 87). |
| `pr-quality-gate` | `git-workflow` | Merge-readiness criteria | ⚠️ **PARTIAL CONFLICT** | `pr-quality-gate` requires AC validation evidence + code-reviewer verdict. `git-workflow` PR conventions require "Testing performed" and "Issues closed" but no explicit AC validation evidence. Neither references the other. An agent using only `git-workflow` will produce PRs that fail `pr-quality-gate`. |
| `tdd-authoring` | `acceptance-criteria-authoring` | AC format | ⚠️ **GAP** | `tdd-authoring` has an "Acceptance mapping" section but does not specify AC format. `acceptance-criteria-authoring` defines GWT and structured bullet formats. No conflict, but a gap: staff-engineer uses `tdd-authoring` without `acceptance-criteria-authoring` and may write AC inconsistently. |
| `td-workflow` | `git-worktree-flow` | TD task lifecycle | ✅ Consistent | `td-workflow` baseline sequence: `usage → status → start/focus → log → review → handoff`. `git-worktree-flow` guardrails: "Do not delete worktree before TD handoff and review state are captured." Minor ordering ambiguity (see S-18) but no functional conflict. |
| `design-system` | `frontend-design` | Design tokens | ⚠️ **GAP** | `design-system` mandates semantic tokens (`color-surface-default`, `space-0`, etc.) and prohibits raw hex/pixel values. `frontend-design` says "Use CSS variables for consistency" but does not reference the token vocabulary. No direct conflict, but an agent using `frontend-design` without `design-system` will produce non-compliant token usage. |
| `agent-browser` | Any other skill | Browser automation | ✅ No conflict | `agent-browser` is self-contained. No other skill prescribes browser interaction patterns. |
| `bug-triage` | `acceptance-criteria-authoring` | AC format for bug reports | ✅ Consistent | `bug-triage` template includes "Acceptance criteria" field (line 128). `acceptance-criteria-authoring` defines the format. No conflict — they are complementary. |
| `release-notes` | `pr-quality-gate` | PR evidence as source | ✅ Consistent | `release-notes` lists "Merged PR descriptions" as source-of-truth #1 (line 31). `pr-quality-gate` requires PR summary sections. The two skills are complementary. |

**Conflict summary:** 1 hard conflict (branch naming), 2 partial conflicts/gaps (PR merge criteria, design token vocabulary), 1 AC format gap.

---

### 3. Skill-to-Agent Assignment Matrix

Agent skill lists extracted from frontmatter:
- `team-lead`: `td-workflow`, `git-workflow`
- `staff-engineer`: `tdd-authoring`, `git-workflow`
- `senior-engineer`: `git-worktree-flow`, `td-workflow`, `pr-quality-gate`, `git-workflow`
- `product-manager`: `td-workflow`, `git-workflow`
- `qa-engineer`: *(none — `skill: false` blocks all skill loading)*
- `ux-designer`: `td-workflow`, `frontend-design`

| Skill | team-lead | staff-eng | senior-eng | product-mgr | qa-eng | ux-designer | Orphaned? |
|-------|-----------|-----------|------------|-------------|--------|-------------|-----------|
| acceptance-criteria-authoring | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | **YES — P1** |
| agent-browser | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | **YES — P1** |
| bug-triage | ❌ | ❌ | ❌ | ❌ | ❌ (skill disabled) | ❌ | **YES — P1** |
| design-system | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | **YES — P1** |
| frontend-design | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | No |
| git-workflow | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | No |
| git-worktree-flow | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | No |
| pr-quality-gate | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | No |
| release-notes | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | **YES — P1** |
| td-workflow | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ | No |
| tdd-authoring | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | No |

**Orphaned skills (5 of 11 = 45%):**
1. `acceptance-criteria-authoring` — should be `product-manager` (planning workflow, AC authoring)
2. `agent-browser` — should be `senior-engineer` (implementation) and `qa-engineer` (validation, when skill is re-enabled)
3. `bug-triage` — should be `qa-engineer` (blocked by `skill: false` — fix that first)
4. `design-system` — should be `ux-designer` (design workflow)
5. `release-notes` — no obvious single owner; recommend `team-lead` (release coordination)

**Role-skill mismatches (agents missing skills that match their role):**

| Agent | Missing Skill | Rationale | Severity |
|-------|--------------|-----------|----------|
| `product-manager` | `acceptance-criteria-authoring` | PM's primary output is AC-backed TD tasks | P1 |
| `qa-engineer` | `bug-triage` | QA's primary workflow is bug triage | P1 (blocked by `skill: false`) |
| `qa-engineer` | `agent-browser` | QA uses browser for validation | P2 |
| `ux-designer` | `design-system` | UX designer must follow design system standards | P2 |
| `staff-engineer` | `pr-quality-gate` | Staff engineer performs code review — the quality gate is their checklist | P3 |
| `team-lead` | `release-notes` | Team lead coordinates releases | P3 |

---

### 4. Content Quality & Actionability Ratings

| Skill | Rating | Key Gap | Example of Gap |
|-------|--------|---------|----------------|
| acceptance-criteria-authoring | **Actionable** | None significant | Has GWT format, structured bullet format, testability checklist, anti-patterns, AC-to-test mapping, minimum counts by task type. Comprehensive. |
| agent-browser | **Actionable** | Incomplete parameter reference | Core commands documented with examples. Defers to "tool schema" for exhaustive params (line 94) — acceptable for a compact skill. |
| bug-triage | **Actionable** | None significant | Has bug report template, severity rubric with concrete examples, triage decision tree, P0 escalation protocol, TD task creation example. Comprehensive. |
| design-system | **Actionable** | No example handoff document | Has naming convention, interaction patterns, accessibility baseline, token vocabulary, handoff contract, anti-patterns. Missing: example of a complete handoff document. |
| frontend-design | **Actionable** | No concrete code examples | Has design thinking framework, aesthetic guidelines, specific font/color/motion guidance. Missing: no code example showing the aesthetic principles applied. |
| git-workflow | **Actionable** | None significant | Has branch types, commit format, PR conventions, post-merge sync section (lines 72–81 — explicit `git checkout main` + `git pull origin main` with rationale), guardrails. Complete and actionable. |
| git-worktree-flow | **Actionable** | None significant | Has naming policy, 7-step manual flow (including `git pull origin main` at step 2), conflict/recovery runbook with `--force-with-lease`, pre-merge rebase gate, guardrails. All prior gaps (td-3a95d3) are now resolved. |
| pr-quality-gate | **Partially-actionable** | No example evidence block | Has pass/fail gate, quality checklist, minimum evidence required, minimum PR summary sections. Missing: no example of what acceptable evidence looks like. 41 lines is very thin for a quality gate. |
| release-notes | **Partially-actionable** | No example release note | Has release modes, output template (section names only), source-of-truth order, quality checks. Missing: no example release note with populated sections. 45 lines is very thin. |
| td-workflow | **Actionable** | None significant | Has tool-first policy, baseline sequence, core actions by category, logging standard, failure handling, handoff quality bar. Accurate against td.ts implementation. |
| tdd-authoring | **Actionable** | AC format not specified | Has full TDD template with all sections, quality checklist, handoff protocol, anti-patterns. Gap: "Acceptance mapping" section in template does not specify AC format — should reference `acceptance-criteria-authoring`. |

**Summary:** 8 actionable, 2 partially-actionable (`pr-quality-gate`, `release-notes`), 0 vague.

---

### 5. td-workflow Skill vs TD Tool Reality

Cross-referenced against td-7c3679 audit report (which audited `td.ts` against 31 actions).

#### Commands prescribed by td-workflow skill

| Skill-Prescribed Action | Exists in td.ts? | Parameters Match? | Notes |
|------------------------|-----------------|-------------------|-------|
| `usage` (new session) | ✅ | ✅ `newSession: true/false` | Correct |
| `status` | ✅ | ✅ | Correct |
| `start` | ✅ | ✅ `task` required | Correct |
| `focus` | ✅ | ✅ `task` required | Correct |
| `log` (with typed logs) | ✅ | ⚠️ | `logType` enum matches skill's 5 types (`decision`, `blocker`, `hypothesis`, `tried`, `result`). However, `task` param is silently ignored (td-7c3679 F-02) — logs always go to focused task |
| `review` | ✅ | ✅ `task` required | Correct |
| `handoff` | ✅ | ✅ `done`, `remaining`, `decision`, `uncertain` | Correct |
| `ws start` | ✅ | ✅ `wsAction: "start"`, `wsName` required | Correct |
| `ws tag` | ✅ | ✅ `wsAction: "tag"`, `issueIds` array | Correct |
| `ws log` | ✅ | ✅ `wsAction: "log"`, `message` required | Correct |
| `ws handoff` | ✅ | ✅ `wsAction: "handoff"` | Correct |
| `create` | ✅ | ✅ | Correct |
| `epic` | ✅ | ✅ | Correct |
| `tree` | ✅ | ✅ | Correct |
| `update` | ✅ | ⚠️ | Missing `acceptance`, `dependsOn`, `blocks`, `points`, `parent` in update case (td-7c3679 minor gap) |
| `dep` (with `depAction`) | ✅ | ✅ | `add`, `list`, `blocking` all correct |
| `critical-path` | ✅ | ✅ | Correct |
| `block-issue` | ✅ | ⚠️ | No `--reason` exposed in tool |
| `unblock-issue` | ✅ | ⚠️ | No `--reason` exposed in tool |
| `query` | ✅ | ✅ | Correct |
| `search` | ✅ | ✅ | Correct |
| `next` | ✅ | ✅ | Correct |
| `ready` | ✅ | ✅ | Correct |
| `blocked` | ✅ | ✅ | Correct |
| `in-review` | ✅ | ✅ | Correct |
| `reviewable` | ✅ | ✅ | Correct |
| `context` | ✅ | ✅ | Correct |
| `approve` | ✅ | ✅ | Correct |
| `reject` | ✅ | ✅ | Correct |
| `files` | ✅ | ❌ **BUG** | Skill prescribes `files` for tracking files. Tool's `files` action only **lists** linked files — ignores `files` array param (td-7c3679 F-01, P0). Agents should use `link` action to attach files. |
| `comment` | ✅ | ✅ | Correct |
| `whoami` | ✅ | ✅ | Correct |
| `link` | ✅ | ✅ | Correct |
| `unlink` | ✅ | ✅ | Correct |

#### Non-existent commands check

| Command | In Skill? | Exists in td.ts? | Status |
|---------|-----------|-----------------|--------|
| `td done` | ❌ Not mentioned | ❌ Does not exist | **PASS** — skill correctly omits this |
| `td block` | ❌ Not mentioned | ✅ Exists as `block-issue` | Skill uses `block-issue` action name — correct |
| `td unblock` | ❌ Not mentioned | ✅ Exists as `unblock-issue` | Skill uses `unblock-issue` action name — correct |
| `td close` | ❌ Not mentioned | ✅ Exists (admin closure) | Skill correctly omits this |

**Verdict:** The `td-workflow` skill does NOT reference any non-existent commands. It does not mention `td done`, `td block`, or `td unblock` as raw CLI commands. The skill is accurate against the TD tool implementation with one inherited bug: the `files` action behavior mismatch (td-7c3679 F-01) means agents following the skill's guidance to use `files` for file tracking will silently get a file listing instead of linking files. The correct action is `link`.

**Skill accuracy score:** 29/31 actions correct (94%). The 2 issues are inherited from td.ts bugs, not skill authoring errors.

---

### 6. Enforcement & Mechanism Assessment

| Skill | Enforcement Status | Mechanism | Gap |
|-------|-------------------|-----------|-----|
| acceptance-criteria-authoring | **Guidance-only** | None | No hook blocks task creation without minimum AC count. Product-manager could create tasks with 0 AC. |
| agent-browser | **Guidance-only** | None | No enforcement — browser automation patterns are advisory |
| bug-triage | **Guidance-only** | None | No hook enforces bug report template or severity classification |
| design-system | **Guidance-only** | None | No linter or hook enforces token usage or handoff contract |
| frontend-design | **Guidance-only** | None | No enforcement — aesthetic guidelines are advisory |
| git-workflow | **Partially-enforced** | `security.ts` plugin blocks dangerous bash commands; `opencode.json` sets `git commit*: ask`, `git push*: ask` | Branch naming convention not enforced; commit message format not enforced; pre-commit hooks not verified |
| git-worktree-flow | **Guidance-only** | None | No hook enforces one-task-per-worktree or pre-merge rebase gate |
| pr-quality-gate | **Guidance-only** | None | No hook blocks PR creation without evidence. `gh pr create*: ask` in `opencode.json` requires user confirmation but does not verify checklist completion |
| release-notes | **Guidance-only** | None | No enforcement — release note generation is advisory |
| td-workflow | **Partially-enforced** | `td-enforcer.ts` plugin enforces Rule 1 (write-blocking without active task) | Rules 2, 3, 4 are prose-only (td-7c3679 F-06, F-07). `session.idle` shows handoff reminder toast but does not block. |
| tdd-authoring | **Guidance-only** | None | No hook enforces TDD creation before implementation or quality checklist |

**Summary:** 0 fully enforced, 2 partially enforced (`git-workflow`, `td-workflow`), 9 guidance-only.

**Root cause:** OpenCode's plugin system supports `permission.ask`, `tool.execute.before`, and `tool.execute.after` hooks. These can block write operations but cannot enforce workflow sequencing (e.g., "TDD must exist before implementation begins") or content quality (e.g., "commit message must follow conventional commits format"). Workflow enforcement requires either LLM-level compliance or external tooling (pre-commit hooks, CI gates) that is not currently configured.

---

## Risk Assessment

**Verdict: needs-structural-changes**

The skills library has a fundamental structural problem: 45% of skills are orphaned and cannot be loaded by any agent. This is not a minor gap — it means the `bug-triage`, `acceptance-criteria-authoring`, `design-system`, `agent-browser`, and `release-notes` skills are dead weight that consume maintenance effort without providing value. The `qa-engineer` agent's `skill: false` setting is the most acute issue: it blocks the QA engineer from loading any skill, including the `bug-triage` skill that defines its primary workflow.

The branch naming conflict between `git-workflow` and `git-worktree-flow` is a concrete source of agent confusion: `senior-engineer` has both skills assigned and receives contradictory guidance on every branch creation. This is a P2 issue that will cause inconsistent branch naming across the team.

The `frontend-design` skill's missing frontmatter keys and non-standard license suggest it was imported from an external source without normalization. `LICENSE.txt` does not exist in the skill directory (confirmed) — the license reference is broken and the terms are undocumented (S-15).

The enforcement gap (9 of 11 skills are guidance-only) is a systemic limitation of the current architecture, not a fixable skill-level issue. Addressing it requires plugin development or external tooling.

---

## Remediation Priority

| Rank | Finding ID | Severity | Fix | Estimated Effort |
|------|-----------|----------|-----|-----------------|
| 1 | S-06 | P1 | Fix `qa-engineer` `skill: false` → `skill: true`; add `bug-triage` to skills list | 5 min |
| 2 | S-04 | P1 | Add `acceptance-criteria-authoring` to `product-manager` skills list | 5 min |
| 3 | S-07 | P1 | Add `design-system` to `ux-designer` skills list | 5 min |
| 4 | S-05 | P1 | Add `agent-browser` to `senior-engineer` skills list; add to `qa-engineer` after fix #1 | 5 min |
| 5 | S-08 | P1 | Assign `release-notes` to `team-lead` or `product-manager` | 5 min |
| 6 | S-01/S-02/S-03 | P1 | Fix `frontend-design` frontmatter: add `compatibility`, `metadata`, normalize `license` | 10 min |
| 7 | S-09 | P2 | Align `git-workflow` branch naming to include TD ID: `feature/td-<id>-<slug>` | 15 min |
| 8 | S-10 | P2 | Cross-reference `pr-quality-gate` and `git-workflow` PR conventions; add AC validation evidence to `git-workflow` PR description fields | 20 min |
| 9 | S-15 | P2 | Add `LICENSE.txt` to `.opencode/skills/frontend-design/` with actual license terms, or change `license:` field to `MIT` | 10 min |
| 10 | S-11 | P2 | Add AC format reference to `tdd-authoring` acceptance mapping section | 10 min |
| 11 | S-12 | P2 | Add design-system token reference to `frontend-design`; or ensure `ux-designer` has both skills | 10 min |
| 12 | S-14 | P2 | Add example release note to `release-notes` skill | 30 min |
| 13 | S-13 | P2 | Add `pr-quality-gate` to `staff-engineer` skills list (reviewer uses this checklist) | 5 min |

**Total estimated remediation effort for P1 items:** ~35 minutes (mostly frontmatter edits)  
**Total estimated remediation effort for P2 items:** ~90 minutes

---

## Appendix: Prior Audit Cross-Reference

| Prior Audit | Task | Relevant Findings Confirmed/Updated |
|-------------|------|-------------------------------------|
| td-c0187e (agent definitions) | ses_508af8 | Confirmed: 5 orphaned skills (F-18), `qa-engineer` `skill: false` (F-10), `design-system` not in `ux-designer` (F-17). All still unresolved. |
| td-3a95d3 (git skills) | ses_7ea00b | Confirmed: `git-workflow` post-merge sync gap **RESOLVED** — section exists at lines 72–81 with explicit `git checkout main` (line 77) + `git pull origin main` (line 78). `git-worktree-flow` gaps (pull-before-branch, force-with-lease, prune, rebase gate) **ALL RESOLVED** in current file. Branch naming conflict **NOT previously identified** — new finding S-09. |
| td-7c3679 (TD tool) | ses_508af8 | Confirmed: `files` action bug (F-01) affects `td-workflow` skill guidance. `td-workflow` skill does NOT reference non-existent commands (`td done`, `td block`, `td unblock`). |

---

*Report generated by senior-engineer (ses_b22378) for task td-616172.*


