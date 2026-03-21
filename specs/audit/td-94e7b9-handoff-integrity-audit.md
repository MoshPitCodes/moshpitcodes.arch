# Cross-Agent Handoff Integrity Audit Report
**Task:** td-94e7b9  
**Date:** 2026-03-06  
**Auditor:** senior-engineer (ses_b22378)

---

## Executive Summary

The end-to-end orchestration flow from `/plan` through `/build` to completion was traced across all delegation points. **All 7 handoff points are classified as implicit (subagent return)** — there is no explicit handoff mechanism beyond the Task tool's return value. The bug feedback loop (qa→pm→senior) is **wired in prose only** — no enforcement mechanism exists. Phase gates are **prose-only** with no tooling enforcement. Sub-agent TD inheritance compliance is **broken**: team-lead does not include explicit TD requirement text when spawning sub-agents. Review ownership constraints are **documented but not enforced** — the TD tool allows approve/reject from the same session. **Total findings: P0: 1, P1: 4, P2: 3, P3: 2. Total: 10.**

---

## Audit Scope

**Files audited:**
- 6 agent definitions (team-lead, product-manager, senior-engineer, qa-engineer, staff-engineer, ux-designer): 556 lines
- 2 command files (plan.md, build.md): 93 lines
- AGENTS.md: 31 lines
- TD tool implementation (td.ts): 31 actions

**Total lines analyzed:** 680 lines

---

## Findings Table

| ID | Severity | Component | Dimension | Finding | Recommended Fix |
|----|----------|-----------|-----------|---------|-----------------|
| H-01 | **P0** | team-lead → sub-agents | Sub-agent TD inheritance | **Broken:** AGENTS.md Rule 3 requires "Before spawning one, include explicit TD requirement text in the sub-agent prompt." Team-lead does not include this text when delegating to product-manager, senior-engineer, qa-engineer, or staff-engineer. Sub-agents operate without TD enforcement. | Add explicit TD requirement text to team-lead's delegation prompts: "Follow global TD rules in AGENTS.md. Before any file edit/write, run TD(action: 'status'). At session start, run TD(action: 'usage', newSession: true). Before context ends, write TD(action: 'handoff', ...)." |
| H-02 | **P1** | All handoffs | Handoff mechanism | **Implicit:** All 7 delegation points (team-lead→staff-engineer, team-lead→ux-designer, team-lead→product-manager, team-lead→senior-engineer, team-lead→qa-engineer, qa→product-manager, product-manager→senior-engineer) rely on subagent return values. No explicit handoff contract, no structured handoff artifact, no handoff verification. | Define explicit handoff contracts in each agent's "Required output format" section. Create a handoff artifact schema (task ID, status, changed files, blockers, next action). |
| H-03 | **P1** | Bug feedback loop | Loop wiring | **Prose-only:** qa-engineer.md lines 72–76 describe the bug intake workflow: "When QA reports a bug: 1. Search existing open bugs... 2. Create a bug issue... 3. Add dependency links... 4. Log triage decision in TD." However, there is no mechanism in build.md or team-lead.md that routes qa-engineer bug reports to product-manager. The loop is documented but not wired in the orchestration flow. | Add explicit bug routing step to build.md: "If qa-engineer reports bugs, delegate triage to product-manager. Product-manager creates bug issues and routes to senior-engineer. Track bug fix tasks in TD." |
| H-04 | **P1** | Phase gates | Enforcement | **Prose-only:** build.md lines 26–29 define phase gates: "All lanes: acceptance criteria validated", "All lanes: no unresolved high-severity review findings", "All lanes: validation evidence captured". team-lead.md lines 82–85 define required phase gates. However, there is no tooling enforcement — the TD tool does not block implementation before planning, or validation before implementation. Gates are trust-based. | Add phase gate enforcement to TD tool: `TD(action: "gate", phase: "implementation")` should fail if planning is incomplete. `TD(action: "gate", phase: "validation")` should fail if implementation is incomplete. |
| H-05 | **P1** | Review ownership | Session constraint | **Documented but not enforced:** staff-engineer.md lines 82–84 define verdict rules: "approve: no unresolved high-severity issues", "changes_requested: any high-severity issue or critical validation gap". However, the TD tool allows `TD(action: "approve")` or `TD(action: "reject")` from the same session that implemented the work. There is no session isolation enforcement. | Add session constraint to TD tool: `approve` and `reject` actions should require a different session than the implementer session. Document this constraint in staff-engineer.md and team-lead.md. |
| H-06 | **P2** | team-lead → product-manager | Input contract | **Missing:** team-lead delegates to product-manager for planning (team-lead.md line 62), but there is no explicit input contract. Product-manager must infer what to plan from the TD task context. No structured planning input artifact. | Define planning input contract in team-lead.md: "Delegate to product-manager with: (1) TD task ID, (2) feature request text, (3) existing specs (tdd/design), (4) constraints and non-goals." |
| H-07 | **P2** | product-manager → senior-engineer | Output contract | **Partial:** product-manager.md lines 78–87 define required output format including execution map. However, there is no verification that senior-engineer receives and acknowledges the execution map. Handoff is one-way. | Add acknowledgment step to senior-engineer.md: "Before implementation, confirm receipt of execution map from product-manager. Log execution map acknowledgment in TD." |
| H-08 | **P2** | senior-engineer → qa-engineer | Handoff artifact | **Missing:** senior-engineer.md lines 88–89 describe "Record handoff and submit review", but there is no structured handoff artifact to qa-engineer. QA must infer what to validate from TD task context. | Define handoff artifact in senior-engineer.md: "Before validation, create handoff artifact: (1) changed files list, (2) test commands, (3) acceptance criteria mapping, (4) known issues. Link artifact to TD task." |
| H-09 | **P3** | team-lead orchestration | Parallel lane tracking | **Prose-only:** build.md lines 44–48 define per-lane status tracking. However, team-lead has no mechanism to aggregate lane status across parallel lanes. The TD tool does not support multi-lane tracking. | Extend TD tool with lane tracking: `TD(action: "ws", wsAction: "tag", wsName: "lane-A")` to tag work sessions by lane. Add `TD(action: "critical-path")` to identify blocked lanes. |
| H-10 | **P3** | team-lead → staff-engineer | Review routing | **Implicit:** team-lead.md line 65 says "Route review to staff-engineer", but there is no explicit routing mechanism. Staff-engineer must check `reviewable` queue manually. No notification or assignment. | Add review assignment to TD tool: `TD(action: "review", task: "td-xxx", assignee: "staff-engineer")` to explicitly route review. Staff-engineer checks `in-review` queue for assigned tasks. |

---

## Orchestration Flow Trace

### /plan Command Flow

```
/plan <feature-request>
  ↓
team-lead (orchestrator)
  ├─ Load TD context (usage, status)
  ├─ Check for existing task or create new one
  └─ Delegate to product-manager
      ↓
      [IMPLICIT HANDOFF - subagent return]
      ↓
product-manager (planner)
  ├─ Load TD context (status, query, search)
  ├─ Read specs (tdd, design)
  ├─ Define scope and non-goals
  ├─ Author acceptance criteria
  ├─ Create TD issues with dependencies
  └─ Return execution map
      ↓
      [IMPLICIT HANDOFF - subagent return]
      ↓
team-lead receives execution map
  └─ Log planning completion to TD
```

**Handoff classification:**
- team-lead → product-manager: **IMPLICIT** (Task tool return value)
- product-manager → team-lead: **IMPLICIT** (subagent return)

**Input/output contracts:**
- Input to product-manager: **MISSING** (no explicit contract)
- Output from product-manager: **DEFINED** (execution map in lines 78–87)

---

### /build Command Flow

```
/build <task-id>
  ↓
team-lead (orchestrator)
  ├─ Load TD context (usage, status)
  ├─ Resolve scope source
  ├─ Assess parallelization opportunity
  └─ Choose execution mode (sequential or parallel)
      ↓
      [PHASE GATE: Planning complete] ← PROSE-ONLY, NOT ENFORCED
      ↓
  Implementation phase:
  └─ Delegate to senior-engineer lane(s)
      ↓
      [IMPLICIT HANDOFF - subagent return]
      ↓
  senior-engineer (implementer)
      ├─ Load task context (status, context)
      ├─ Confirm task/worktree alignment
      ├─ Implement changes
      ├─ Run checks/tests
      ├─ Log decisions and results
      └─ Record handoff and submit review
          ↓
          [IMPLICIT HANDOFF - subagent return]
          ↓
      [PHASE GATE: Implementation complete] ← PROSE-ONLY, NOT ENFORCED
      ↓
  Validation phase:
  └─ Delegate to qa-engineer lane(s)
      ↓
      [IMPLICIT HANDOFF - subagent return]
      ↓
  qa-engineer (validator)
      ├─ Load task context and AC
      ├─ Confirm branch/worktree under test
      ├─ Run shallow checks
      ├─ Run test suites
      ├─ Build AC verification matrix
      ├─ Log blockers and bug reports
      └─ Recommend next action
          ↓
          [IMPLICIT HANDOFF - subagent return]
          ↓
      [PHASE GATE: Validation complete] ← PROSE-ONLY, NOT ENFORCED
      ↓
  Bug feedback loop (if bugs found):
  └─ qa-engineer reports bugs
      ↓
      [MISSING WIRING - no explicit route to product-manager]
      ↓
  product-manager (bug triage)
      ├─ Search existing bugs
      ├─ Create bug issue
      ├─ Add dependency links
      └─ Log triage decision
          ↓
          [MISSING WIRING - no explicit route to senior-engineer]
          ↓
  senior-engineer (bug fix)
      └─ Fix bug and resubmit
          ↓
          [LOOP BACK TO VALIDATION]
      ↓
  Review phase:
  └─ Delegate to staff-engineer
      ↓
      [IMPLICIT HANDOFF - subagent return]
      ↓
  staff-engineer (reviewer)
      ├─ Check reviewable queue
      ├─ Load task context
      ├─ Inspect files and diffs
      ├─ Leave comments
      └─ Verdict: approve or changes_requested
          ↓
          [IMPLICIT HANDOFF - subagent return]
          ↓
      [PHASE GATE: Review complete] ← PROSE-ONLY, NOT ENFORCED
      ↓
  team-lead aggregates results
  └─ Enforce go/no-go gate
      ├─ All lanes: AC validated
      ├─ All lanes: no unresolved high-severity findings
      └─ All lanes: validation evidence captured
```

**Handoff classification:**
- team-lead → senior-engineer: **IMPLICIT** (Task tool return value)
- senior-engineer → team-lead: **IMPLICIT** (subagent return)
- team-lead → qa-engineer: **IMPLICIT** (Task tool return value)
- qa-engineer → team-lead: **IMPLICIT** (subagent return)
- qa-engineer → product-manager: **BROKEN** (no explicit route)
- product-manager → senior-engineer: **BROKEN** (no explicit route)
- team-lead → staff-engineer: **IMPLICIT** (Task tool return value)
- staff-engineer → team-lead: **IMPLICIT** (subagent return)

**Input/output contracts:**
- Input to senior-engineer: **MISSING** (no handoff artifact)
- Output from senior-engineer: **DEFINED** (handoff in TD log)
- Input to qa-engineer: **MISSING** (no handoff artifact)
- Output from qa-engineer: **DEFINED** (validation report)
- Input to staff-engineer: **DEFINED** (TD task context)
- Output from staff-engineer: **DEFINED** (verdict)

---

## Bug Feedback Loop Analysis

**Documented flow (qa-engineer.md lines 72–76):**
1. qa-engineer reports bug
2. product-manager searches existing bugs
3. product-manager creates bug issue
4. product-manager adds dependency links
5. product-manager logs triage decision

**Actual wiring:**
- qa-engineer → product-manager: **BROKEN** — no explicit route in build.md or team-lead.md
- product-manager → senior-engineer: **BROKEN** — no explicit route in build.md or team-lead.md

**Gap:** The bug feedback loop is documented in qa-engineer.md but not wired in the orchestration flow. Team-lead must manually route bug reports to product-manager, and product-manager must manually route bug fixes to senior-engineer.

---

## Phase Gate Enforcement Analysis

**Defined gates (team-lead.md lines 82–85):**
1. Planning complete before implementation
2. Implementation complete before validation
3. Validation complete before final review decision

**Enforcement mechanism:**
- **PROSE-ONLY** — no tooling enforcement
- TD tool does not block `start` if planning is incomplete
- TD tool does not block validation if implementation is incomplete
- TD tool does not block review if validation is incomplete

**Gap:** Phase gates are trust-based. An agent can skip phases without tooling enforcement.

---

## Sub-Agent TD Inheritance Compliance

**AGENTS.md Rule 3 (lines 25–27):**
> "Sub-agents do not inherit TD enforcement.
>  - Before spawning one, include explicit TD requirement text in the sub-agent prompt.
>  - After completion, link changed files via TD(action: 'link', task: 'TASK-123', files: [...])."

**Compliance check:**
- team-lead → product-manager: **BROKEN** — no explicit TD requirement text in delegation
- team-lead → senior-engineer: **BROKEN** — no explicit TD requirement text in delegation
- team-lead → qa-engineer: **BROKEN** — no explicit TD requirement text in delegation
- team-lead → staff-engineer: **BROKEN** — no explicit TD requirement text in delegation

**Gap:** Team-lead does not include explicit TD requirement text when spawning sub-agents. Sub-agents operate without TD enforcement unless they independently follow AGENTS.md rules.

---

## Review Ownership Constraints

**staff-engineer.md verdict rules (lines 82–84):**
- `approve`: no unresolved high-severity issues
- `changes_requested`: any high-severity issue or critical validation gap

**TD tool session constraint:**
- **NOT ENFORCED** — TD tool allows `approve` and `reject` from the same session that implemented the work
- No session isolation check

**Gap:** Review ownership constraint is documented but not enforced. A senior-engineer could approve their own work by using a different TD session.

---

## Recommendations

### Critical (P0)

1. **Fix sub-agent TD inheritance (H-01):** Add explicit TD requirement text to team-lead's delegation prompts. This is a mandatory rule in AGENTS.md and is currently broken.

### High Priority (P1)

2. **Define explicit handoff contracts (H-02):** Create a handoff artifact schema and require each agent to produce it before handoff.
3. **Wire bug feedback loop (H-03):** Add explicit bug routing steps to build.md and team-lead.md.
4. **Enforce phase gates (H-04):** Add phase gate enforcement to TD tool or create a gate plugin.
5. **Enforce review session constraint (H-05):** Add session isolation check to TD tool's `approve` and `reject` actions.

### Medium Priority (P2)

6. **Define planning input contract (H-06):** Add explicit input contract to team-lead → product-manager delegation.
7. **Add execution map acknowledgment (H-07):** Require senior-engineer to acknowledge execution map receipt.
8. **Define validation handoff artifact (H-08):** Require senior-engineer to produce structured handoff artifact for qa-engineer.

### Low Priority (P3)

9. **Add lane tracking to TD tool (H-09):** Support multi-lane tracking for parallel execution.
10. **Add review assignment to TD tool (H-10):** Explicitly route reviews to staff-engineer.

---

## Conclusion

The orchestration flow is **structurally sound but enforcement-weak**. All handoffs are implicit, phase gates are prose-only, and sub-agent TD inheritance is broken. The bug feedback loop is documented but not wired. Review ownership constraints are documented but not enforced. **The single P0 finding (H-01) is critical** — sub-agents are operating without TD enforcement, violating AGENTS.md Rule 3. This should be fixed immediately. The P1 findings (H-02 through H-05) are high-impact and should be addressed in the next iteration. The P2 and P3 findings are quality-of-life improvements that can be deferred.
