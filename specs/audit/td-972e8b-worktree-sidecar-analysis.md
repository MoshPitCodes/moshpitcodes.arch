# Git Worktree Flow Audit & Sidecar Workspace Investigation

**Task:** td-972e8b  
**Date:** 2026-03-05  
**Auditor:** senior-engineer (ses_508af8)

---

## Executive Summary

The git worktree flow is structurally sound at the skill level — the `git-worktree-flow` skill contains three of four td-14de4a patches fully and one partially (the `--rebase` flag on `git pull` is missing). However, `agent-team-workflow.md` is the primary source of risk: it references three non-existent TD commands (`td done`, `td block`, `td unblock`), two non-existent agents (`validator`, `staff-engineer` as implementer), prescribes direct `git merge` instead of PR-based flow, omits the `origin/main` base ref from `git worktree add` commands, and uses an inconsistent worktree path format. The `git-workflow` skill and `git-worktree-flow` skill have a meaningful branch naming divergence — one omits TD task IDs, the other requires them. OpenCode has no native sidecar workspace concept; the platform operates via sessions and subagents without filesystem-level isolation. Git worktrees remain the correct isolation model for this workflow and no migration path to a sidecar model exists without significant external tooling. The recommended action is to update `agent-team-workflow.md` to align with actual TD commands, correct agent roles, PR-based merge flow, and canonical worktree path format.

---

## Audit Scope

| File | Lines | Role |
|------|-------|------|
| `.opencode/skills/git-worktree-flow/SKILL.md` | 52 | Primary skill being audited |
| `.opencode/skills/git-workflow/SKILL.md` | 88 | Companion skill, consistency check |
| `.opencode/skills/pr-quality-gate/SKILL.md` | 41 | Merge flow reference |
| `.opencode/docs/agent-team-workflow.md` | 605 | Delivery playbook |
| `.opencode/commands/plan.md` | 34 | Worktree path conventions |
| `.opencode/commands/build.md` | 59 | Worktree path conventions |
| `AGENTS.md` | 31 | Global rules |
| `opencode.json` | 167 | Global config |
| `.opencode/agents/` (6 files) | ~400 | Agent definitions (worktree refs) |

---

## PART A: Git Worktree Flow Audit

### Findings Table

| ID | Severity | File | Dimension | Finding | Recommended Fix |
|----|----------|------|-----------|---------|-----------------|
| A-01 | P2 | `git-worktree-flow/SKILL.md` | A1 | Step 2 uses `git pull origin main` instead of `git pull --rebase origin main` as specified in td-14de4a patch intent | Change to `git pull --rebase origin main` to prevent merge commits on local main |
| A-02 | P0 | `agent-team-workflow.md` | A3 | `td done` used 3× (lines 196, 331, 516) — this command does NOT exist in TD CLI | Replace all with `td approve <id>` (reviewer action) or remove if post-approve cleanup |
| A-03 | P0 | `agent-team-workflow.md` | A3 | `td block` used 4× (lines 234, 346, 564, 584) — this command does NOT exist in TD CLI | Replace with `td log --type blocker "reason"` or `td update` with blocker context |
| A-04 | P0 | `agent-team-workflow.md` | A3 | `td unblock` used 1× (line 247) — this command does NOT exist in TD CLI | Replace with `td log "blocker resolved: ..."` and `td update` to clear blocker state |
| A-05 | P1 | `agent-team-workflow.md` | A3 | `validator` agent referenced (line 10) — does not exist; actual validation agent is `qa-engineer` | Replace `validator` with `qa-engineer` throughout |
| A-06 | P1 | `agent-team-workflow.md` | A3 | `staff-engineer` listed as implementer (line 9) — incorrect; `staff-engineer` is reviewer, `senior-engineer` implements | Replace `staff-engineer (implementation and code review)` with `senior-engineer (implementation)` and `staff-engineer (code review)` |
| A-07 | P1 | `agent-team-workflow.md` | A5 | Direct `git merge` used 2× (lines 187, 329) in merge/cleanup flow — contradicts PR-based flow mandated by `pr-quality-gate` skill | Replace with `gh pr create` + PR merge flow; add pre-merge rebase gate |
| A-08 | P1 | `agent-team-workflow.md` | A5 | Troubleshooting section (line 570) uses `git merge main` inside worktree — contradicts rebase-first guidance | Replace with `git rebase origin/main` per `git-worktree-flow` conflict runbook |
| A-09 | P2 | `agent-team-workflow.md` | A4 | Worktree path format `~/Development/.worktrees/feature-td-abc123-jwt-service` (full branch slug) conflicts with `plan.md` format `~/Development/.worktrees/td-xxx` (task ID only) | Adopt canonical format (see A4 section below) |
| A-10 | P2 | `git-workflow/SKILL.md` | A2 | Branch naming omits TD task ID: `feature/<slug>` vs `git-worktree-flow` which requires `feature/td-<id>-<slug>` | Update `git-workflow` branch table to include TD-ID variant or add note that TD-tracked work uses the extended format |
| A-11 | P2 | `agent-team-workflow.md` | A3 | `refactor/` branch type listed (line 121) but not present in `git-workflow` skill branch types table | Add `refactor/` to `git-workflow` branch types, or remove from playbook |
| A-12 | P3 | `agent-team-workflow.md` | A3 | `docs/` and `test/` branch types listed (lines 122-123) but not in `git-workflow` skill | Align branch type lists across both documents |
| A-13 | P1 | `plan.md:31`, `agent-team-workflow.md:128` | A4 | `git worktree add` omits `origin/main` base ref — agents will branch from local HEAD (potentially stale) instead of `origin/main`, contradicting `git-worktree-flow` skill which explicitly requires the base ref | Update both files to use `git worktree add <path> -b <branch> origin/main` consistently |

---

### A1 — td-14de4a Patch Verification

The four patches from td-14de4a are verified against the current `git-worktree-flow/SKILL.md`:

| Patch Item | Status | Evidence | Notes |
|------------|--------|----------|-------|
| `git pull --rebase origin main` before branching | **PARTIAL** | Line 24: `git pull origin main` (no `--rebase` flag) | The intent is present (pull before branch) but the `--rebase` flag is missing. Plain `git pull` creates a merge commit on local main if it has diverged; `--rebase` keeps history linear. This is a minor but meaningful distinction. |
| `git push --force-with-lease` instead of plain push | **PRESENT** | Line 36: `use git push --force-with-lease (not --force)` | Correctly placed in conflict/recovery runbook with clear rationale. |
| `git worktree prune` in cleanup steps | **PRESENT** | Line 29: `Run git worktree prune to remove stale worktree refs after git worktree remove` | Correctly placed as step 7 in the manual flow. |
| Rebase gate before merging | **PRESENT** | Lines 38-47: Full `## Pre-merge rebase gate` section with `git fetch origin` + `git rebase origin/main` | Correctly placed with mandatory language: "This gate is mandatory — do not merge without completing it." |

**Summary:** 3 of 4 patches fully present; 1 partial (missing `--rebase` flag on pull).

---

### A2 — Cross-Skill Consistency (git-worktree-flow ↔ git-workflow)

| Convention | git-worktree-flow says | git-workflow says | Consistent? |
|------------|----------------------|-------------------|-------------|
| Branch naming — feature | `feature/td-<id>-<slug>` | `feature/<slug>` (e.g., `feature/user-authentication`) | **NO** — TD task ID required in worktree-flow, absent in git-workflow |
| Branch naming — bugfix | `bugfix/td-<id>-<slug>` | `bugfix/<slug>` (e.g., `bugfix/login-error`) | **NO** — same divergence |
| Branch naming — chore | `chore/td-<id>-<slug>` | Not listed | **PARTIAL** — chore type missing from git-workflow |
| Branch naming — hotfix | Not listed | `hotfix/<slug>` | **PARTIAL** — hotfix missing from git-worktree-flow |
| Branch naming — release | Not listed | `release/<version>` | **PARTIAL** — release missing from git-worktree-flow |
| Commit message format | Not specified | Conventional commits (`feat:`, `fix:`, etc.) with full type table | **GAP** — git-worktree-flow has no commit message guidance |
| PR vs direct merge | "Validate, review, push, open PR" (step 5) | PR conventions section with title format and required fields | **CONSISTENT** — both imply PR-based flow |
| Rebase strategy | Explicit: rebase early, force-with-lease on push | Implicit: "Rebase or merge origin/main early" (guardrail) | **CONSISTENT** — aligned guidance |
| Protected branch | Not mentioned | `main is protected; never push directly` | **GAP** — git-worktree-flow doesn't state main protection |
| Post-merge sync | Not mentioned | `git checkout main && git pull origin main` | **GAP** — git-worktree-flow doesn't cover post-merge sync |

**Key finding:** The branch naming divergence (A-10) is the most impactful inconsistency. An agent following `git-workflow` would create `feature/user-auth` while an agent following `git-worktree-flow` would create `feature/td-abc123-user-auth`. These are incompatible conventions that will cause confusion in multi-agent workflows.

---

### A3 — Playbook Command Audit (agent-team-workflow.md)

#### Non-Existent TD Commands

| Command | Occurrences | Lines | Severity | Valid Alternative |
|---------|-------------|-------|----------|-------------------|
| `td done` | 3 | 196, 331, 516 | **P0** | No direct equivalent. Post-approve cleanup is manual. Remove or replace with comment. |
| `td block` | 4 | 234, 346, 564, 584 | **P0** | `td log --type blocker "reason"` captures blocker context; no status-change command exists |
| `td unblock` | 1 | 247 | **P0** | `td log "blocker resolved: ..."` — no unblock command exists |

**Valid TD actions (for reference):** status, start, focus, link, log, review, approve, reject, handoff, whoami, usage, create, epic, tree, dep, ws, query, search, critical-path, next, ready, blocked, in-review, reviewable, context, comment, update, files, unlink, block-issue, unblock-issue

Note: `block-issue` and `unblock-issue` exist but operate on issue-level blocking (dependency blocking), not the same as the playbook's `td block --reason` pattern which implies a status-change command.

#### Non-Existent Agent References

| Reference | Line | Severity | Fix |
|-----------|------|----------|-----|
| `validator` agent in Team Roles | 10 | **P1** | Replace with `qa-engineer` |
| `staff-engineer` as implementer | 9 | **P1** | Replace with `senior-engineer (implementation)` |

**Actual agent roster:** team-lead, product-manager, staff-engineer (reviewer), senior-engineer (implementer), qa-engineer (validator), ux-designer

#### Direct Git Merge (PR-bypass)

| Usage | Line | Context | Severity |
|-------|------|---------|----------|
| `git merge feature/td-abc123-jwt-service` | 187 | "Merge and Cleanup" step 5 | **P1** |
| `git merge feature/td-abc123-jwt-service` | 329 | "Approved" review outcome | **P1** |
| `git merge main` | 570 | Troubleshooting conflict resolution | **P1** |

All three bypass the PR-based flow required by `pr-quality-gate` skill. The correct flow is: `gh pr create` → PR review → merge via GitHub UI or `gh pr merge`.

---

### A4 — Worktree Path Naming

#### All Formats Found

| Format | Source | Example |
|--------|--------|---------|
| `~/Development/.worktrees/feature-td-abc123-jwt-service` | `agent-team-workflow.md` (lines 128, 142, 190, 330, 397, 433, 474, 519-521) | Full branch slug as directory name |
| `~/Development/.worktrees/td-xxx` | `plan.md` (lines 28, 31) | Task ID only |
| `~/Development/.worktrees/<workspace>` | `git-worktree-flow/SKILL.md` (lines 25, 28) | Generic placeholder |
| `~/Development/.worktrees/<name>` | `team-lead.md` (line 108) | Generic placeholder |
| `~/Development/.worktrees/td-xxx` | `product-manager.md` (line 93) | Task ID only |

#### Recommended Canonical Format

**Recommended:** `~/Development/.worktrees/<branch-type>-td-<id>-<slug>`

**Examples:**
- `~/Development/.worktrees/feature-td-abc123-jwt-service`
- `~/Development/.worktrees/bugfix-td-def456-login-error`
- `~/Development/.worktrees/chore-td-ghi789-update-deps`

**Rationale:**
1. **Mirrors branch name** — `feature/td-abc123-jwt-service` → `feature-td-abc123-jwt-service` (slash replaced with hyphen). This makes the relationship between branch and worktree directory immediately obvious.
2. **Includes task ID** — enables `td focus` to be run from the directory without needing to look up the task.
3. **Includes type prefix** — distinguishes feature vs bugfix worktrees at a glance in `ls ~/.worktrees/`.
4. **Already used in playbook** — `agent-team-workflow.md` already uses this format; `plan.md` and `product-manager.md` use the shorter `td-xxx` format which loses type and slug context.

**Files requiring update to canonical format:** `plan.md` (lines 28, 31), `product-manager.md` (line 93), `git-worktree-flow/SKILL.md` (lines 25, 28 — update placeholder to show canonical pattern).

#### A-13 — Missing `origin/main` Base Ref in `git worktree add` (P1)

The `git-worktree-flow` skill (line 25) explicitly specifies:
```bash
git worktree add ~/Development/.worktrees/<workspace> -b <branch> origin/main
```

However, two files omit the `origin/main` base ref:

| File | Line | Command as Written | Risk |
|------|------|--------------------|------|
| `plan.md` | 31 | `git worktree add ~/Development/.worktrees/<task-id> -b <branch-name>` | Branches from local HEAD — may be stale if `git fetch` was not run recently |
| `agent-team-workflow.md` | 128 | `git worktree add -b feature/td-abc123-jwt-service ~/Development/.worktrees/feature-td-abc123-jwt-service` | Same risk — no base ref specified |

**Why this matters:** Without an explicit base ref, `git worktree add -b <branch>` branches from the current local HEAD of the checked-out branch. If the local `main` has not been synced with `origin/main` (e.g., after another PR was merged), the new worktree will be based on a stale commit. This silently introduces the exact divergence problem the `git pull --rebase` step is meant to prevent.

**Fix:** Both files must be updated to append `origin/main` as the base ref:
```bash
git worktree add <path> -b <branch> origin/main
```

---

### A5 — Merge Flow Analysis

#### Current State in agent-team-workflow.md

The playbook prescribes **direct `git merge`** in two critical locations:
- "Merge and Cleanup" step (line 187): `git merge feature/td-abc123-jwt-service`
- "Approved" review outcome (line 329): `git merge feature/td-abc123-jwt-service`

#### What pr-quality-gate Skill Requires

The `pr-quality-gate` skill mandates:
- Acceptance criteria validated with evidence
- No unresolved high-severity code review findings
- Required tests/checks passed
- Risk/rollback notes documented
- Minimum PR summary sections (why, what, validation, risks)

Direct `git merge` bypasses all of these gates — there is no PR to attach evidence to, no reviewer verdict to capture, and no rollback notes to document.

#### What git-workflow Skill Says

The `git-workflow` skill has a full **PR conventions** section (lines 56-71) specifying:
- PR title format matching commit type
- Required PR description fields (Summary, Impact, Files changed, Testing performed, Issues closed)

This is unambiguously PR-based. The skill does not mention direct merge.

#### Verdict

The playbook's direct `git merge` approach **contradicts both** `pr-quality-gate` and `git-workflow` skills. The correct flow is:

```bash
# Pre-merge rebase gate (from git-worktree-flow skill)
git fetch origin
git rebase origin/main

# Push branch
git push --force-with-lease origin feature/td-abc123-jwt-service

# Create PR (requires user confirmation per opencode.json)
gh pr create --title "feat: implement JWT service" --body "..."

# After PR approval, merge via GitHub UI or:
gh pr merge --squash
```

---

## PART B: Sidecar Workspace Investigation

### Research Summary

**OpenCode documentation research** (opencode.ai/docs, github.com/anomalyco/opencode) confirms:

OpenCode has **no native sidecar workspace concept**. The platform's isolation model operates at the **session/agent level**, not the filesystem level:

- **Sessions** — each conversation is a session with its own context window. Sessions can have child sessions (subagents). Navigation between parent/child sessions is supported via keybinds.
- **Subagents** — specialized agents invoked by primary agents via the Task tool. They run in the same filesystem context as the parent.
- **No workspace isolation** — OpenCode does not create separate directories, containers, or filesystem namespaces per task. All agents operate in the project directory (or wherever OpenCode is launched from).
- **No sidecar concept in docs** — the terms "sidecar", "workspace isolation", "container", and "isolated workspace" do not appear in OpenCode documentation.

The closest OpenCode concept to "sidecar" is the **subagent model** — a specialized agent running in a child session. But subagents share the same working directory and filesystem as the parent, providing no task isolation.

**What "sidecar workspace" would require** (not natively supported):
1. Docker/container per task — external tooling, not OpenCode-native
2. Separate OpenCode instances in separate directories — manual setup, no orchestration
3. VM-level isolation — far beyond current scope

### Comparison Matrix

| Dimension | Git Worktrees (current) | Sidecar Workspaces (hypothetical) | Winner |
|-----------|------------------------|----------------------------------|--------|
| **Task isolation (file system)** | Each branch = isolated FS via `git worktree add` | Would require Docker/container or separate directory + manual setup | **Git Worktrees** |
| **Setup complexity per task** | 1 command: `git worktree add -b <branch> <path>` | Multiple steps: container build/start, directory init, OpenCode launch | **Git Worktrees** |
| **TD integration** | TD CLI works natively in any worktree directory; `td focus` sets context | TD CLI would need to be installed/configured in each container; session isolation unclear | **Git Worktrees** |
| **Parallel execution** | Multiple worktrees simultaneously, each with own OpenCode session | Possible with containers but requires orchestration layer not in OpenCode | **Git Worktrees** |
| **Cleanup** | `git worktree remove <path>` + `git branch -d` + `git worktree prune` | Container teardown + volume cleanup + branch delete — more steps | **Git Worktrees** |
| **Agent compatibility** | All agents work in any directory; `external_directory` permission in opencode.json covers `~/Development/**` | Would require permission updates per container path; agent config not portable | **Git Worktrees** |
| **Context switching overhead** | Low — directory change only; OpenCode session continues | High — new container/process start per task switch | **Git Worktrees** |
| **Risk of cross-task pollution** | Low — separate branches prevent file conflicts; td-enforcer enforces task focus | Low (if containerized) but adds operational complexity with no benefit over worktrees | **Git Worktrees** |

**Score: Git Worktrees 8/8 dimensions**

### Migration Assessment

#### What Would Break

| Component | Worktree Reference | Break Risk |
|-----------|-------------------|------------|
| `git-worktree-flow/SKILL.md` | Core skill — entire content | **Complete rewrite required** |
| `agent-team-workflow.md` | 15+ worktree references | **Complete rewrite required** |
| `plan.md` | Worktree execution map output format | **Significant rewrite** |
| `senior-engineer.md` | `git worktree*: allow` permission, skill assignment | **Permission + skill update** |
| `qa-engineer.md` | `~/Development/.worktrees/**` permission | **Permission update** |
| `team-lead.md` | Worktree mapping in lane handoffs | **Prose update** |
| `product-manager.md` | Worktree execution map output | **Template update** |
| `opencode.json` | `external_directory` covers `~/Development/**` — would need container paths | **Config update** |
| `AGENTS.md` | No direct worktree references | **No change needed** |

#### Effort Estimate

**XL** — Migration from git worktrees to a sidecar model would require:
1. Selecting and implementing a container/isolation technology (Docker, nix-shell, devcontainers)
2. Rewriting 7+ files of agent/skill/command configuration
3. Building an orchestration layer OpenCode doesn't provide
4. Updating TD CLI integration for container-aware operation
5. Testing parallel execution across container boundaries
6. Training agents on new workflow patterns

This is a multi-week infrastructure project with no clear benefit over the current git worktree approach.

### Recommendation

**KEEP git worktrees.**

**Rationale:** Git worktrees are the correct isolation model for this workflow. They provide native filesystem isolation with a single command, integrate seamlessly with TD CLI, support parallel execution across multiple tasks, and are already supported by OpenCode's `external_directory` permission model. OpenCode has no native sidecar concept, and implementing one would require significant external tooling with no isolation benefit over worktrees. The current architecture is sound — the issues identified in Part A are documentation/playbook problems, not architectural problems with the worktree model itself.

---

## Risk Assessment

**Verdict: NEEDS MINOR FIXES**

The underlying architecture (git worktrees + TD CLI + OpenCode agents) is sound. The `git-worktree-flow` skill is well-structured and contains all required safety patches. The risk is concentrated in `agent-team-workflow.md`, which contains multiple P0 references to non-existent TD commands that would cause agent failures if followed literally. These are documentation bugs, not architectural flaws, and are straightforward to fix.

---

## Remediation Priority

| Rank | Finding | Severity | File | Fix | Effort |
|------|---------|----------|------|-----|--------|
| 1 | `td done` (3×), `td block` (4×), `td unblock` (1×) — non-existent commands | P0 | `agent-team-workflow.md` | Replace with valid TD commands or remove | S |
| 2 | `git worktree add` missing `origin/main` base ref — agents branch from stale local HEAD | P1 | `plan.md`, `agent-team-workflow.md` | Append `origin/main` to all `git worktree add -b <branch>` commands | XS |
| 3 | Direct `git merge` (2× in main flow, 1× in troubleshooting) — bypasses PR gate | P1 | `agent-team-workflow.md` | Replace with `gh pr create` + `gh pr merge` flow | S |
| 4 | `validator` and `staff-engineer-as-implementer` agent references | P1 | `agent-team-workflow.md` | Update Team Roles section to match actual agent roster | XS |
| 5 | Branch naming divergence: `git-workflow` omits TD task ID | P2 | `git-workflow/SKILL.md` | Add note that TD-tracked work uses `feature/td-<id>-<slug>` format | XS |

**Also recommended (P2):** Worktree path format inconsistency across `plan.md`, `product-manager.md`, playbook — adopt canonical `<type>-td-<id>-<slug>` format everywhere.

**Bonus (P2, not ranked):** `git pull origin main` → `git pull --rebase origin main` in `git-worktree-flow/SKILL.md` step 2 to fully complete the td-14de4a patch intent.
