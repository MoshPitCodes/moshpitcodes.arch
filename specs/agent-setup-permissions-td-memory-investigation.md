# Plan: Agent Setup, Permissions, TD Task, and Memory Investigation

## Task Description

Investigate and remediate critical issues across four areas of the OpenCode template workspace:

1. **Agent setup issues** — Mismatches between agent markdown frontmatter and `opencode.json` config, inconsistent tool declarations, dead config, and mode discrepancies.
2. **Permission issues** — Agents with overly broad or contradictory permissions, missing least-privilege enforcement, and gaps between documented policy and actual config.
3. **TD task usage issues** — TD enforcer plugin gaps, agents not consistently following TD workflow rules, and potential race conditions in the TD tool.
4. **Memory leaks (18GB RAM)** — Investigate which plugins, tools, or scripts could cause unbounded memory growth during long OpenCode sessions.

## Goal

Produce a comprehensive audit of all four areas with concrete findings, then implement targeted fixes that:
- Align all agent configs with the documented `agent-tools-policy.md` archetypes
- Close permission gaps and eliminate dead config
- Harden TD enforcement and fix workflow compliance issues
- Identify and fix memory leak sources that cause 18GB RAM usage

## Scope
- All 6 agent markdown files in `.opencode/agents/`
- `opencode.json` agent config block (lines 74–247)
- All 6 plugins in `.opencode/plugins/`
- Both tools in `.opencode/tools/`
- `AGENTS.md`, `.opencode/AGENTS_INDEX.md`, `.opencode/docs/agent-tools-policy.md`
- `.opencode/scripts/audit-agents.mjs`
- `.opencode/icm.jsonc`
- `.opencode/package.json` and dependency tree

## Non-Goals
- Rewriting the entire agent system from scratch
- Changing the team workflow model or role definitions
- Adding new agents, plugins, or tools
- Modifying skills content
- Performance optimization beyond memory leak fixes
- Upstream OpenCode SDK changes

## Relevant Files
- `.opencode/agents/team-lead.md` — Has extra tools not in 7-key policy (read, list, grep, question, agent-browser); mode says `primary` but opencode.json says `mode: "all"`
- `.opencode/agents/product-manager.md` — Has extra tools (read, list, grep, question, agent-browser); `todoread: false, todowrite: false` contradicts opencode.json which has `"todoread": "allow", "todowrite": "allow"`
- `.opencode/agents/senior-engineer.md` — Has extra tools (read, list, grep, question, agent-browser); `todoread: false, todowrite: false` contradicts opencode.json
- `.opencode/agents/staff-engineer.md` — Has `bash: false` but permission.bash is absent (no dead config, but inconsistent with policy doc which shows bash entries for review agents); `todowrite: false` contradicts opencode.json
- `.opencode/agents/qa-engineer.md` — Has extra tools (read, list, grep, question, agent-browser); `todoread: false, todowrite: false` contradicts opencode.json; `webfetch: true, websearch: true` in frontmatter but opencode.json has `"webfetch": "deny", "websearch": "deny"`
- `.opencode/agents/ux-designer.md` — Has extra tools (read, list, grep, question, agent-browser); `todoread: false, todowrite: false` contradicts opencode.json
- `opencode.json` — Central config with agent permission blocks that may conflict with frontmatter
- `.opencode/plugins/icm.ts` — 1045-line ICM plugin with persistent state maps that never shrink (potential memory leak)
- `.opencode/plugins/notifications.ts` — Module-level `sessions` Map that only deletes on session switch or error (potential leak)
- `.opencode/plugins/post-stop-detector.ts` — Captures full filesystem snapshots with SHA-256 hashes of every file (massive memory spike)
- `.opencode/plugins/td-enforcer.ts` — `sessionFiles` Map, `writeCallFiles` Map, `lastSeenReviews` Set — potential unbounded growth
- `.opencode/plugins/logging.ts` — Synchronous JSON.stringify on every event (CPU pressure, not memory)
- `.opencode/plugins/security.ts` — Lightweight, unlikely memory issue
- `.opencode/tools/td.ts` — Runs `td version` on every single invocation (unnecessary overhead)
- `.opencode/tools/agent-browser.ts` — Runs `agent-browser --version` on every invocation (unnecessary overhead)
- `.opencode/docs/agent-tools-policy.md` — Defines 7-key policy but agents have 12+ keys
- `.opencode/scripts/audit-agents.mjs` — Does not validate tool key count or detect extra keys

## Proposed Approach

### Area 1: Agent Setup Issues

**Finding 1.1: Frontmatter vs opencode.json mode mismatch**
- `team-lead.md` frontmatter says `mode: primary` but `opencode.json` says `"mode": "all"`. These are different values. Need to determine which is canonical.

**Finding 1.2: Extra tool keys beyond the 7-key policy**
- The `agent-tools-policy.md` mandates exactly 7 tool keys: `edit, write, skill, td, webfetch, todowrite, bash`.
- Every agent declares 12+ keys including: `read, list, grep, question, agent-browser, websearch, todoread`.
- These extra keys are not in the policy document. Either the policy needs updating or the agents need trimming.

**Finding 1.3: Frontmatter/opencode.json tool permission conflicts**
- `product-manager.md`: `todoread: false, todowrite: false` but `opencode.json` has `"todoread": "allow", "todowrite": "allow"`.
- `senior-engineer.md`: `todoread: false, todowrite: false` but `opencode.json` has `"todoread": "allow", "todowrite": "allow"`.
- `qa-engineer.md`: `webfetch: true, websearch: true` in frontmatter but `opencode.json` has `"webfetch": "deny", "websearch": "deny"`.
- `ux-designer.md`: `todoread: false, todowrite: false` but `opencode.json` has `"todoread": "allow", "todowrite": "allow"`.
- `staff-engineer.md`: `todowrite: false` but `opencode.json` has `"todowrite": "allow"`.
- **Critical question**: Which takes precedence — frontmatter or opencode.json? This determines whether agents actually have the capabilities they appear to have.

**Finding 1.4: AGENTS_INDEX.md references use relative paths**
- Index uses `agents/staff-engineer.md` (relative to `.opencode/`) but the audit script looks for `.opencode/agents/staff-engineer.md` (relative to repo root). The audit script's `collectRefs` function uses regex `/\.opencode\/agents\/[A-Za-z0-9_./-]+\.md/g` which won't match the relative paths in AGENTS_INDEX.md.

### Area 2: Permission Issues

**Finding 2.1: team-lead has `bash: true` in frontmatter but opencode.json has `"bash": { "*": "deny" }`**
- The frontmatter enables bash, but the opencode.json permission block denies all bash. The frontmatter also has specific allows for `ls*`, `cat*`, `grep*`. Need to verify which layer wins.

**Finding 2.2: qa-engineer permission block is the most complex and potentially over-permissive**
- Has `external_directory: "~/Development/.worktrees/**": allow` — this grants access outside the repo.
- Has `"find*": allow` which could be used to enumerate sensitive directories.
- Has `"npx playwright*": ask` and `"npx vitest*": ask` — reasonable but should be documented.

**Finding 2.3: senior-engineer has `"gh*": ask` which is very broad**
- This allows any GitHub CLI command with user confirmation, including potentially destructive operations like `gh repo delete`.

**Finding 2.4: Global permission `"*": "ask"` means any unlisted tool defaults to ask**
- This is reasonable but means new tools added by plugins get `ask` by default, not `deny`.

### Area 3: TD Task Usage Issues

**Finding 3.1: TD tool runs `td version` on every invocation**
- Line 209 of `td.ts`: `const version = await runTD(["version"])` — this spawns a subprocess on every single tool call. For a session with 100+ TD calls, this is 100+ unnecessary process spawns.

**Finding 3.2: TD enforcer calls `td status --json` on every write tool invocation**
- `td-enforcer.ts` line 410: `const status = await getTDStatus()` in `tool.execute.before` for every write tool. This spawns a subprocess for every file edit. Combined with `tool.execute.after` also calling `getTDStatus()`, that's 2 subprocess spawns per file edit.

**Finding 3.3: TD enforcer auto-links and auto-logs on every file write**
- Lines 449-450: `await linkFileToTask(task, filePath)` and `await logToTask(...)` — each spawns a subprocess. For a session editing 50 files, that's 100+ additional subprocess spawns just for tracking.

**Finding 3.4: AGENTS.md TD rules reference `TD(action: ...)` syntax but agents use `td` tool**
- The AGENTS.md says "run `TD(action: "status")`" but the actual tool is invoked as `td` in the tool registry. This is a documentation/naming inconsistency that could confuse agents.

### Area 4: Memory Leak Investigation (18GB RAM)

**Finding 4.1: post-stop-detector.ts — Full filesystem snapshot in memory**
- `captureSnapshot()` (line 90) reads EVERY file in the repo (up to 10MB each), computes SHA-256 hashes, and stores all `FileSnapshot` objects in an array. For a large repo with thousands of files, this could easily consume gigabytes.
- The snapshot is stored as JSON on disk AND kept in memory for the 30-second detection window.
- `detectChanges()` (line 154) captures a SECOND full snapshot and creates Maps from both, doubling memory usage during comparison.

**Finding 4.2: ICM plugin — knownToolNames Map grows unboundedly within a session**
- `persistentState.knownToolNames` (line 676) is populated on every `messages.transform` call but only cleaned up for `toolPruneSet`, not for `knownToolNames` itself. Over a long session with many tool calls, this map grows without bound.

**Finding 4.3: ICM plugin — buildToolIndex rebuilds from scratch every invocation**
- `buildToolIndex()` (line 339) iterates ALL messages and ALL parts on every single `messages.transform` call. For a long session with thousands of messages, this is O(n²) over the session lifetime.

**Finding 4.4: notifications.ts — sessions Map only cleaned on switch**
- The `sessions` Map (line 21) stores `SessionContext` objects. Old sessions are only deleted when a new session is created (line 155-157). If sessions are created without switching, the map grows.
- `stats.uniqueTools` array grows unboundedly per session.

**Finding 4.5: td-enforcer.ts — sessionFiles Map potential leak**
- `sessionFiles` Map (line 272) stores Sets of file paths per session. Cleaned on `session.idle` and `session.error`, but if neither event fires (e.g., process crash), the map leaks.
- `writeCallFiles` Map (line 273) stores file arrays per call ID. Cleaned in `tool.execute.after`, but if `after` hook doesn't fire (tool crash), entries leak.

**Finding 4.6: agent-browser.ts — version check on every invocation**
- Line 425: `const versionCheck = await runAgentBrowser(["--version"])` spawns a subprocess on every tool call. Not a memory leak per se, but contributes to process table pressure.

**Finding 4.7: Bun subprocess accumulation**
- Both tools (`td.ts`, `agent-browser.ts`) use `Bun.$` template literals to spawn subprocesses. If Bun doesn't properly clean up child process handles, this could accumulate file descriptors and memory over hundreds of invocations.

## Risks And Assumptions
- **Risk**: Changing frontmatter tool keys may break agent behavior if OpenCode uses frontmatter as the source of truth for tool availability.
- **Risk**: The precedence model between `opencode.json` and agent frontmatter is not documented — changes to one may be silently overridden by the other.
- **Assumption**: OpenCode loads plugins at startup and keeps them in memory for the session lifetime — plugin state persists across all tool calls.
- **Assumption**: The 18GB RAM usage is from the OpenCode process itself, not from spawned subprocesses (which would have their own memory).
- **Risk**: Fixing the post-stop-detector snapshot approach may reduce its detection accuracy.
- **Open question**: Does OpenCode's SDK provide any memory profiling or heap snapshot capability?
- **Open question**: What is the typical session length and tool call count when 18GB is observed?
- **Open question**: Is the `mode: "all"` in opencode.json a valid mode, or should it be `"primary"`?

## Implementation Phases

### Phase 1: Audit and Evidence Collection
- Owner: `senior-engineer`
- Outcomes:
  - Run `audit-agents.mjs --strict --format json` and capture baseline findings
  - Profile memory usage of a simulated long session (if possible)
  - Document the actual precedence behavior between frontmatter and opencode.json
  - Produce a findings report with severity ratings

### Phase 2: Agent Config Alignment
- Owner: `senior-engineer`
- Outcomes:
  - Resolve frontmatter vs opencode.json conflicts (pick one source of truth per setting)
  - Update `agent-tools-policy.md` to reflect actual tool key set (12 keys, not 7)
  - Fix mode mismatch for team-lead
  - Fix qa-engineer webfetch/websearch contradiction
  - Fix todoread/todowrite contradictions across all agents

### Phase 3: Permission Hardening
- Owner: `senior-engineer`
- Outcomes:
  - Remove or restrict `external_directory` access for qa-engineer
  - Narrow `"gh*": ask` for senior-engineer to specific safe commands
  - Audit and document the effective permission for each agent (merged frontmatter + opencode.json)
  - Add missing permission documentation to agent-tools-policy.md

### Phase 4: Memory Leak Fixes
- Owner: `senior-engineer`
- Outcomes:
  - **post-stop-detector.ts**: Replace full-file SHA-256 with stat-only comparison (mtime + size) to eliminate multi-GB memory spikes
  - **ICM plugin**: Add cleanup for `knownToolNames` Map (prune entries not in current message stream)
  - **ICM plugin**: Consider caching `buildToolIndex` results or using incremental updates
  - **td.ts**: Cache `td version` result for the session instead of checking every call
  - **agent-browser.ts**: Cache `--version` result for the session
  - **td-enforcer.ts**: Add TTL or max-size bounds to `sessionFiles` and `writeCallFiles` Maps
  - **notifications.ts**: Add max session count or TTL cleanup to `sessions` Map

### Phase 5: TD Workflow Hardening
- Owner: `senior-engineer`
- Outcomes:
  - Reduce subprocess spawns in td-enforcer (batch or cache `td status --json`)
  - Fix audit-agents.mjs to detect AGENTS_INDEX.md relative path references correctly
  - Update audit-agents.mjs to validate tool key count against policy
  - Ensure AGENTS.md TD rule syntax matches actual tool invocation patterns

### Phase 6: Validation
- Owner: `qa-engineer`
- Outcomes:
  - Run updated audit-agents.mjs and confirm zero critical/high findings
  - Verify each agent can still perform its role after config changes
  - Measure memory usage improvement with fixed plugins
  - Validate TD enforcement still blocks writes without active tasks

## Team Orchestration
- Use the existing OpenCode delivery roles deliberately.
- Prefer `product-manager` for planning refinement, `staff-engineer` for technical review, `senior-engineer` for implementation, and `qa-engineer` for validation.
- Use `todowrite` to track execution and `task` to delegate meaningful stages when the plan is executed.

### Team Members
- `team-lead` - coordinates stages, approvals, and handoffs; sequences the 6 phases
- `product-manager` - refines scope, phases, and acceptance criteria; owns this plan
- `staff-engineer` - reviews architecture changes (especially memory fixes and permission model); reviews Phase 2-5 diffs
- `senior-engineer` - implements Phases 1-5
- `qa-engineer` - validates Phase 6; runs audit script and behavioral checks

## Step By Step Tasks

### 1. Baseline Audit Run
- Owner: `senior-engineer`
- Depends On: none
- Parallel: false
- Deliverables:
  - JSON output from `node .opencode/scripts/audit-agents.mjs --strict --format json`
  - Document of frontmatter vs opencode.json precedence behavior (test with a known conflict)
  - Memory baseline measurement if tooling available

### 2. Resolve Config Source-of-Truth
- Owner: `staff-engineer` (decision) → `senior-engineer` (implementation)
- Depends On: Task 1
- Parallel: false
- Deliverables:
  - Decision document: which layer (frontmatter vs opencode.json) is authoritative for each setting type
  - Updated `agent-tools-policy.md` reflecting the actual 12-key tool set
  - Updated AGENTS.md if needed

### 3. Fix Agent Frontmatter Conflicts
- Owner: `senior-engineer`
- Depends On: Task 2
- Parallel: false
- Deliverables:
  - Updated `team-lead.md` — fix mode value
  - Updated `product-manager.md` — fix todoread/todowrite
  - Updated `senior-engineer.md` — fix todoread/todowrite
  - Updated `staff-engineer.md` — fix todowrite
  - Updated `qa-engineer.md` — fix webfetch/websearch contradiction
  - Updated `ux-designer.md` — fix todoread/todowrite

### 4. Fix opencode.json Permission Conflicts
- Owner: `senior-engineer`
- Depends On: Task 2
- Parallel: true (with Task 3)
- Deliverables:
  - Updated `opencode.json` agent blocks aligned with frontmatter decisions
  - Narrowed `"gh*"` permission for senior-engineer
  - Documented effective permissions per agent

### 5. Fix Memory Leaks in Plugins
- Owner: `senior-engineer`
- Depends On: Task 1 (for baseline)
- Parallel: true (with Tasks 3-4)
- Deliverables:
  - Updated `post-stop-detector.ts` — stat-only snapshots instead of full-file hashing
  - Updated `icm.ts` — knownToolNames cleanup, consider incremental buildToolIndex
  - Updated `td.ts` — cached version check
  - Updated `agent-browser.ts` — cached version check
  - Updated `td-enforcer.ts` — bounded Maps with cleanup
  - Updated `notifications.ts` — bounded sessions Map

### 6. Fix TD Workflow Issues
- Owner: `senior-engineer`
- Depends On: Task 1
- Parallel: true (with Tasks 3-5)
- Deliverables:
  - Updated `td-enforcer.ts` — cached/batched `td status --json` calls
  - Updated `audit-agents.mjs` — fix relative path detection for AGENTS_INDEX.md, add tool key count validation

### 7. Architecture Review
- Owner: `staff-engineer`
- Depends On: Tasks 3, 4, 5, 6
- Parallel: false
- Deliverables:
  - Review of all changed files
  - Approval or conditional approval with specific conditions
  - Risk assessment of memory fix approaches

### 8. Validation and QA
- Owner: `qa-engineer`
- Depends On: Task 7 (approval)
- Parallel: false
- Deliverables:
  - Audit script results (zero critical/high)
  - Agent behavioral verification (each agent can still do its job)
  - Memory usage comparison (before/after)
  - TD enforcement verification
  - Final pass/fail report

## Acceptance Criteria
- `node .opencode/scripts/audit-agents.mjs --strict` exits with code 0 (no critical or high findings)
- All 6 agent frontmatter files have consistent tool declarations matching the updated policy
- No contradictions between frontmatter tool booleans and opencode.json permission values
- `post-stop-detector.ts` no longer reads file contents for snapshot comparison (stat-only)
- `td.ts` and `agent-browser.ts` cache version checks (at most 1 subprocess per session)
- `knownToolNames` Map in ICM plugin has cleanup logic preventing unbounded growth
- `td-enforcer.ts` caches `td status --json` with a short TTL (e.g., 2 seconds) to reduce subprocess spawns
- Memory usage during a 200+ tool-call session stays under 4GB (down from 18GB)
- TD enforcement still blocks file writes when no active task exists
- Each agent role can still be invoked and performs its documented function

## Validation Commands
- `node .opencode/scripts/audit-agents.mjs --strict --format json` — validates agent config consistency
- `node .opencode/scripts/audit-agents.mjs --strict` — validates with markdown output and exit code
- `grep -r "todoread: false" .opencode/agents/` — should return no results after fix (or should match policy)
- `grep -r "td version" .opencode/tools/` — verify version check is cached
- `grep -r "agent-browser.*--version" .opencode/tools/` — verify version check is cached
- `grep -r "readFile" .opencode/plugins/post-stop-detector.ts` — should not appear in snapshot logic after fix
- `grep -c "getTDStatus" .opencode/plugins/td-enforcer.ts` — verify reduced call count through caching

## Notes
- The 18GB memory issue is most likely caused by `post-stop-detector.ts` reading every file in the repo into memory for SHA-256 hashing. A repo with 5000 files averaging 100KB each would consume ~500MB per snapshot, and with two snapshots during detection that's 1GB. But if the plugin fires multiple times without cleanup, or if the repo has large files near the 10MB limit, memory could spike dramatically.
- The ICM plugin's `buildToolIndex` running on every `messages.transform` is O(n) per call but O(n²) over a session, which could contribute to memory pressure through garbage collection churn even if peak usage is bounded.
- The frontmatter vs opencode.json precedence question is the single most important decision in this plan. All agent config fixes depend on understanding which layer wins. This should be resolved first, potentially by reading OpenCode SDK source or testing empirically.
- The `mode: "all"` value in opencode.json for team-lead is not in the `VALID_MODES` set in audit-agents.mjs (which only knows `primary` and `subagent`). This suggests either the audit script is incomplete or `"all"` is an opencode.json-specific mode that maps to `primary` in frontmatter.
- Consider adding a memory monitoring plugin or periodic heap snapshot capability for ongoing observability.
- The sync-opencode-config.sh script will propagate all these fixes to downstream repos, so getting them right in the template is high-leverage.
