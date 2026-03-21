# Git Skills Audit Report — td-3a95d3

**Audited:** 2026-03-01  
**Auditor:** senior-engineer (ses_7ea00b)  
**Task:** td-3a95d3 — Audit git-workflow and git-worktree-flow skills for missing steps  
**Branch:** chore/td-3a95d3-audit-git-skills  
**Files audited:**
- `.opencode/skills/git-workflow/SKILL.md` (78 lines)
- `.opencode/skills/git-worktree-flow/SKILL.md` (42 lines)

---

## Summary

Both skill files are missing critical operational steps that have caused or can cause production failures. All 5 known gaps were confirmed. One additional structural issue was found in `git-workflow/SKILL.md`: the file has no merge/post-merge section at all — not just a missing step, but a missing section entirely. The `git-worktree-flow/SKILL.md` step 5 references "prune stale refs" in prose but does not specify the explicit command `git worktree prune`, which is insufficient for agent-driven execution.

**Total gaps confirmed:** 5 of 5 known  
**New issues found:** 2

---

## git-workflow/SKILL.md

### Checks

- **Post-merge git pull step:** MISSING  
  The file has no merge/post-merge section. The PR conventions section (lines 57–71) covers PR title format and required description fields but contains no instruction for what to do after a PR is merged. There is no `git checkout main && git pull origin main` step anywhere in the file. Without this step, agents will continue working from a stale local `main`, causing false test failures and branching from outdated commits.

- **Merge/post-merge section:** MISSING (structural gap)  
  The file covers: Ownership, Branch types, Commit message format, PR conventions, Guardrails. There is no section for the merge lifecycle or post-merge cleanup. This is a structural omission, not just a missing line.

- **Other issues:**
  - Line 77 (`Guardrails`): "Rebase or merge `origin/main` early when branches diverge; do not defer to merge time." — This is good guidance but is buried in Guardrails rather than a dedicated workflow section. It does not substitute for a post-merge pull step.

### Gap Table

| Gap | Location Where It Should Go | Production Failure Risk | Severity |
|-----|-----------------------------|------------------------|----------|
| Missing post-merge `git checkout main && git pull origin main` | New "Post-merge cleanup" section after PR conventions | Agents branch from stale `main`; tests fail against outdated baseline | P1 |
| No merge/post-merge section | Between PR conventions and Guardrails | Agents have no structured guidance for the merge lifecycle | P2 |

---

## git-worktree-flow/SKILL.md

### Checks

- **Pull-before-branch step:** PARTIALLY ADDRESSED  
  The manual flow (lines 26–31) begins with `git fetch origin` (step 1), and step 2 uses `git worktree add ../<workspace> -b <branch> origin/main` — which correctly branches from `origin/main` directly, not from local `main`. The worktree creation itself is therefore safe. However, `git fetch origin` alone does NOT update the local `main` branch. This creates a gap for any subsequent operations that reference local `main`: (a) rebase operations (`git rebase main`) will rebase onto a stale base, (b) the missing rebase-before-merge gate (see below) would be ineffective if it rebases against local `main`, (c) any tooling or scripts that read local `main` will see outdated state. A `git pull origin main` step is needed before `git worktree add` to keep local `main` current for these downstream operations.

- **--force-with-lease guidance:** MISSING  
  There is no mention of `--force-with-lease` anywhere in the file. The conflict/recovery runbook (lines 33–37) mentions rebasing but does not specify how to push after a rebase. Agents will default to `git push --force` (destructive) or fail to push at all. `--force-with-lease` is the safe alternative that prevents overwriting remote changes made by others.

- **git worktree prune in cleanup:** MISSING (implicit only)  
  Step 5 of the manual flow (line 31) says: "After merge: `git worktree remove ../<workspace>` and prune stale refs." The phrase "prune stale refs" is vague prose — it does not specify the command `git worktree prune`. Agents require explicit commands. Without `git worktree prune`, stale `.git/worktrees/<name>` entries accumulate and can cause `git worktree add` to fail on subsequent tasks with the same workspace name.

- **Rebase-before-merge gate:** MISSING  
  There is no explicit gate requiring agents to rebase onto latest `origin/main` before merging. The conflict/recovery runbook (line 35) says "rebase or merge `origin/main` early, not at the end" — but this is reactive guidance for when divergence is detected, not a mandatory pre-merge gate. There is no step that says: before opening a PR or merging, run `git fetch origin && git rebase origin/main` and verify the branch is up to date.

- **Other issues:**
  - Lines 21–24 duplicate the naming policy from lines 15–19 (near-identical content in "Naming policy" and "Recommended conventions" sections). This is redundant and should be consolidated.

### Gap Table

| Gap | Location Where It Should Go | Production Failure Risk | Severity |
|-----|-----------------------------|------------------------|----------|
| Missing `git pull origin main` before `git worktree add` | Step 1–2 of Manual git worktree flow | Worktree creation uses `origin/main` correctly, but local `main` stays stale; rebase/merge operations diverge from outdated base | P1 |
| Missing `--force-with-lease` guidance | Conflict and recovery runbook, push step | Agents use `--force` (destructive) or fail to push rebased branches | P1 |
| Missing explicit `git worktree prune` command | Step 5 of Manual git worktree flow (cleanup) | Stale worktree refs accumulate; future `git worktree add` fails | P2 |
| Missing rebase-before-merge gate | New "Pre-merge checklist" or Guardrails section | PRs merge from diverged branches; integration failures | P1 |
| Duplicate naming policy content | Lines 15–19 vs 21–24 | Confusion about canonical naming convention | P3 |

---

## Known Issues Confirmed

All 5 known missing items were confirmed:

| # | Known Issue | File | Status |
|---|-------------|------|--------|
| 1 | Missing post-merge `git pull` step | `git-workflow/SKILL.md` | CONFIRMED MISSING |
| 2 | Missing pull-before-branch step | `git-worktree-flow/SKILL.md` | CONFIRMED MISSING (worktree creation uses `origin/main` correctly; gap is local `main` not updated — affects rebase/merge operations) |
| 3 | Missing `--force-with-lease` guidance | `git-worktree-flow/SKILL.md` | CONFIRMED MISSING |
| 4 | Missing `git worktree prune` in cleanup | `git-worktree-flow/SKILL.md` | CONFIRMED MISSING (implicit prose only) |
| 5 | Missing rebase-before-merge gate | `git-worktree-flow/SKILL.md` | CONFIRMED MISSING |

---

## New Issues Found

| # | Issue | File | Severity | Notes |
|---|-------|------|----------|-------|
| 1 | No merge/post-merge section exists at all | `git-workflow/SKILL.md` | P2 | Not just a missing step — the entire section is absent. The fix task (td-52e95b) should add a new section, not just a line. |
| 2 | Duplicate naming policy content | `git-worktree-flow/SKILL.md` | P3 | "Naming policy" (lines 15–19) and "Recommended conventions" (lines 21–24) are near-identical. Should be consolidated into one section. |

---

## Fix Task Mapping

| Gap | Fix Task |
|-----|----------|
| Post-merge git pull step in git-workflow | td-52e95b |
| Pull-before-branch, force-with-lease, prune, rebase gate in git-worktree-flow | td-14de4a |

---

## Appendix: Raw File State at Audit Time

**git-workflow/SKILL.md** — 78 lines, 5 sections: Ownership, Branch types, Commit message format, PR conventions, Guardrails. No merge/post-merge section.

**git-worktree-flow/SKILL.md** — 42 lines, 6 sections: What I do, Naming policy, Recommended conventions (duplicate), Manual git worktree flow, Conflict and recovery runbook, Guardrails. Manual flow has 5 steps; step 1 is `git fetch origin` (not `git pull`); step 5 references "prune stale refs" without explicit command.
