# Agent Definitions Audit Report

**Task:** td-c0187e  
**Date:** 2026-03-05  
**Auditor:** senior-engineer (ses_508af8)

---

## Executive Summary

All 6 agent definitions, the TD-enforcer plugin, both policy/workflow docs, `opencode.json`, `AGENTS.md`, and `AGENTS_INDEX.md` were read in full (2,346 lines across 12 files). The audit script (`audit-agents.mjs --strict`) was also executed and returned 9 findings (7 critical, 1 high, 1 low). The architecture is **functionally operational but carries critical structural gaps and significant documentation drift**. The most severe issue is that all 6 agents are missing the `type:` frontmatter field required by the audit script — the script flags this as 6 critical findings. Additionally, `qa-engineer.md` uses `openai/gpt-5.2`, a model ID not in the known-good allowlist (script: `unknown_model`, severity high); the prior audit changed it from `openai/gpt-5.3-codex` (which IS in the allowlist) to `gpt-5.2` (which is not), making the situation worse. The policy document (`agent-tools-policy.md`) is severely stale: it mandates exactly 7 tool keys but all 6 deployed agents have 11–14 keys, and it references 31 agent archetypes of which only 6 exist. Total findings: **1 P0, 6 P1, 8 P2, 4 P3**.

---

## Audit Scope

| File | Lines | Notes |
|------|-------|-------|
| `.opencode/agents/team-lead.md` | 116 | Primary mode agent |
| `.opencode/agents/staff-engineer.md` | 97 | Subagent |
| `.opencode/agents/senior-engineer.md` | 127 | Subagent |
| `.opencode/agents/product-manager.md` | 100 | Subagent |
| `.opencode/agents/qa-engineer.md` | 116 | Subagent |
| `.opencode/agents/ux-designer.md` | 80 | Subagent |
| `.opencode/plugins/td-enforcer.ts` | 524 | TD enforcement plugin |
| `.opencode/docs/agent-tools-policy.md` | 318 | Policy document |
| `.opencode/docs/agent-team-workflow.md` | 605 | Workflow playbook |
| `opencode.json` | 167 | Global config |
| `AGENTS.md` | 31 | Global rules |
| `.opencode/AGENTS_INDEX.md` | 65 | Component index |

**Total lines read:** 2,346

---

## Findings Table

| ID | Severity | Agent/File | Dimension | Finding | Recommended Fix |
|----|----------|------------|-----------|---------|-----------------|
| F-01 | **P0** | `qa-engineer.md` | Model Validity | `model: openai/gpt-5.2` — model ID is not in the known-good allowlist and has never been a valid OpenAI model identifier; likelihood of runtime failure is high. Audit script reports `unknown_model` (severity: high). The prior audit changed it from `openai/gpt-5.3-codex` (which IS in the allowlist) to `openai/gpt-5.2` (which is not), making the situation worse. | Replace with `anthropic/claude-sonnet-4-6` or `openai/gpt-4o` (both in allowlist) |
| F-02 | **P1** | `team-lead.md` | Model Validity | No `model:` field in frontmatter. Agent runs on primary mode default (inherits whatever model the user has configured). Behavior is non-deterministic across deployments. | Add `model: anthropic/claude-sonnet-4-6` |
| F-03 | **P1** | `agent-tools-policy.md` | Tool Declaration Completeness | Policy mandates exactly 7 tool keys (`edit`, `write`, `skill`, `td`, `webfetch`, `todowrite`, `bash`). All 6 deployed agents have 12–14 keys (`read`, `list`, `question`, `websearch`, `grep`, `todoread`, `agent-browser` added). Policy is stale and contradicts deployed reality. | Update policy to reflect actual 14-key schema, or document the delta explicitly |
| F-04 | **P1** | `agent-tools-policy.md` | 31-Agent Reference Drift | Policy's "Agent-to-Archetype Mapping" table lists 31 agents. Only 6 exist in `.opencode/agents/`. 25 phantom archetypes are referenced (e.g., `validator`, `backend-golang`, `frontend-react-typescript`, etc.). | Update mapping table to reflect the 6 actual agents; remove phantom entries |
| F-05 | **P1** | `agent-team-workflow.md` | Dead Config / Drift | Workflow doc references `validator` agent (line 10) — does not exist; `qa-engineer` is the actual validator. Also references `staff-engineer` as implementer (line 9) — `senior-engineer` is the implementer. | Replace `validator` with `qa-engineer`; replace `staff-engineer` (implementer role) with `senior-engineer` |
| F-06 | **P1** | `agent-team-workflow.md` | Dead Config / Drift | `td done <id>` command used in 4 places (lines 196, 331, 516, 517). This command does not exist in the TD CLI. The correct flow is `td review` → `td approve`. | Replace all `td done` references with `td review` + `td approve` workflow |
| F-07 | **P2** | `team-lead.md` | Permission Block vs Prose | `task` permission block allows `product-manager`, `staff-engineer`, `senior-engineer`, `qa-engineer`, `ux-designer` (5 agents). Policy template (agent-tools-policy.md line 72) shows `validator` instead of `qa-engineer` and `senior-engineer`. Policy template is stale. | Update policy template to match actual agent names |
| F-08 | **P2** | `team-lead.md` | Tool Declaration Completeness | Policy mandates 7 keys; team-lead has 14 keys (`bash`, `read`, `write`, `edit`, `list`, `skill`, `webfetch`, `websearch`, `grep`, `todoread`, `todowrite`, `question`, `agent-browser`, `td`). Policy says `write: false`, `edit: false`, `todowrite: true` for Orchestration archetype. Actual: `write: false`, `edit: false`, `todowrite: true` — matches archetype intent but has 7 extra undeclared keys. | Document the 7 extra keys in policy; verify `todoread: true` is intentional for orchestration |
| F-09 | **P2** | `staff-engineer.md` | Permission Block vs Prose | `bash: false` in tools block, but `permission.bash` block has 13 entries annotated as "forward-compatible placeholders." The annotation was added by prior audit (td-2b04e5) but the dead config remains. No functional impact, but misleading to readers. | Either remove the bash permission entries entirely, or add a comment block header explaining they are inactive |
| F-10 | **P2** | `qa-engineer.md` | Permission Block vs Prose | `skill: false` in tools block. Prose says "Follow global TD rules in AGENTS.md" and references skill-based validation workflows. No skills are assigned in frontmatter. QA engineer cannot load skills (e.g., `bug-triage`, `td-workflow`). | Set `skill: true` and assign `bug-triage` and `td-workflow` skills |
| F-11 | **P2** | `agent-tools-policy.md` | Tool Declaration Completeness | Policy "Migration Required" table (lines 280–295) lists agents that need tool key updates — including `staff-engineer` needing "entire tools block." The staff-engineer now has a complete tools block. Migration table is stale and will mislead future implementers. | Update or remove the Migration Required table to reflect current state |
| F-12 | **P2** | `agent-team-workflow.md` | Dead Config / Drift | Merge workflow (lines 186–196) uses direct `git merge` instead of PR-based flow. This contradicts the `pr-quality-gate` skill and the `senior-engineer` agent's own guardrail ("Do not attempt PR creation at agent level"). | Update merge section to reference PR-based flow via `gh pr create` (user-level) |
| F-13 | **P2** | `agent-team-workflow.md` | Dead Config / Drift | Worktree path convention in playbook uses `~/Development/.worktrees/feature-td-abc123-jwt-service` (full branch name as dir). `team-lead.md` uses `~/Development/.worktrees/<name>` and the task description uses `~/Development/.worktrees/td-xxx`. Three different conventions. | Standardize on `~/Development/.worktrees/td-<id>` (shortest, unambiguous) |
| F-14 | **P2** | `opencode.json` | opencode.json Cross-Reference | Global `permission.bash["*"]: allow` is set. All 6 agents override this with `"*": deny` or `"*": ask`. The global allow is effectively dead for all agents since every agent has its own bash permission block. However, any new agent added without a bash permission block would inherit unrestricted bash access. | Change global `bash["*"]` to `ask` as a safer default |
| F-15 | **P3** | `staff-engineer.md` | Skill Assignments | `staff-engineer` has skills `tdd-authoring` and `git-workflow`. Prose says it produces TDDs and reviews code. Missing `pr-quality-gate` skill — the review protocol (lines 76–90) describes a quality gate process but the skill is not assigned. | Add `pr-quality-gate` to staff-engineer skills |
| F-16 | **P3** | All 6 agents | Permission Block vs Prose | `external_directory` uses `~` tilde shorthand (e.g., `~/Development/.worktrees/**`). Tilde expansion support in OpenCode is unverified. If not supported, worktree access will silently fail. Carried forward from prior audit (td-2b04e5). | Verify tilde expansion; replace with absolute paths if unsupported |
| F-17 | **P3** | `ux-designer.md` | Skill Assignments | `ux-designer` has skills `td-workflow` and `frontend-design`. The `design-system` skill exists in `.opencode/skills/design-system/` and is directly relevant to UX design work, but is not assigned. | Add `design-system` to ux-designer skills |
| F-18 | **P3** | Multiple agents | Skill Assignments | Skills with directories but not assigned to any agent: `bug-triage` (not in qa-engineer), `acceptance-criteria-authoring` (not in product-manager), `release-notes` (not in any agent), `design-system` (not in ux-designer). | Assign orphaned skills to appropriate agents |
| F-19 | **P1** | All 6 agents | Tool Declaration Completeness | All 6 agents use `mode:` (values: `primary` or `subagent`) but the audit script requires a `type:` field (valid values: `primary`, `subagent`). The script flags this as 6 critical `missing_required_field: type` findings. The agents use `mode:` which appears to be the OpenCode runtime field name, while the audit script expects `type:`. This is either a schema mismatch between the script and the runtime, or all agents need a `type:` field added alongside `mode:`. | Determine canonical field name: if runtime uses `mode:`, update the audit script's `required` array; if `type:` is required, add it to all 6 agent frontmatter blocks |

---

## Dimension Analysis

### 1. Permission Block vs Prose Consistency

For each agent, the permission block (YAML frontmatter) was compared against prose documentation.

| Agent | Prose Permission Table? | Block vs Prose Status | Issues |
|-------|------------------------|----------------------|--------|
| `team-lead` | No explicit table | No inconsistency detectable | None (F-07 is policy doc drift, not agent-internal) |
| `staff-engineer` | No explicit table | No inconsistency | Dead bash config (F-09, P2) |
| `senior-engineer` | Yes — Git policy section (lines 91–101) | **FIXED** by td-2b04e5: PR lifecycle now `deny` ✅ | State-changing git ops (`git add`, `git commit`, etc.) are `allow` in block; prose says "standard git workflow commands are allowed" — this is now **consistent** (prose was updated to match block) |
| `product-manager` | No explicit table | No inconsistency | None |
| `qa-engineer` | No explicit table | No inconsistency | `skill: false` blocks skill loading (F-10) |
| `ux-designer` | TD usage section (lines 64–73) | Consistent — `status`, `context`, `comment`, `handoff` allowed; `create`, `start`, `focus`, `review`, `approve`, `reject` denied | None |

**Prior audit fix verification (td-2b04e5):**
- `senior-engineer.md` PR lifecycle: `gh pr create*: deny`, `gh pr merge*: deny`, `gh pr edit*: deny`, `hub pull-request*: deny`, `git push*merge_request*: deny` — **ALL FIXED** ✅
- `staff-engineer.md` dead bash config: annotated as "forward-compatible placeholders" — **ANNOTATED** (P3 addressed, dead config remains) ⚠️

---

### 2. Tool Declaration Completeness

**Policy mandates exactly 7 keys** (from `agent-tools-policy.md` lines 14–24):
1. `edit`
2. `write`
3. `skill`
4. `td`
5. `webfetch`
6. `todowrite`
7. `bash`

**Actual tool keys per agent (14 keys in use across the team; staff-engineer has 11):**

| Tool Key | team-lead | staff-engineer | senior-engineer | product-manager | qa-engineer | ux-designer | Policy Mandated? |
|----------|-----------|----------------|-----------------|-----------------|-------------|-------------|-----------------|
| `bash` | ✅ true | ✅ false | ✅ true | ✅ true | ✅ true | ✅ true | ✅ Yes |
| `read` | ✅ true | ✅ true | ✅ true | ✅ true | ✅ true | ✅ true | ❌ No (extra) |
| `write` | ✅ false | ✅ true | ✅ true | ✅ false | ✅ false | ✅ true | ✅ Yes |
| `edit` | ✅ false | ✅ false | ✅ true | ✅ false | ✅ false | ✅ false | ✅ Yes |
| `list` | ✅ true | ✅ true | ✅ true | ✅ true | ✅ true | ✅ true | ❌ No (extra) |
| `skill` | ✅ true | ✅ true | ✅ true | ✅ true | ✅ **false** | ✅ true | ✅ Yes |
| `webfetch` | ✅ true | ✅ true | ✅ true | ✅ true | ✅ true | ✅ true | ✅ Yes |
| `websearch` | ✅ true | ❌ absent | ✅ true | ✅ true | ✅ true | ✅ true | ❌ No (extra) |
| `grep` | ✅ true | ✅ true | ✅ true | ✅ true | ✅ true | ✅ true | ❌ No (extra) |
| `todoread` | ✅ true | ❌ absent | ✅ false | ✅ false | ✅ false | ✅ false | ❌ No (extra) |
| `todowrite` | ✅ true | ✅ **false** | ✅ false | ✅ false | ✅ false | ✅ false | ✅ Yes |
| `question` | ✅ true | ❌ absent | ✅ true | ✅ true | ✅ true | ✅ true | ❌ No (extra) |
| `agent-browser` | ✅ true | ✅ true | ✅ true | ✅ true | ✅ true | ✅ true | ❌ No (extra) |
| `td` | ✅ true | ✅ true | ✅ true | ✅ true | ✅ true | ✅ true | ✅ Yes |

**Key observations:**
- All 6 agents declare all 7 policy-mandated keys (`bash`, `write`, `edit`, `skill`, `webfetch`, `todowrite`, `td`).
- `staff-engineer` has `todowrite: false` (explicitly declared, intentionally disabled — consistent with its read/review role that does not need internal checklists).
- `staff-engineer` has 11 tool keys total (missing the 3 extra keys `websearch`, `todoread`, `question` that other agents declare). This is not a policy violation since those keys are not mandated.
- 7 extra keys are in use across agents: `read`, `list`, `websearch`, `grep`, `todoread`, `question`, `agent-browser`.
- `qa-engineer` has `skill: false` — this is a functional issue (F-10).
- Policy document is stale: it says "No extra keys in tools" but 7 extra keys are deployed across all agents.

---

### 3. Model Validity

Model IDs were cross-referenced against the audit script's `KNOWN_MODELS` allowlist (11 entries: `anthropic/claude-sonnet-4-6`, `anthropic/claude-opus-4-6`, `anthropic/claude-haiku-4-5`, `openai/gpt-4o`, `openai/gpt-4o-mini`, `openai/gpt-4-turbo`, `openai/gpt-5.3-codex`, `openai/o1`, `openai/o3-mini`, `google/gemini-2.0-flash`, `google/gemini-2.5-pro`).

| Agent | Model Field | In Allowlist? | Script Finding | Notes |
|-------|-------------|--------------|----------------|-------|
| `team-lead` | *(absent)* | ⚠️ **MISSING** | `missing_required_field: model` (critical) | No model field; uses primary mode default. Non-deterministic across deployments (F-02) |
| `staff-engineer` | `anthropic/claude-sonnet-4-6` | ✅ Yes | None | Correct format, in allowlist |
| `senior-engineer` | `anthropic/claude-sonnet-4-6` | ✅ Yes | None | Correct format, in allowlist |
| `product-manager` | `anthropic/claude-opus-4-6` | ✅ Yes | None | Correct format, in allowlist |
| `qa-engineer` | `openai/gpt-5.2` | ❌ **No** | `unknown_model` (high) | Not in allowlist; has never been a valid OpenAI model identifier. Likelihood of runtime failure is high. Prior audit changed from `gpt-5.3-codex` (which IS in allowlist) to `gpt-5.2` (which is not). **P0** (F-01) |
| `ux-designer` | `anthropic/claude-opus-4-6` | ✅ Yes | None | Correct format, in allowlist |

**Note on F-01 severity rationale:** The audit script classifies `unknown_model` as `high` (not `critical`). This audit escalates it to P0 because: (1) `openai/gpt-5.2` has never been a published OpenAI model identifier, (2) the prior "fix" regressed from an allowlisted model to a non-allowlisted one, and (3) a broken QA agent blocks the entire validation phase of the delivery pipeline.

**Summary:** 1 P0 (model not in allowlist, high likelihood of runtime failure), 1 P1 (missing model field), 4 in-allowlist.

---

### 3a. Audit Script: `type:` Field Findings (F-19)

The audit script (`audit-agents.mjs`) requires 4 frontmatter fields: `name`, `description`, `type`, `model` (script line 116). All 6 agents use `mode:` (values: `primary` or `subagent`) but none declare a `type:` field. The script flags this as 6 critical `missing_required_field: type` findings.

**Per-agent `mode:` vs `type:` status:**

| Agent | Has `mode:` | `mode:` value | Has `type:` | Script finding |
|-------|------------|--------------|------------|----------------|
| `team-lead` | ✅ Yes | `primary` | ❌ No | `missing_required_field: type` (critical) |
| `staff-engineer` | ✅ Yes | `subagent` | ❌ No | `missing_required_field: type` (critical) |
| `senior-engineer` | ✅ Yes | `subagent` | ❌ No | `missing_required_field: type` (critical) |
| `product-manager` | ✅ Yes | `subagent` | ❌ No | `missing_required_field: type` (critical) |
| `qa-engineer` | ✅ Yes | `subagent` | ❌ No | `missing_required_field: type` (critical) |
| `ux-designer` | ✅ Yes | `subagent` | ❌ No | `missing_required_field: type` (critical) |

**Root cause analysis:** The audit script's `VALID_TYPES` set contains `"primary"` and `"subagent"` — the same values used in `mode:`. This strongly suggests the script was written expecting `type:` as the field name, while the OpenCode runtime uses `mode:`. Two possible interpretations:

1. **Schema mismatch (script bug):** The OpenCode runtime uses `mode:` as the canonical field name. The audit script should be updated to check `mode:` instead of `type:`. In this case, all 6 agents are correct and the script needs a one-line fix.
2. **Agent gap (agent bug):** OpenCode requires both `mode:` (runtime field) and `type:` (audit/metadata field). All 6 agents need `type:` added alongside `mode:`.

**Recommendation:** Verify against OpenCode documentation which field name the runtime expects. If `mode:` is correct, update the script's `required` array from `"type"` to `"mode"`. If both are needed, add `type:` to all 6 agents with the same values as their `mode:` fields.

---

### 4. Skill Assignments

**Skills assigned per agent:**

| Agent | Assigned Skills |
|-------|----------------|
| `team-lead` | `td-workflow`, `git-workflow` |
| `staff-engineer` | `tdd-authoring`, `git-workflow` |
| `senior-engineer` | `git-worktree-flow`, `td-workflow`, `pr-quality-gate`, `git-workflow` |
| `product-manager` | `td-workflow`, `git-workflow` |
| `qa-engineer` | *(none — `skill: false`)* |
| `ux-designer` | `td-workflow`, `frontend-design` |

**Skill directories in `.opencode/skills/` (11 total):**

| Skill Directory | Assigned To Agent(s) | Status |
|----------------|---------------------|--------|
| `acceptance-criteria-authoring/` | *(none)* | ⚠️ Orphaned — not assigned to any agent |
| `agent-browser/` | *(none)* | ⚠️ Orphaned — not assigned to any agent |
| `bug-triage/` | *(none)* | ⚠️ Orphaned — not assigned to any agent (qa-engineer has `skill: false`) |
| `design-system/` | *(none)* | ⚠️ Orphaned — not assigned to any agent |
| `frontend-design/` | `ux-designer` | ✅ Assigned |
| `git-workflow/` | `team-lead`, `staff-engineer`, `senior-engineer`, `product-manager` | ✅ Assigned |
| `git-worktree-flow/` | `senior-engineer` | ✅ Assigned |
| `pr-quality-gate/` | `senior-engineer` | ✅ Assigned |
| `release-notes/` | *(none)* | ⚠️ Orphaned — not assigned to any agent |
| `td-workflow/` | `team-lead`, `senior-engineer`, `product-manager`, `ux-designer` | ✅ Assigned |
| `tdd-authoring/` | `staff-engineer` | ✅ Assigned |

**Orphaned skills (directory exists, not assigned to any agent):** 5 of 11
- `acceptance-criteria-authoring` — should be assigned to `product-manager`
- `agent-browser` — should be assigned to agents that use browser automation (senior-engineer, qa-engineer)
- `bug-triage` — should be assigned to `qa-engineer` (blocked by `skill: false`)
- `design-system` — should be assigned to `ux-designer`
- `release-notes` — no obvious owner; could be `product-manager` or `team-lead`

**Skills assigned but directory missing:** None — all assigned skills have corresponding directories.

---

### 5. Dead Config Detection

| Agent | Dead Config Found | Details | Severity |
|-------|------------------|---------|---------|
| `staff-engineer` | ✅ Yes | `bash: false` in tools block, but `permission.bash` has 13 entries. Annotated as "forward-compatible placeholders" by prior audit. Entries are never evaluated when `bash: false`. | P2 |
| `team-lead` | Partial | `permission.bash["td*"]: deny` with comment "belt-and-suspenders: td CLI must go through the td tool, not bash." This is intentional redundancy, not dead config — `bash: true` is set so the block IS evaluated. The `td*: deny` entry is active. | None |
| `senior-engineer` | None | All permission entries are active (`bash: true`). | None |
| `product-manager` | None | `bash: true` is set; permission block is active. | None |
| `qa-engineer` | None | `bash: true` is set; permission block is active. | None |
| `ux-designer` | None | `bash: true` is set; permission block is active. | None |

**Additional dead config in policy doc:**
- `agent-tools-policy.md` "Migration Required" table (lines 280–295) lists agents needing updates. `staff-engineer` entry says "entire tools block (currently absent)" — but staff-engineer now has a complete tools block. This table is stale dead documentation.

---

### 6. opencode.json Cross-Reference

**Global permission defaults (opencode.json):**

| Permission | Global Default | Notes |
|-----------|---------------|-------|
| `*` | `ask` | Catch-all: any unspecified tool requires confirmation |
| `webfetch` | `allow` | All agents can fetch web content |
| `websearch` | `allow` | All agents can search the web |
| `read["*"]` | `allow` | Read all files by default |
| `read[sensitive files]` | `deny` | `.env`, `.pem`, `.key`, credentials, `~/.ssh`, etc. |
| `edit["*"]` | `allow` | Edit all files by default |
| `edit[sensitive files]` | `deny` | Same sensitive file list as read |
| `bash["*"]` | `allow` | **All bash commands allowed by default** |
| `bash[dangerous]` | `deny` | `rm -rf*`, `rm --recursive*`, `rm -r*`, `sudo *`, `chmod 777*` |
| `bash[infra]` | `ask` | `kubectl apply/delete`, `terraform apply/destroy`, `nixos-rebuild` |
| `external_directory` | `allow` for `/home/moshpitcodes/Development/**` | Worktree access |

**Per-agent override analysis:**

| Agent | bash override | Conflict with global? | Redundancy? | Gap? |
|-------|--------------|----------------------|-------------|------|
| `team-lead` | `"*": deny` + specific allows | No conflict — agent is more restrictive | No redundancy | None |
| `staff-engineer` | `"*": deny` + specific allows (dead) | No conflict — agent is more restrictive | No redundancy | None |
| `senior-engineer` | `"*": ask` + specific allows/denies | No conflict — agent overrides global `allow` with `ask` | No redundancy | None |
| `product-manager` | `"*": deny` + specific allows | No conflict — agent is more restrictive | No redundancy | None |
| `qa-engineer` | `"*": deny` + specific allows | No conflict — agent is more restrictive | No redundancy | None |
| `ux-designer` | `"*": deny` + specific allows | No conflict — agent is more restrictive | No redundancy | None |

**Key finding (F-14):** Global `bash["*"]: allow` is the most permissive possible default. Every deployed agent overrides this with `deny` or `ask`. However, any future agent added without a bash permission block would inherit unrestricted bash access (modulo the dangerous command denies). This is a latent security gap.

**Conflicts:** None — all agents are more restrictive than global defaults.

**Redundancies:** `webfetch` and `websearch` are `allow` globally; all agents also declare `webfetch: true` and `websearch: true` in their tools blocks. The global `allow` means the tool-level `true` is redundant for permission purposes (though tool declarations still control capability availability).

**Gaps:** None identified — global denies for sensitive files are comprehensive and agents do not attempt to override them.

---

### 7. Agent-Tools-Policy Drift (31-Agent Reference)

`agent-tools-policy.md` "Agent-to-Archetype Mapping" table (lines 241–275) lists **31 agents**. Actual deployed agents: **6**.

| Policy Archetype | Actual Agent Exists? | Notes |
|-----------------|---------------------|-------|
| `team-lead` | ✅ Yes | Deployed |
| `product-manager` | ✅ Yes | Deployed |
| `validator` | ❌ No | Phantom — `qa-engineer` is the actual validator |
| `staff-engineer` | ✅ Yes | Deployed (but mapped as "Implementation" — actually Review/TDD) |
| `backend-golang` | ❌ No | Phantom |
| `backend-java-kotlin` | ❌ No | Phantom |
| `backend-typescript` | ❌ No | Phantom |
| `database-specialist` | ❌ No | Phantom |
| `devops-infrastructure` | ❌ No | Phantom |
| `frontend-react-typescript` | ❌ No | Phantom |
| `frontend-sveltekit` | ❌ No | Phantom |
| `fullstack-nextjs` | ❌ No | Phantom |
| `fullstack-sveltekit` | ❌ No | Phantom |
| `golang-backend-api` | ❌ No | Phantom |
| `golang-tui-bubbletea` | ❌ No | Phantom |
| `java-kotlin-backend` | ❌ No | Phantom |
| `mcp-server` | ❌ No | Phantom |
| `mlops-engineer` | ❌ No | Phantom |
| `nextjs-fullstack` | ❌ No | Phantom |
| `react-typescript` | ❌ No | Phantom |
| `security-engineer` | ❌ No | Phantom |
| `sveltekit-frontend` | ❌ No | Phantom |
| `sveltekit-fullstack` | ❌ No | Phantom |
| `testing-engineer` | ❌ No | Phantom |
| `tui-golang-bubbletea` | ❌ No | Phantom |
| `typescript-backend` | ❌ No | Phantom |
| `git-flow-manager` | ❌ No | Phantom (Specialized) |
| `linearapp` | ❌ No | Phantom (Specialized) |
| `nixos` | ❌ No | Phantom (Specialized) |
| `prompt-engineering` | ❌ No | Phantom (Specialized) |
| `rpg-mmo-systems-designer` | ❌ No | Phantom (Specialized) |

**Summary:** 6 of 31 agents exist (19%). 25 phantom archetypes referenced.

**Missing from policy:** `qa-engineer` and `ux-designer` are deployed but not listed in the policy mapping table at all.

**Archetype misclassification:** `staff-engineer` is mapped as "Implementation" archetype in the policy, but the actual `staff-engineer.md` has `edit: false` and `write: true` (write only to `specs/tdd/`). It is a Review/TDD agent, not an Implementation agent. The policy archetype template for "Implementation" (`edit: true`, `write: true`, `bash: true`) does not match the deployed staff-engineer.

---

## Risk Assessment

**Overall architecture health verdict: needs-minor-fixes**

The core architecture (6 agents, plugin system, TD integration, permission model) is sound. The TD-enforcer plugin is well-implemented with proper write-blocking, file tracking, review notification, and session lifecycle management. The permission model correctly applies least-privilege at the agent level, overriding the permissive global defaults.

The primary risks are:
1. **P0 model risk** — `qa-engineer` uses `openai/gpt-5.2`, not in the known-good allowlist and not a valid OpenAI model identifier. Likelihood of runtime failure is high. This breaks the validation phase of the delivery pipeline.
2. **`type:` field gap** — All 6 agents are missing the `type:` field required by the audit script (6 critical findings). This is either a script bug (should check `mode:` not `type:`) or a real gap in all agent definitions. Either way, the audit script exits with code 1 in `--strict` mode, blocking QA validation.
3. **Policy document is a liability** — `agent-tools-policy.md` is so stale (31 phantom agents, wrong tool key count, stale migration table) that it actively misleads anyone trying to add or modify agents. It should be rewritten to reflect the 6-agent reality.
4. **Workflow playbook has broken commands** — `td done` does not exist; `validator` agent does not exist. Anyone following the playbook will encounter failures.
5. **5 orphaned skills** — Nearly half the skill library is unassigned. Skills are only useful when assigned to agents that can load them.

---

## Recommended Remediation Priority

| Rank | Finding | Fix | Estimated Effort |
|------|---------|-----|-----------------|
| 1 | **F-01** (P0): `qa-engineer` model `openai/gpt-5.2` not in allowlist | Change to `anthropic/claude-sonnet-4-6` or `openai/gpt-4o` | 5 min |
| 2 | **F-19** (P1): All 6 agents missing `type:` field (6 critical script findings) | Determine if `mode:` vs `type:` is a script bug or agent gap; fix accordingly | 15–30 min |
| 3 | **F-02** (P1): `team-lead` missing `model:` field | Add `model: anthropic/claude-sonnet-4-6` | 5 min |
| 4 | **F-05 + F-06** (P1): `agent-team-workflow.md` references `validator`, `staff-engineer` as implementer, and `td done` | Replace `validator` → `qa-engineer`, `staff-engineer` → `senior-engineer`, `td done` → `td review` + `td approve` | 30 min |
| 5 | **F-03 + F-04 + F-11** (P1): `agent-tools-policy.md` stale — wrong tool key count, 25 phantom agents, stale migration table | Rewrite policy to reflect 6-agent reality with 14-key schema | 2 hours |

---

## Audit Script Output (Reference)

Executed: `node .opencode/scripts/audit-agents.mjs --strict --format markdown`

```
# Agent Audit Report

- Agents scanned: 6
- Markdown files checked: 3
- Findings: 9

## Severity Summary

- critical: 7
- high: 1
- medium: 0
- low: 1

## Findings

- [critical] .opencode/agents/product-manager.md:1 (missing_required_field) Missing required frontmatter field: type
- [critical] .opencode/agents/qa-engineer.md:1 (missing_required_field) Missing required frontmatter field: type
- [critical] .opencode/agents/senior-engineer.md:1 (missing_required_field) Missing required frontmatter field: type
- [critical] .opencode/agents/staff-engineer.md:1 (missing_required_field) Missing required frontmatter field: type
- [critical] .opencode/agents/team-lead.md:1 (missing_required_field) Missing required frontmatter field: type
- [critical] .opencode/agents/team-lead.md:1 (missing_required_field) Missing required frontmatter field: model
- [critical] .opencode/agents/ux-designer.md:1 (missing_required_field) Missing required frontmatter field: type
- [high] .opencode/agents/qa-engineer.md:1 (unknown_model) Model 'openai/gpt-5.2' is not in the known-good allowlist.
- [low] .opencode/agents/staff-engineer.md:1 (dead_bash_permission_config) tools.bash is false but permission.bash has 13 entries (dead config).
```

Script exits with code 1 in `--strict` mode (critical + high findings present). This blocks QA's mandatory agent-integrity audit gate.

---

> **Note:** At task start, repository had 6 pre-existing uncommitted modifications unrelated to this audit (`.gitignore`, `.opencode/bun.lock`, `.opencode/package.json`, `.todos/agent_errors.jsonl`, `.todos/command_usage.jsonl`, `.todos/config.json`). Only `specs/audit/td-c0187e-agent-definitions-audit.md` was created by this task.

---

*Report generated by senior-engineer (ses_508af8) for task td-c0187e. Revised per QA defect report (3 defects fixed).*
