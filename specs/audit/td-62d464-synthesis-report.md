# Synthesis Report: Consolidated Risk Register & Prioritized Remediation Plan

**Task:** td-62d464  
**Date:** 2026-03-06  
**Author:** senior-engineer (ses_732b15)  
**Scope:** Synthesis of all findings from Tasks 1–7 (td-c0187e, td-7c3679, td-972e8b, td-616172, td-94e7b9, td-b35bad, td-1cc703) plus 3 prior-cycle audits included as additional context (td-2b04e5, td-3a95d3, td-99cb98)  
**Parent Epic:** td-25bf87 — Deep Workflow Analysis: Agents, TD Tool, Git Worktrees, and Skills

---

## Table of Contents

1. [Unified Risk Register](#1-unified-risk-register)
2. [Critical Path Analysis — Top 5 Blockers](#2-critical-path-analysis--top-5-blockers)
3. [Remediation Epic Proposal](#3-remediation-epic-proposal)
4. [Architecture Assessment](#4-architecture-assessment)
5. [Sidecar Workspace Recommendation](#5-sidecar-workspace-recommendation)

---

## 1. Unified Risk Register

### Deduplication Methodology

Raw findings across all 10 audit reports totalled approximately 116 individual items. After deduplication (merging findings that target the same root cause across multiple audits), the register contains **52 unique findings**. Where multiple audits reported the same issue, the highest severity assigned by any audit is used and all source references are listed.

Severity scale: **P0** (runtime-breaking / pipeline-blocking) → **P1** (high-impact, must fix before next release) → **P2** (medium-impact, fix in next sprint) → **P3** (low-impact, fix when convenient).

Effort scale: **XS** (<15 min) · **S** (15–60 min) · **M** (1–4 hrs) · **L** (4–8 hrs) · **XL** (>1 day).

Owner abbreviations: **SE** = senior-engineer · **SE-staff** = staff-engineer · **PM** = product-manager · **TL** = team-lead · **QA** = qa-engineer · **UX** = ux-designer · **ARCH** = architecture decision (team-level).

---

### 1.1 P0 — Runtime-Breaking / Pipeline-Blocking

| ID | Severity | Finding | Source Audits | Impact | Effort | Owner |
|----|----------|---------|--------------|--------|--------|-------|
| R-01 | P0 | `qa-engineer.md` uses `model: openai/gpt-5.2` — not a valid OpenAI model identifier; high likelihood of runtime failure. Breaks the entire validation phase of every delivery pipeline execution. | td-c0187e (F-01), td-b35bad (D5-01), td-2b04e5 (original: gpt-5.3-codex) | Validation phase completely blocked | XS | SE |
| R-02 | P0 | `td.ts` `files` action ignores the `files` array parameter — silently calls `td files <task>` (list only) instead of linking files. Any agent calling `TD(action:"files", files:[...])` to link files gets a listing instead. | td-7c3679 (F-01), td-b35bad (D5-04), td-616172 (S-19 note) | Silent data loss: file links never recorded | S | SE |
| R-03 | P0 | `agent-team-workflow.md` contains 8 references to non-existent TD commands: `td done` (3×), `td block` (4×), `td unblock` (1×). Any agent following the playbook will fail at these steps. | td-c0187e (F-06), td-972e8b (A-02/A-03/A-04), td-7c3679 (F-13), td-b35bad (D3-01/D3-02) | Agent workflow failures at 8 execution points | S | SE |
| R-04 | P0 | `team-lead.md` does not include explicit TD requirement text when spawning sub-agents (AGENTS.md Rule 3). Sub-agents operate without TD enforcement — writes are unblocked, handoffs may be skipped. | td-94e7b9 (H-01) | TD enforcement broken for all sub-agent sessions | M | TL |

---

### 1.2 P1 — High Impact, Must Fix Before Next Release

| ID | Severity | Finding | Source Audits | Impact | Effort | Owner |
|----|----------|---------|--------------|--------|--------|-------|
| R-05 | P1 | `qa-engineer.md` has `skill: false` — blocks all skill loading. QA engineer cannot load `bug-triage`, `agent-browser`, or any other skill. | td-c0187e (F-10), td-616172 (S-06) | QA workflow skills permanently inaccessible | XS | SE |
| R-06 | P1 | All 6 agents missing `type:` frontmatter field required by `audit-agents.mjs --strict`. Script exits with code 1 (7 critical findings), blocking QA's mandatory agent-integrity audit gate. Root cause unclear: runtime uses `mode:`, script expects `type:`. | td-c0187e (F-19) | Audit gate always fails; CI/QA blocked | S | ARCH |
| R-07 | P1 | `team-lead.md` missing `model:` field — agent runs on primary mode default, non-deterministic across deployments. | td-c0187e (F-02) | Non-deterministic team-lead behavior | XS | SE |
| R-08 | P1 | `agent-team-workflow.md` references `validator` agent (does not exist) and `staff-engineer` as implementer (incorrect — `senior-engineer` implements). Agents following the playbook will delegate to wrong roles. | td-c0187e (F-05), td-972e8b (A-05/A-06), td-b35bad (D3-03/D3-04), td-94e7b9 | Wrong agent delegation | XS | SE |
| R-09 | P1 | `agent-tools-policy.md` lists 31 agents; only 6 exist. 25 phantom archetypes referenced. `qa-engineer` and `ux-designer` absent from policy entirely. Policy mandates 7 tool keys; all agents have 11–14. Policy actively misleads anyone adding or modifying agents. | td-c0187e (F-03/F-04), td-b35bad (D4-01/D4-02/D4-03) | Policy is a liability; misleads future implementers | M | SE |
| R-10 | P1 | `td.ts` `log` action ignores `task` parameter — always logs to focused task. Agents targeting specific tasks get logs on the wrong task. | td-7c3679 (F-02), td-b35bad (D5-05) | Structured logs misrouted | XS | SE |
| R-11 | P1 | `agent-team-workflow.md` uses direct `git merge` (3×) instead of PR-based flow. Contradicts `pr-quality-gate` and `git-workflow` skills. Bypasses all quality gates. | td-c0187e (F-12), td-972e8b (A-07/A-08), td-b35bad (D3-05) | Quality gate bypass | S | SE |
| R-12 | P1 | `git worktree add` in `plan.md` and `agent-team-workflow.md` omits `origin/main` base ref — agents branch from potentially stale local HEAD. | td-972e8b (A-13), td-b35bad (D5-03) | Stale branch base; divergence failures | XS | SE |
| R-13 | P1 | `git-worktree-flow/SKILL.md` uses `git pull origin main` without `--rebase` flag — creates merge commits on local main when it has diverged. | td-972e8b (A-01), td-b35bad (D5-02) | Non-linear history; merge commit pollution | XS | SE |
| R-14 | P1 | 5 of 11 skills (45%) are orphaned — not assigned to any agent: `acceptance-criteria-authoring`, `agent-browser`, `bug-triage`, `design-system`, `release-notes`. Skills are dead weight until assigned. | td-c0187e (F-18), td-616172 (S-04/S-05/S-06/S-07/S-08) | 45% of skill library inaccessible | XS | SE |
| R-15 | P1 | `product-manager` missing `acceptance-criteria-authoring` skill — PM's primary output is AC-backed TD tasks but has no skill guidance for AC format. | td-616172 (S-04) | Inconsistent AC authoring | XS | PM |
| R-16 | P1 | AGENTS.md Rules 2, 3, and 4 are prose-only with zero enforcement mechanism. Rule 2 (session-start usage), Rule 3 (sub-agent TD text), Rule 4 (handoff before context end) can all be silently skipped. | td-7c3679 (F-06/F-07), td-b35bad (D1-05) | Compliance depends entirely on LLM goodwill | M | ARCH |
| R-17 | P1 | All handoff points in the orchestration flow are implicit (subagent return value only). No explicit handoff contract, no structured handoff artifact, no handoff verification. | td-94e7b9 (H-02) | Handoff integrity unverifiable | M | TL |
| R-18 | P1 | Bug feedback loop (qa→pm→senior) is documented in `qa-engineer.md` but not wired in `build.md` or `team-lead.md`. Team-lead must manually route bug reports. | td-94e7b9 (H-03) | Bug reports may be dropped | S | TL |
| R-19 | P1 | Phase gates (planning→implementation→validation→review) are prose-only. TD tool does not block implementation before planning, or validation before implementation. | td-94e7b9 (H-04) | Phases can be skipped without enforcement | L | ARCH |
| R-20 | P1 | Review session constraint not enforced — TD tool allows `approve`/`reject` from the same session that implemented the work. Self-review is technically possible. | td-94e7b9 (H-05), td-1cc703 (P3 finding) | Self-review risk | M | ARCH |

---

### 1.3 P2 — Medium Impact, Fix in Next Sprint

| ID | Severity | Finding | Source Audits | Impact | Effort | Owner |
|----|----------|---------|--------------|--------|--------|-------|
| R-21 | P2 | `git-workflow` and `git-worktree-flow` skills have incompatible branch naming: `feature/<slug>` vs `feature/td-<id>-<slug>`. `senior-engineer` has both skills and receives contradictory guidance. | td-972e8b (A-10), td-616172 (S-09) | Inconsistent branch naming across team | XS | SE |
| R-22 | P2 | `pr-quality-gate` and `git-workflow` have overlapping but non-identical merge-readiness criteria. Neither references the other. An agent using only `git-workflow` produces PRs that fail `pr-quality-gate`. | td-616172 (S-10) | PRs may fail quality gate silently | S | SE |
| R-23 | P2 | `staff-engineer.md` has dead bash config: `bash: false` in tools block but `permission.bash` has 13 entries (never evaluated). Annotated as "forward-compatible placeholders" but misleads readers. | td-2b04e5, td-c0187e (F-09) | Misleading dead config | XS | SE |
| R-24 | P2 | `staff-engineer` missing `pr-quality-gate` skill — reviewer uses this checklist but skill is not assigned. | td-c0187e (F-15), td-616172 (S-13) | Reviewer lacks structured quality gate guidance | XS | SE-staff |
| R-25 | P2 | `ux-designer` missing `design-system` skill — UX designer must follow design system standards but has no skill guidance. | td-c0187e (F-17), td-616172 (S-07/S-12) | Design token violations likely | XS | UX |
| R-26 | P2 | `frontend-design` skill missing `compatibility` and `metadata` frontmatter keys; non-standard `license` value references a `LICENSE.txt` that does not exist in the skill directory. | td-616172 (S-01/S-02/S-03/S-15) | Skill structurally inconsistent; license terms undocumented | XS | SE |
| R-27 | P2 | `design-system` and `frontend-design` skills have a design token gap: `design-system` mandates semantic tokens; `frontend-design` says "use CSS variables" without referencing the token vocabulary. | td-616172 (S-12) | Ad-hoc CSS variables violate token standard | S | UX |
| R-28 | P2 | `tdd-authoring` skill references "acceptance criteria" in its template but does not specify AC format. `acceptance-criteria-authoring` defines the format but is not referenced. | td-616172 (S-11) | Inconsistent AC format in TDDs | XS | SE-staff |
| R-29 | P2 | `td-enforcer.ts` `permission.ask` hook and `tool.execute.before` hook use different blocking mechanisms on null TD status (ask-prompt vs hard throw). UX inconsistency when TD CLI is unavailable. | td-7c3679 (F-03/F-04) | Confusing UX on CLI failure | S | SE |
| R-30 | P2 | `td-enforcer.ts` `TRACKED_EXTENSIONS` missing: `.lock`, `.xml`, `.tf`, `.hcl` — these file types are not auto-tracked when written. | td-7c3679 (F-11) | File links missed for infra/config files | XS | SE |
| R-31 | P2 | `td.ts` `update` action missing params: `acceptance`, `dependsOn`, `blocks`, `points`, `parent` — valid CLI flags silently dropped. | td-7c3679 (minor gap), td-616172 | Update action incomplete | S | SE |
| R-32 | P2 | Worktree path format inconsistency: `agent-team-workflow.md` uses `~/Development/.worktrees/feature-td-abc123-jwt-service`; `plan.md` uses `~/Development/.worktrees/td-xxx`; `team-lead.md` uses `~/Development/.worktrees/<name>`. Three different conventions. | td-c0187e (F-13), td-972e8b (A-09), td-b35bad (D3-06) | Agent confusion on worktree path creation | XS | SE |
| R-33 | P2 | `opencode.json` global `bash["*"]: allow` is the most permissive possible default. All 6 agents override it, but any new agent added without a bash permission block would inherit unrestricted bash access. | td-c0187e (F-14) | Latent security gap for future agents | XS | ARCH |
| R-34 | P2 | `agent-team-workflow.md` `td unblock` uses positional reason arg; CLI uses `--reason` flag. | td-7c3679 (F-14) | Wrong CLI syntax in playbook | XS | SE |
| R-35 | P2 | `td-workflow` skill prescribes `review` before `handoff` (step 5 then 6); `git-worktree-flow` guardrails imply handoff before review. Minor ordering ambiguity. | td-616172 (S-18) | Ordering confusion before worktree deletion | XS | SE |
| R-36 | P2 | `team-lead → product-manager` delegation has no explicit input contract. Product-manager must infer planning scope from TD task context. | td-94e7b9 (H-06) | Planning scope ambiguity | S | TL |
| R-37 | P2 | `product-manager → senior-engineer` handoff is one-way. No acknowledgment that senior-engineer received the execution map. | td-94e7b9 (H-07) | Execution map may be ignored | S | SE |
| R-38 | P2 | `senior-engineer → qa-engineer` handoff has no structured artifact. QA must infer what to validate from TD task context. | td-94e7b9 (H-08) | Validation scope ambiguity | S | SE |
| R-39 | P2 | Security plugin does not block `chmod 777*` (opencode.json denies it but plugin doesn't log it). Security plugin does not log infrastructure commands (kubectl, terraform, nixos-rebuild). | td-1cc703 (P1 findings) | Security audit gaps | S | SE |
| R-40 | P2 | `AGENTS_INDEX.md` plugin count claim of "6" is ambiguous — directory has 6 `.ts` files + 1 `README.md` = 7 entries. | td-b35bad (D2-01) | Minor count confusion | XS | SE |
| R-41 | P2 | `AGENTS.md` Rule 1 enforcement is partial: `td-enforcer.ts` blocks MCP write tools only. Shell-level writes via Bash tool bypass enforcement entirely. | td-7c3679 (F-06), td-b35bad (D1-04) | Bash writes unprotected | M | ARCH |
| R-42 | P2 | `pr-quality-gate` skill is very thin (41 lines) — no example of what acceptable evidence looks like. "Validator output with criteria-to-evidence mapping" is vague without a template. | td-616172 (S-17) | Quality gate guidance insufficient | S | SE-staff |
| R-43 | P2 | `release-notes` skill is very thin (45 lines) — no example release note with populated sections. | td-616172 (S-14) | Release note quality inconsistent | S | PM |
| R-44 | P2 | `td.ts` `ws` action: `else` branch catches `handoff` but also any unrecognized `wsAction` value — fragile fallthrough. | td-7c3679 (F-20) | Silent wrong behavior on unknown wsAction | XS | SE |
| R-45 | P2 | `td.ts` `handoff` action: if no `task` param and no focused task, CLI may error cryptically. No pre-validation. | td-7c3679 (F-09) | Cryptic error on unfocused handoff | XS | SE |

---

### 1.4 P3 — Low Impact, Fix When Convenient

| ID | Severity | Finding | Source Audits | Impact | Effort | Owner |
|----|----------|---------|--------------|--------|--------|-------|
| R-46 | P3 | All 6 agents use `~` tilde shorthand in `external_directory` — tilde expansion support in OpenCode is unverified. If unsupported, worktree access silently fails. | td-2b04e5, td-c0187e (F-16) | Potential silent worktree access failure | S | ARCH |
| R-47 | P3 | `AGENTS_INDEX.md` `Last updated: 2026-03-03` — stale by 3 days at audit time; not updated when new audit reports were added. | td-b35bad (D2-03) | Stale index date | XS | SE |
| R-48 | P3 | `AGENTS_INDEX.md` not referenced from `AGENTS.md` — effectively undiscoverable from the primary entry point. | td-b35bad (D2-02) | Index undiscoverable | XS | SE |
| R-49 | P3 | `td-enforcer.ts` `EXCLUDED_DIR_SEGMENTS` mixes single-segment and multi-segment entries without comment — non-obvious to future maintainers. | td-7c3679 (F-12) | Maintainability risk | XS | SE |
| R-50 | P3 | `specs/tdd/td-9da879-icm-llm-driven-tools.md` status field still shows `draft` — Phase 1 (td-e2af34) is confirmed closed; Phase 2 is ready to proceed. | td-b35bad (D6-02) | TDD status misleading | XS | SE |
| R-51 | P3 | `agent-browser` skill missing from all agents despite `agent-browser: true` in tools blocks. No skill guidance for browser automation patterns. | td-616172 (S-05) | Browser automation undocumented | XS | SE |
| R-52 | P3 | `td.ts` `log` action: `orchestration` log type (valid per CLI) not exposed in `logType` enum. | td-7c3679 (F-10) | Minor enum incompleteness | XS | SE |

---

### 1.5 Risk Register Summary

| Severity | Count | Cumulative |
|----------|-------|-----------|
| P0 | 4 | 4 |
| P1 | 16 | 20 |
| P2 | 25 | 45 |
| P3 | 7 | 52 |
| **Total** | **52** | |

**Zero prior fixes applied:** As of the td-b35bad audit (2026-03-05), 0 of 10 sampled recommendations from three prior audit cycles had been applied to source files. The remediation backlog is growing without remediation. This is the most significant process risk in the system.

---

## 2. Critical Path Analysis — Top 5 Blockers

The following 5 findings must be resolved first because they either (a) block the most other remediation work, (b) block the delivery pipeline entirely, or (c) prevent the audit/validation toolchain from functioning.

---

### CP-1: R-01 — QA Engineer Invalid Model (P0)

**Blocks:** Every delivery pipeline execution. The QA engineer is the validation phase agent. If it fails to load, no task can complete the validation phase. This also blocks QA from running the audit script, verifying fixes, or approving any work.

**Also unblocks:** R-05 (skill fix becomes meaningful only when agent loads), R-14 (bug-triage skill assignment only useful when QA can load skills).

**Fix:** Change `qa-engineer.md` line 4 from `model: openai/gpt-5.2` to `model: anthropic/claude-sonnet-4-6`.

**Effort:** XS (2 min). **Owner:** SE.

---

### CP-2: R-04 — Sub-Agent TD Inheritance Broken (P0)

**Blocks:** All sub-agent sessions. When team-lead spawns any sub-agent (product-manager, senior-engineer, qa-engineer, staff-engineer), the sub-agent operates without TD enforcement. This means:
- Writes are unblocked (td-enforcer not active)
- Handoffs may be skipped
- File links are not recorded
- The entire TD audit trail is unreliable for sub-agent work

**Also unblocks:** R-16 (enforcement gap partially addressed), R-17 (handoff integrity improves), R-18 (bug loop routing improves when team-lead delegation is explicit).

**Fix:** Add explicit TD requirement text to `team-lead.md` delegation prompts for all 4 sub-agents.

**Effort:** M (1–2 hrs). **Owner:** TL.

---

### CP-3: R-03 — Broken Playbook Commands (P0)

**Blocks:** Any agent following `agent-team-workflow.md`. The 8 broken TD command references (`td done`, `td block`, `td unblock`) will cause agent failures at 8 execution points in the standard delivery workflow. This is the primary operational document for the team.

**Also unblocks:** R-08 (agent role references), R-11 (git merge bypass), R-32 (path format) — all in the same file, can be fixed in one pass.

**Fix:** Replace all broken TD commands with valid alternatives; fix agent role references; replace direct `git merge` with PR-based flow.

**Effort:** S (45 min for all related fixes in one pass). **Owner:** SE.

---

### CP-4: R-06 — Audit Script `type:` Field Mismatch (P1)

**Blocks:** The `audit-agents.mjs --strict` gate. The script exits with code 1 (7 critical findings) because all 6 agents use `mode:` but the script expects `type:`. This blocks:
- QA's mandatory agent-integrity audit gate
- Any CI pipeline that runs the audit script
- Confidence in the audit toolchain

**Root cause ambiguity:** Either the script has a bug (should check `mode:` not `type:`), or all 6 agents need a `type:` field added. This must be resolved before the audit script can be trusted.

**Fix:** Determine canonical field name. If `mode:` is correct (runtime field), update script's `required` array. If `type:` is also required, add it to all 6 agents.

**Effort:** S (15–30 min). **Owner:** ARCH → SE.

---

### CP-5: R-09 — Agent Tools Policy Is a Liability (P1)

**Blocks:** Any future agent addition or modification. `agent-tools-policy.md` is so stale (31 phantom agents, wrong tool key count, stale migration table) that it actively misleads anyone trying to add or modify agents. Until this is rewritten, the policy document is a source of incorrect guidance.

**Also unblocks:** R-23 (dead config annotation), R-24 (skill assignments), R-25 (skill assignments) — all become easier to reason about once the policy reflects reality.

**Fix:** Rewrite `agent-tools-policy.md` to reflect the 6-agent reality with the 14-key schema. Remove phantom archetypes, update migration table, add `qa-engineer` and `ux-designer`.

**Effort:** M (2 hrs). **Owner:** SE.

---

### Critical Path Summary

```
CP-1 (R-01: QA model fix)
  └─ Unblocks: QA agent loads → CP-4 can be validated by QA
  
CP-2 (R-04: Sub-agent TD inheritance)
  └─ Unblocks: TD audit trail reliability → R-16, R-17, R-18

CP-3 (R-03: Broken playbook commands)
  └─ Unblocks: Operational workflow → R-08, R-11, R-32 (same file)

CP-4 (R-06: Audit script type: field)
  └─ Unblocks: Audit gate → CI/QA validation toolchain
  └─ Depends on: CP-1 (QA must load to run audit)

CP-5 (R-09: Policy rewrite)
  └─ Unblocks: Future agent work → R-23, R-24, R-25
```

**Recommended execution order:** CP-1 → CP-3 → CP-4 → CP-2 → CP-5

Rationale: CP-1 is a 2-minute fix that immediately unblocks QA. CP-3 fixes the operational playbook in one pass. CP-4 restores the audit toolchain. CP-2 requires team-lead prose changes that benefit from CP-3 being done first (playbook is the reference). CP-5 is a larger rewrite that can proceed in parallel with CP-2.

---

## 3. Remediation Epic Proposal

### Epic: `REMEDIATION-001` — Workflow Audit Remediation

**Description:** Implement all P0 and P1 fixes identified in the td-25bf87 audit cycle. Restore the delivery pipeline to a fully operational state, fix the audit toolchain, and eliminate the most impactful documentation drift.

**Estimated total effort:** ~12–16 hours across all child tasks.

**Acceptance criteria (epic-level):**
1. `audit-agents.mjs --strict` exits with code 0 (no findings).
2. `qa-engineer.md` loads successfully with a valid model.
3. `agent-team-workflow.md` contains no references to non-existent TD commands or agents.
4. All 11 skills are assigned to at least one agent.
5. `team-lead.md` includes explicit TD requirement text in all sub-agent delegation prompts.
6. `td.ts` `files` action correctly links files when `files` array is provided.

---

### Child Tasks

| Task ID (proposed) | Title | Severity | Points | Effort | Depends On | AC Summary |
|-------------------|-------|----------|--------|--------|-----------|------------|
| REMED-01 | Fix qa-engineer model and enable skills | P0 | 1 | XS | — | `model: anthropic/claude-sonnet-4-6`; `skill: true`; `bug-triage` and `agent-browser` assigned |
| REMED-02 | Fix agent-team-workflow.md broken commands and references | P0 | 2 | S | — | All `td done`/`td block`/`td unblock` replaced; `validator` → `qa-engineer`; `staff-engineer` → `senior-engineer`; direct `git merge` → PR flow |
| REMED-03 | Fix td.ts files action and log task targeting | P0/P1 | 2 | S | — | `files` action calls `td link` when `files` array provided; `log` action inserts `task` ID before message |
| REMED-04 | Fix team-lead sub-agent TD inheritance | P0 | 3 | M | REMED-02 | All 4 delegation prompts include explicit TD requirement text per AGENTS.md Rule 3 |
| REMED-05 | Resolve audit script type:/mode: field mismatch | P1 | 1 | S | REMED-01 | `audit-agents.mjs --strict` exits code 0; determination documented in decision log |
| REMED-06 | Assign all 5 orphaned skills to appropriate agents | P1 | 1 | XS | REMED-01 | `acceptance-criteria-authoring` → PM; `bug-triage` → QA; `design-system` → UX; `agent-browser` → SE+QA; `release-notes` → TL |
| REMED-07 | Fix team-lead missing model field | P1 | 1 | XS | — | `model: anthropic/claude-sonnet-4-6` added to team-lead frontmatter |
| REMED-08 | Fix git-worktree-flow --rebase and origin/main base ref | P1 | 1 | XS | — | `git pull --rebase origin main` in SKILL.md; `origin/main` base ref in plan.md and workflow doc |
| REMED-09 | Rewrite agent-tools-policy.md for 6-agent reality | P1 | 3 | M | REMED-06 | Policy reflects 6 actual agents; 14-key schema documented; phantom archetypes removed; migration table updated |
| REMED-10 | Wire bug feedback loop in build.md and team-lead.md | P1 | 2 | S | REMED-04 | Explicit bug routing steps in build.md; team-lead routes QA bug reports to PM; PM routes fixes to SE |
| REMED-11 | Align git-workflow branch naming to include TD ID | P2 | 1 | XS | — | `git-workflow` branch patterns updated to `feature/td-<id>-<slug>`; cross-reference to `git-worktree-flow` added |
| REMED-12 | Cross-reference pr-quality-gate and git-workflow skills | P2 | 1 | S | — | `git-workflow` PR description fields include AC validation evidence requirement; skills reference each other |
| REMED-13 | Fix frontend-design skill frontmatter and license | P2 | 1 | XS | — | `compatibility: opencode`; `metadata:` block added; `license: MIT` or `LICENSE.txt` created |
| REMED-14 | Add staff-engineer pr-quality-gate skill | P2 | 1 | XS | REMED-09 | `pr-quality-gate` in staff-engineer skills list |
| REMED-15 | Define explicit handoff contracts for all agent transitions | P1 | 3 | M | REMED-04 | Handoff artifact schema defined; each agent produces structured handoff before delegation |

---

### Dependency Graph

```
REMED-01 (QA model + skills)
  ├─ REMED-05 (audit script fix — needs QA to validate)
  └─ REMED-06 (orphaned skills — needs skill: true)
      └─ REMED-09 (policy rewrite — needs skill assignments settled)
          └─ REMED-14 (staff-engineer skill)

REMED-02 (playbook commands)
  └─ REMED-04 (sub-agent TD inheritance — playbook is reference)
      └─ REMED-10 (bug loop wiring — needs delegation fixed)
          └─ REMED-15 (handoff contracts — needs delegation model clear)

REMED-03 (td.ts fixes) — independent
REMED-07 (team-lead model) — independent
REMED-08 (git rebase/base ref) — independent
REMED-11 (branch naming) — independent
REMED-12 (pr-quality-gate cross-ref) — independent
REMED-13 (frontend-design frontmatter) — independent
```

---

### Execution Recommendation

**Sprint 1 (P0 fixes, ~4 hrs):** REMED-01, REMED-02, REMED-03, REMED-07, REMED-08 — all independent or fast-follow. Restores pipeline operability.

**Sprint 2 (P1 structural fixes, ~6 hrs):** REMED-04, REMED-05, REMED-06, REMED-09, REMED-10 — requires Sprint 1 to be complete.

**Sprint 3 (P2 quality improvements, ~4 hrs):** REMED-11 through REMED-15 — can proceed in parallel with Sprint 2 for independent items.

---

## 4. Architecture Assessment

### Verdict: **needs-minor-fixes**

---

### Evidence Summary

The audit cycle covered 7 distinct workflow domains across ~6,000 lines of configuration, documentation, and code. The findings break down as follows by domain:

| Domain | Audit | Verdict | Rationale |
|--------|-------|---------|-----------|
| Agent definitions | td-c0187e | needs-minor-fixes | Core permission model sound; issues are model ID, stale policy doc, orphaned skills |
| TD tool implementation | td-7c3679 | needs-minor-fixes | 29/31 actions correct; 2 P0 bugs isolated and fixable |
| Git worktree flow | td-972e8b | needs-minor-fixes | Architecture sound; issues concentrated in playbook doc |
| Skills library | td-616172 | needs-structural-changes* | 45% orphaned; branch naming conflict; enforcement gap |
| Cross-agent handoffs | td-94e7b9 | needs-minor-fixes | Flow structurally sound; enforcement-weak |
| Documentation | td-b35bad | needs-structural-changes* | Zero prior fixes applied; policy severely stale |
| Plugins ecosystem | td-1cc703 | needs-minor-fixes | Functionally sound; 2 P1 security logging gaps |

*The two "needs-structural-changes" verdicts (skills library, documentation) reflect **documentation debt and configuration gaps**, not architectural flaws. The skills library verdict is driven by 45% orphaned skills — a configuration problem solvable in ~35 minutes of frontmatter edits. The documentation verdict is driven by zero prior fixes applied — a process problem, not an architecture problem.

---

### What Is Sound

1. **Permission model:** All 6 agents correctly override the global `bash["*"]: allow` with more restrictive per-agent policies. The least-privilege principle is applied correctly at the agent level.

2. **TD-enforcer plugin:** Architecturally correct fail-safe design. Both `permission.ask` and `tool.execute.before` hooks block writes when TD status is null (CLI failure, DB error). The review notification logic is sound. The same-session check correctly prevents self-review notifications.

3. **Plugin ecosystem:** No critical conflicts between plugins. Load order is correct (security first, icm last). ICM Phase 2 implementation matches TDD with all 12 acceptance criteria satisfied.

4. **Git worktree model:** The `git-worktree-flow` skill is well-structured and contains all required safety patches from td-14de4a (pull-before-branch, force-with-lease, prune, rebase gate). The worktree isolation model is the correct approach for this workflow.

5. **TD tool coverage:** 29 of 31 actions are correctly implemented. The tool correctly wraps the CLI for the vast majority of operations. Error handling (stderr fallback) is consistent across all actions.

6. **Agent role separation:** The 6-agent team structure (team-lead, product-manager, staff-engineer, senior-engineer, qa-engineer, ux-designer) correctly separates orchestration, planning, implementation, review, validation, and design concerns.

---

### What Needs Fixing

The 4 P0 findings are the most urgent:
- R-01: QA model is invalid (runtime failure)
- R-02: `files` action silently misbehaves (data loss)
- R-03: Playbook has 8 broken commands (workflow failures)
- R-04: Sub-agent TD inheritance is broken (enforcement gap)

These are **isolated bugs and documentation errors**, not architectural flaws. None require structural changes to the agent/skill/plugin architecture.

The 16 P1 findings are significant but all addressable within the existing architecture. The most impactful are the orphaned skills (R-14), the prose-only enforcement rules (R-16), and the implicit handoff contracts (R-17). These require configuration changes and prose additions, not architectural redesign.

---

### Why Not "needs-structural-changes"

A "needs-structural-changes" verdict would be warranted if:
- The permission model was fundamentally broken (it is not — it is correctly applied)
- The plugin system had unresolvable conflicts (it does not — 2 minor overlaps, no functional conflicts)
- The agent role structure was wrong (it is not — roles are correctly separated)
- The TD integration was architecturally unsound (it is not — 29/31 actions correct)

The two audits that returned "needs-structural-changes" verdicts (td-616172, td-b35bad) were responding to the *scale* of documentation debt and the *rate* of fix application (zero). These are process and maintenance failures, not architectural failures. The underlying architecture they were auditing is sound.

**Final verdict: needs-minor-fixes** — with a high-priority remediation backlog of 4 P0 and 16 P1 findings that must be addressed before the next delivery cycle.

---

## 5. Sidecar Workspace Recommendation

### Recommendation: **Preserve git worktrees. Do not migrate to a sidecar model.**

---

### Evidence from td-972e8b

The sidecar workspace investigation (td-972e8b) conducted a comprehensive comparison across 8 dimensions:

| Dimension | Git Worktrees | Sidecar (hypothetical) | Winner |
|-----------|--------------|----------------------|--------|
| Task isolation (filesystem) | Each branch = isolated FS via `git worktree add` | Requires Docker/container or separate directory + manual setup | **Git Worktrees** |
| Setup complexity per task | 1 command | Multiple steps: container build/start, directory init, OpenCode launch | **Git Worktrees** |
| TD integration | TD CLI works natively in any worktree directory | TD CLI would need per-container install/config | **Git Worktrees** |
| Parallel execution | Multiple worktrees simultaneously, each with own OpenCode session | Possible with containers but requires orchestration layer | **Git Worktrees** |
| Cleanup | 3 commands (`worktree remove`, `branch -d`, `worktree prune`) | Container teardown + volume cleanup + branch delete | **Git Worktrees** |
| Agent compatibility | All agents work in any directory; `external_directory` covers `~/Development/**` | Requires permission updates per container path | **Git Worktrees** |
| Context switching overhead | Low — directory change only | High — new container/process start | **Git Worktrees** |
| Cross-task pollution risk | Low — separate branches prevent file conflicts | Low (if containerized) but adds operational complexity | **Git Worktrees** |

**Score: Git Worktrees 8/8 dimensions.**

---

### OpenCode Platform Constraint

OpenCode has **no native sidecar workspace concept**. The platform's isolation model operates at the session/agent level, not the filesystem level. The terms "sidecar", "workspace isolation", "container", and "isolated workspace" do not appear in OpenCode documentation. Implementing a sidecar model would require:

1. Selecting and implementing a container/isolation technology (Docker, nix-shell, devcontainers)
2. Rewriting 7+ files of agent/skill/command configuration
3. Building an orchestration layer OpenCode does not provide
4. Updating TD CLI integration for container-aware operation
5. Testing parallel execution across container boundaries

This is a multi-week infrastructure project with no isolation benefit over the current git worktree approach.

---

### Repo Evidence Check

The repository shows no evidence contradicting the worktree recommendation:
- `opencode.json` `external_directory` already covers `~/Development/**` — worktree paths are pre-authorized
- All 6 agents have `~/Development/.worktrees/**` in their `external_directory` permissions
- The `git-worktree-flow` skill is well-maintained and contains all required safety patches
- Active worktrees exist for multiple tasks (confirmed via `git worktree list`)
- No container configuration files (Dockerfile, devcontainer.json, docker-compose.yml) exist in the repository

---

### Worktree Path Standardization (Action Item)

While preserving git worktrees, the path naming convention should be standardized. Three formats currently exist:

| Format | Source | Recommendation |
|--------|--------|---------------|
| `~/Development/.worktrees/feature-td-abc123-jwt-service` | `agent-team-workflow.md` | **Adopt as canonical** — mirrors branch name, includes type+ID+slug |
| `~/Development/.worktrees/td-xxx` | `plan.md`, `product-manager.md` | Update to canonical format |
| `~/Development/.worktrees/<name>` | `team-lead.md`, `git-worktree-flow` | Update placeholder to show canonical pattern |

**Canonical format:** `~/Development/.worktrees/<type>-td-<id>-<slug>`

Examples:
- `~/Development/.worktrees/feature-td-abc123-jwt-service`
- `~/Development/.worktrees/bugfix-td-def456-login-error`
- `~/Development/.worktrees/chore-td-ghi789-update-deps`

This format mirrors the branch name (with `/` → `-`), includes the task ID for `td focus` lookup, and includes the type prefix for visual differentiation.

**Note on actual worktree location:** The live repository uses `~/Development/MoshPitLabs/worktrees/td-<id>` (task-ID-only format, no type prefix, under `MoshPitLabs/` not `.worktrees/`). The canonical format recommendation above applies to the documented convention in skills/commands/agents. The actual path used in practice should be confirmed and standardized in a separate task.

---

## Appendix A: Source Audit Cross-Reference

| Audit Task | Title | Date | Findings | Verdict |
|-----------|-------|------|----------|---------|
| td-2b04e5 | Agent permission blocks audit | 2026-03-01 | 9 (P1:1, P2:5, P3:3) | needs-minor-fixes |
| td-3a95d3 | Git skills audit | 2026-03-01 | 7 (P1:4, P2:1, P3:2) | needs-minor-fixes |
| td-99cb98 | Final validation (Phase 1 fixes) | 2026-03-01 | 0 (all AC pass) | PASS |
| td-c0187e | Agent definitions audit | 2026-03-05 | 19 (P0:1, P1:6, P2:8, P3:4) | needs-minor-fixes |
| td-7c3679 | TD tool & enforcer audit | 2026-03-05 | 20 (P0:2, P1:4, P2:9, P3:5) | needs-minor-fixes |
| td-972e8b | Git worktree & sidecar analysis | 2026-03-05 | 13 (P0:3, P1:4, P2:4, P3:2) | needs-minor-fixes |
| td-616172 | Skills audit (all 11) | 2026-03-05 | 19 (P1:8, P2:7, P3:4) | needs-structural-changes* |
| td-94e7b9 | Cross-agent handoff integrity | 2026-03-06 | 10 (P0:1, P1:4, P2:3, P3:2) | needs-minor-fixes |
| td-b35bad | Documentation consistency | 2026-03-05 | 26 (P0:4, P1:11, P2:7, P3:4) | needs-structural-changes* |
| td-1cc703 | Plugins ecosystem | 2026-03-06 | 9 (P1:2, P2:4, P3:3) | needs-minor-fixes |

*Structural verdict reflects documentation debt and configuration gaps, not architectural flaws. See Section 4.

---

## Appendix B: Finding-to-Source Mapping

| Register ID | Source Finding IDs |
|------------|-------------------|
| R-01 | td-c0187e F-01, td-b35bad D5-01, td-2b04e5 (original) |
| R-02 | td-7c3679 F-01, td-b35bad D5-04 |
| R-03 | td-c0187e F-06, td-972e8b A-02/A-03/A-04, td-7c3679 F-13, td-b35bad D3-01/D3-02 |
| R-04 | td-94e7b9 H-01 |
| R-05 | td-c0187e F-10, td-616172 S-06 |
| R-06 | td-c0187e F-19 |
| R-07 | td-c0187e F-02 |
| R-08 | td-c0187e F-05, td-972e8b A-05/A-06, td-b35bad D3-03/D3-04 |
| R-09 | td-c0187e F-03/F-04, td-b35bad D4-01/D4-02/D4-03 |
| R-10 | td-7c3679 F-02, td-b35bad D5-05 |
| R-11 | td-c0187e F-12, td-972e8b A-07/A-08, td-b35bad D3-05 |
| R-12 | td-972e8b A-13, td-b35bad D5-03 |
| R-13 | td-972e8b A-01, td-b35bad D5-02 |
| R-14 | td-c0187e F-18, td-616172 S-04/S-05/S-06/S-07/S-08 |
| R-15 | td-616172 S-04 |
| R-16 | td-7c3679 F-06/F-07, td-b35bad D1-05 |
| R-17 | td-94e7b9 H-02 |
| R-18 | td-94e7b9 H-03 |
| R-19 | td-94e7b9 H-04 |
| R-20 | td-94e7b9 H-05, td-1cc703 |
| R-21 | td-972e8b A-10, td-616172 S-09 |
| R-22 | td-616172 S-10 |
| R-23 | td-2b04e5, td-c0187e F-09 |
| R-24 | td-c0187e F-15, td-616172 S-13 |
| R-25 | td-c0187e F-17, td-616172 S-07/S-12 |
| R-26 | td-616172 S-01/S-02/S-03/S-15 |
| R-27 | td-616172 S-12 |
| R-28 | td-616172 S-11 |
| R-29 | td-7c3679 F-03/F-04 |
| R-30 | td-7c3679 F-11 |
| R-31 | td-7c3679 minor gap |
| R-32 | td-c0187e F-13, td-972e8b A-09, td-b35bad D3-06 |
| R-33 | td-c0187e F-14 |
| R-34 | td-7c3679 F-14 |
| R-35 | td-616172 S-18 |
| R-36 | td-94e7b9 H-06 |
| R-37 | td-94e7b9 H-07 |
| R-38 | td-94e7b9 H-08 |
| R-39 | td-1cc703 P1 findings |
| R-40 | td-b35bad D2-01 |
| R-41 | td-7c3679 F-06, td-b35bad D1-04 |
| R-42 | td-616172 S-17 |
| R-43 | td-616172 S-14 |
| R-44 | td-7c3679 F-20 |
| R-45 | td-7c3679 F-09 |
| R-46 | td-2b04e5, td-c0187e F-16 |
| R-47 | td-b35bad D2-03 |
| R-48 | td-b35bad D2-02 |
| R-49 | td-7c3679 F-12 |
| R-50 | td-b35bad D6-02 |
| R-51 | td-616172 S-05 |
| R-52 | td-7c3679 F-10 |

---

*Report generated by senior-engineer (ses_732b15) for task td-62d464.*  
*Synthesizes findings from 10 audit reports covering ~6,000 lines of configuration, documentation, and code.*
