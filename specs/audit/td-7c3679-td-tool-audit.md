# TD Tool & TD-Enforcer Plugin Audit Report

**Task:** td-7c3679  
**Date:** 2026-03-05  
**Auditor:** senior-engineer (ses_508af8)

---

## Executive Summary

The TD tool (`td.ts`) correctly implements all 31 declared actions with proper CLI argument construction for the vast majority of cases. However, **two concrete bugs** were identified: (1) the `files` action **ignores the `files` array parameter** and only shows linked files rather than linking new ones; (2) the `log` action does not accept a `task` parameter for targeting a specific issue, relying solely on the focused task. The TD-enforcer plugin is architecturally sound with a **fail-safe design**: both `permission.ask` and `tool.execute.before` hooks block writes when `td status` returns null (CLI failure, DB error) — this is correct fail-closed behavior, though the two hooks use different blocking mechanisms (ask-prompt vs throw) creating a minor UX inconsistency. AGENTS.md Rules 2–4 are **prose-only** with zero enforcement mechanism. The td-workflow skill is largely accurate and all prescribed commands map correctly to the tool implementation.

---

## Audit Scope

| File | Lines | Role |
|------|-------|------|
| `.opencode/tools/td.ts` | 596 | Primary subject — TD MCP tool |
| `.opencode/plugins/td-enforcer.ts` | 524 | Primary subject — write-block enforcer |
| `AGENTS.md` | 31 | Mandatory rules source |
| `.opencode/skills/td-workflow/SKILL.md` | 68 | Cross-reference |
| `.opencode/docs/agent-team-workflow.md` | 605 | TD command usage validation |
| `.opencode/commands/plan.md` | 34 | Command-level TD usage |
| `.opencode/commands/build.md` | 59 | Command-level TD usage |

---

## Findings Table

| ID | Severity | Component | Dimension | Finding | Recommended Fix |
|----|----------|-----------|-----------|---------|-----------------|
| F-01 | P0 | td.ts | D1 | `files` action calls `td files <task>` (list only) — ignores `files` array param, cannot link files | Add separate `link` path when `input.files` is provided; or document that `files` is read-only and rename to `list-files` |
| F-02 | P0 | td.ts | D1 | `log` action has no `task` targeting — always logs to focused task; if no task is focused, CLI silently fails or errors with no user-facing message | Add `if (input.task) args.splice(1, 0, input.task)` to support `td log <id> <message>` |
| F-03 | P2 | td-enforcer.ts | D2 | `permission.ask` hook: if `getTDStatus()` returns `null` (CLI failure, DB error), `status && hasActiveTask(status)` is falsy → `output.status = "ask"` fires → writes are **blocked** (fail-safe). `tool.execute.before` also blocks on null status but throws an error instead of prompting. Both hooks block correctly, but via different UX mechanisms (ask-prompt vs hard throw) | Unify null-status handling: both hooks should use the same blocking mechanism for consistent UX when TD CLI is unavailable |
| F-04 | P2 | td-enforcer.ts | D2 | `tool.execute.before` hook: on null status it throws `"No active TD task"` — technically correct (blocks writes) but the error message is misleading when the real cause is CLI unavailability, not a missing task | Improve error message: distinguish between "no active task" and "TD CLI unavailable" by checking `status === null` separately |
| F-05 | P1 | td.ts | D1 | `tree` action with `childIssue` uses `td update <child> --parent <task>` — this is a workaround, not a native tree operation; `td tree` has no `add-child` subcommand | Document this as the correct approach (it works), or add a comment explaining the workaround |
| F-06 | P1 | AGENTS.md | D3 | Rules 2, 3, 4 are prose-only — no enforcement mechanism exists for session-start `usage`, sub-agent TD text injection, or handoff before context end | Add enforcer hooks for `session.created` (Rule 2) and `session.idle`/`session.error` (Rule 4); Rule 3 requires LLM-level compliance |
| F-07 | P1 | td-enforcer.ts | D2 | `session.idle` event fires handoff reminder toast but does NOT block or enforce handoff — Rule 4 remains prose-only | Consider logging a structured warning to JSONL and/or blocking session close if no handoff exists |
| F-08 | P1 | td.ts | D4 | `approve` and `reject` use `--reason` flag — CLI primary flag is `-m`/`--reason` but also accepts `--message` as alias. The tool passes `--reason` which is correct. However, the `message` parameter description says "reason for approve/reject" — **no bug** but the parameter name mismatch (`message` → `--reason`) is confusing | Rename MCP param from `message` to `reason` for approve/reject, or add a note in description |
| F-09 | P2 | td.ts | D1 | `handoff` action: `task` is optional — if omitted and no task is focused, `td handoff` will fail with CLI error. The tool returns `result.stderr` which is correct, but the error message from CLI may be cryptic | Add validation: if no `input.task` and no focused task detectable, return a clear message |
| F-10 | P2 | td.ts | D1 | `log` action: `logType` maps to `--decision`, `--blocker`, etc. as boolean flags. CLI also supports `-t/--type <value>` string form. The boolean flag approach is correct but only supports the 5 declared types; `orchestration` type (valid per CLI) is not exposed | Add `orchestration` to `logType` enum or use `--type` string form for extensibility |
| F-11 | P2 | td-enforcer.ts | D2 | `TRACKED_EXTENSIONS` missing: `.env` (intentional — security plugin handles it), `.lock` (package-lock.json, yarn.lock), `.xml`, `.csv`, `.txt`, `.tf` (Terraform), `.hcl`, `.dockerfile` | Add `.lock`, `.xml`, `.tf`, `.hcl` to tracked extensions for completeness |
| F-12 | P3 | td-enforcer.ts | D2 | `EXCLUDED_DIR_SEGMENTS` uses multi-segment strings `".opencode/logs"` and `".opencode/data"` — the check `filePath.includes(\`/${segment}/\`)` correctly matches these paths (e.g. `/.opencode/logs/` is found in `/repo/.opencode/logs/td_enforcer.jsonl`). Logic is correct but the mixed single-segment / multi-segment entries in one Set is non-obvious and could confuse future maintainers | Add a comment in the source explaining that multi-segment entries are intentional and work correctly with the `includes()` check |
| F-13 | P2 | agent-team-workflow.md | D5 | Uses `td done <id>` in 5 places (lines 196, 331, 516) — `td done` is an alias for `td close` (admin closure), NOT the correct completion flow. Correct flow is `td review` → `td approve` | Replace all `td done` references with `td review <id>` + `td approve <id>` |
| F-14 | P2 | agent-team-workflow.md | D5 | Uses `td block <id> --reason "..."` (lines 237, 347, 564, 584) — CLI `td block` accepts `--reason` flag. This is correct. However `td unblock <id> "reason"` (line 249) passes reason as positional arg — CLI uses `--reason` flag | Fix `td unblock td-abc123 "reason"` → `td unblock td-abc123 --reason "reason"` |
| F-15 | P2 | td.ts | D1 | `epic` action: does not support `--minor`, `--points`, `--acceptance`, `--type` params (epic create doesn't accept these). The tool correctly omits them, but the shared `minor`, `points`, `acceptance` params in the schema could mislead callers | Add a note in the `epic` action description that these params are ignored |
| F-16 | P2 | td-workflow SKILL.md | D5 | Skill prescribes `dep list` as a named sub-action (line 59: "inspect with `dep list`") — `dep list` is NOT a valid sub-action in the tool schema (`depAction` enum: `add`, `list`, `blocking`). Wait — `list` IS in the enum. But CLI `td dep --help` shows no `list` subcommand; `td dep <issue>` (no sub-action) is the list form | The tool schema has `depAction: "list"` which maps to `td dep <task>` (correct). Skill text is fine. But tool description says `dep (depAction: add/list/blocking)` — `list` maps to bare `td dep <task>`, which is correct behavior |
| F-17 | P3 | td.ts | D1 | `usage` action: `newSession: false` (explicit false) still passes no `--new-session` flag — correct. But `newSession: undefined` and `newSession: false` are treated identically. Minor: no issue | No action needed |
| F-18 | P3 | td.ts | D1 | `create` action: `points: 0` would be falsy in JS (`if (input.points)`) and would silently drop the `--points 0` flag. However, 0 is not a valid Fibonacci story point, so this is acceptable | Add comment noting 0 is intentionally excluded |
| F-19 | P3 | td-enforcer.ts | D2 | `extractReviewTasks` handles both `status.inReview` (old shape) and `status.in_review.reviewable_by_you` (new shape) — dual-shape handling is good defensive code but the old shape may never fire in current CLI version | No action needed — defensive code is appropriate |
| F-20 | P3 | td.ts | D1 | `ws` action: `wsAction: "handoff"` is the `else` branch — any unrecognized `wsAction` value would silently execute `ws handoff`. The enum constraint prevents this at schema level but the runtime `else` is fragile | Add explicit `else if (input.wsAction === "handoff")` with a final `else` returning an error |

---

## Dimension Analysis

### 1. TD Tool Action Coverage (31 Actions)

| Action | CLI Construction | Error Handling | Required Params Validated | Edge Cases | Status |
|--------|-----------------|----------------|--------------------------|------------|--------|
| `status` | `td status --json` | ✅ stderr fallback | N/A | None | ✅ OK |
| `whoami` | `td whoami --json` | ✅ stderr fallback | N/A | None | ✅ OK |
| `start` | `td start <task>` | ✅ stderr fallback | ✅ task required | None | ✅ OK |
| `focus` | `td focus <task>` | ✅ stderr fallback | ✅ task required | None | ✅ OK |
| `link` | `td link <task> <files...>` | ✅ stderr fallback | ✅ task + files required | Absolute path → relative conversion via `context.worktree` | ✅ OK |
| `log` | `td log [--<type>] <message>` | ✅ stderr fallback | ✅ message required | **No task targeting** — always logs to focused task; `td log <id> <message>` form not supported | ⚠️ F-02 |
| `review` | `td review <task>` | ✅ stderr fallback | ✅ task required | None | ✅ OK |
| `approve` | `td approve [<task>] [--reason <msg>] --json` | ✅ stderr fallback | None (task optional) | `--reason` is correct primary flag; `--message` is alias — works | ✅ OK |
| `reject` | `td reject [<task>] [--reason <msg>] --json` | ✅ stderr fallback | None (task optional) | Same as approve | ✅ OK |
| `handoff` | `td handoff [<task>] [--done] [--remaining] [--decision] [--uncertain]` | ✅ stderr fallback | None (all optional) | If no task focused and no `task` param, CLI may error cryptically | ⚠️ F-09 |
| `usage` | `td usage [--new-session]` | ✅ stderr fallback | N/A | `newSession: false` correctly omits flag | ✅ OK |
| `create` | `td create <title> [flags...]` | ✅ stderr fallback | ✅ task (title) required | `points: 0` silently dropped (acceptable) | ✅ OK |
| `epic` | `td epic create <title> [flags...]` | ✅ stderr fallback | ✅ task (title) required | `minor`/`points`/`acceptance` params silently ignored (correct — epic create doesn't support them) | ✅ OK |
| `tree` | `td tree <task>` OR `td update <child> --parent <task>` | ✅ stderr fallback | ✅ task required | `childIssue` path uses `update --parent` workaround — works but undocumented | ⚠️ F-05 |
| `dep` | `td dep add <task> <target>` / `td dep <task>` / `td dep <task> --blocking` | ✅ stderr fallback | ✅ task required; targetIssue required for add | `blocking` → `td dep <task> --blocking` is **correct** per CLI | ✅ OK |
| `ws` | `td ws <sub> [args]` | ✅ stderr fallback | ✅ wsAction required; wsName/issueIds/message validated per sub-action | `else` branch catches `handoff` but also any unknown wsAction | ⚠️ F-20 |
| `query` | `td query <query>` | ✅ stderr fallback | ✅ query required | None | ✅ OK |
| `search` | `td search <query>` | ✅ stderr fallback | ✅ query required | None | ✅ OK |
| `critical-path` | `td critical-path` | ✅ stderr fallback | N/A | None | ✅ OK |
| `next` | `td next` | ✅ stderr fallback | N/A | None | ✅ OK |
| `ready` | `td ready` | ✅ stderr fallback | N/A | None | ✅ OK |
| `blocked` | `td blocked` | ✅ stderr fallback | N/A | None | ✅ OK |
| `in-review` | `td in-review` | ✅ stderr fallback | N/A | None | ✅ OK |
| `reviewable` | `td reviewable` | ✅ stderr fallback | N/A | None | ✅ OK |
| `context` | `td context <task>` | ✅ stderr fallback | ✅ task required | CLI alias: `show`/`view`/`get` — `context` is valid | ✅ OK |
| `comment` | `td comment <task> <text>` | ✅ stderr fallback | ✅ task + commentText required | None | ✅ OK |
| `update` | `td update <task> [--title] [--description] [--priority] [--type] [--labels]` | ✅ stderr fallback | ✅ task required | `acceptance`, `dependsOn`, `blocks`, `points`, `parent` fields from `update` CLI are NOT exposed in the tool's `update` action | ⚠️ Minor gap |
| `files` | `td files <task>` | ✅ stderr fallback | ✅ task required | **Ignores `files` array param** — only lists linked files, cannot link new ones via this action | ❌ F-01 |
| `unlink` | `td unlink <task> <files...>` | ✅ stderr fallback | ✅ task + files required | Absolute path → relative conversion (same as `link`) | ✅ OK |
| `block-issue` | `td block <task>` | ✅ stderr fallback | ✅ task required | No `--reason` flag exposed — CLI supports it | ⚠️ Minor gap |
| `unblock-issue` | `td unblock <task>` | ✅ stderr fallback | ✅ task required | No `--reason` flag exposed — CLI supports it | ⚠️ Minor gap |

#### Broken/Incorrect Actions Summary

**P0 — Broken:**
- **`files`**: The action name implies "link files to task" (matching the `files` parameter in the schema), but the implementation calls `td files <task>` which only **lists** already-linked files. The `files` array parameter is completely ignored. An agent calling `TD(action: "files", task: "td-xxx", files: ["src/foo.ts"])` expecting to link files will silently get a file listing instead.

**P1 — Silent incorrect behavior:**
- **`log`**: No `task` targeting. `td log <id> <message>` is a valid CLI form (per `td log --help`), but the tool always logs to the focused task. If an agent passes `task: "td-xxx"` to `log`, it is silently ignored.

---

### 2. TD-Enforcer Plugin Hook Analysis

#### `permission.ask` Hook (lines 387–398)

```
"permission.ask": async (input, output) => {
  if (!input.type || !WRITE_PERMISSION_TYPES.has(input.type)) return
  const status = await getTDStatus()
  if (status && hasActiveTask(status)) return   // ← allow if active task
  output.status = "ask"                          // ← block otherwise
}
```

**Analysis:**
- **What triggers "active task"**: `hasActiveTask()` checks `extractTaskIdentifier()` (looks at `status.focus.key/id`, `status.focused.issue.key/id`, `status.inProgress[0].key/id`) AND `status.focused.issue` object presence. This covers both `focus`-ed and `start`-ed tasks.
- **`start` without `focus`**: A `start`-ed task appears in `inProgress` array — `extractTaskIdentifier` checks `inProgress[0]` — so writes ARE allowed. ✅
- **`in_review` task**: A task in `in_review` status is NOT in `inProgress` and NOT in `focused`. If the only task is `in_review`, `hasActiveTask()` returns `false` → writes are **blocked**. This may be unexpected if a reviewer is making notes.
- **Null-status behavior (F-03)**: If `getTDStatus()` returns `null` (CLI failure, DB error, td not installed), the condition `if (status && hasActiveTask(status))` evaluates to `false` (because `null && X` is falsy) → we do NOT return early → `output.status = "ask"` fires → **writes are blocked**. This is correct **fail-safe / fail-closed** behavior. The hook does NOT silently allow writes on CLI failure.
- **UX inconsistency (F-03/F-04)**: `permission.ask` blocks via `output.status = "ask"` (prompts the user), while `tool.execute.before` blocks via `throw new Error(...)`. Both block writes on null status, but the error message in `tool.execute.before` says "No active TD task" — which is misleading when the real cause is CLI unavailability. These two hooks should be unified for consistent UX.

#### `tool.execute.before` Hook (lines 400–422)

```
"tool.execute.before": async (input, output) => {
  if (!WRITE_TOOLS.has(input.tool)) return
  // extract file paths from args
  // check status
  if (status && hasActiveTask(status)) {
    writeCallFiles.set(input.callID, files)
    return
  }
  writeCallFiles.delete(input.callID)
  throw new Error("No active TD task...")
}
```

**Tools intercepted**: `write`, `edit`, `patch`, `multiedit`, `apply_patch` — matches `WRITE_TOOLS` set.

**Read operations pass through**: `Glob`, `Grep`, `Read`, `WebFetch`, `Bash` (read-only) are not in `WRITE_TOOLS` — correctly pass through.

**File path extraction**: Handles `filePath`, `path`, and `patchText` (via `extractPathsFromPatchText`). Does NOT handle `content` field or other tool-specific arg names. For the 5 write tools, `filePath` and `path` cover the standard cases.

**Edge case**: `Bash` tool with write operations (e.g., `echo > file`) is NOT intercepted — only MCP write tools are blocked. Shell-level writes bypass the enforcer entirely.

#### `tool.execute.after` Hook (lines 424–469)

**File tracking logic:**
1. Gets current TD status
2. Extracts task identifier
3. Collects candidate paths from `output.metadata.filePath`, `output.metadata.path`, and `writeCallFiles` map
4. For each path: strips directory prefix, checks `shouldTrackFile()`, calls `td link` and `td log`

**`TRACKED_EXTENSIONS` analysis:**

| Category | Tracked | Missing |
|----------|---------|---------|
| TypeScript/JS | `.ts`, `.tsx`, `.js`, `.jsx` | `.mts`, `.cts`, `.mjs`, `.cjs` |
| Systems | `.go`, `.rs`, `.c`, `.cpp`, `.h`, `.hpp` | `.zig`, `.nim` |
| JVM | `.java`, `.kt` | `.scala`, `.groovy`, `.clj` |
| Scripting | `.py`, `.rb`, `.php`, `.sh` | `.bash`, `.zsh`, `.fish`, `.ps1`, `.lua`, `.r` |
| Frontend | `.vue`, `.svelte`, `.css`, `.scss`, `.html` | `.less`, `.sass`, `.astro` |
| Config | `.yaml`, `.yml`, `.toml`, `.json` | `.ini`, `.cfg`, `.env` (intentional), `.lock` |
| Data/Schema | `.sql`, `.graphql`, `.proto` | `.avro`, `.thrift` |
| Docs | `.md` | `.mdx`, `.rst`, `.adoc` |
| Mobile | `.swift` | `.dart`, `.m`, `.mm` |

**`EXCLUDED_DIR_SEGMENTS` analysis:**

| Segment | Correct? | Notes |
|---------|----------|-------|
| `node_modules` | ✅ | Standard |
| `dist`, `build`, `out` | ✅ | Build outputs |
| `.git` | ✅ | Git internals |
| `target` | ✅ | Rust/Java build |
| `vendor` | ✅ | Go vendor |
| `.next`, `.nuxt`, `.svelte-kit` | ✅ | Framework outputs |
| `coverage` | ✅ | Test coverage |
| `__pycache__` | ✅ | Python cache |
| `.opencode/logs` | ✅ | Multi-segment string — works correctly (see F-12 note) |
| `.opencode/data` | ✅ | Multi-segment string — works correctly (see F-12 note) |

**F-12 Note (P3 — cosmetic)**: The `shouldTrackFile` function checks:
```typescript
if (filePath.includes(`/${segment}/`) || filePath.endsWith(`/${segment}`))
```
For segment `".opencode/logs"`, this becomes:
```
filePath.includes("/.opencode/logs/") || filePath.endsWith("/.opencode/logs")
```
This **works correctly** — the check `filePath.includes("/.opencode/logs/")` matches paths like `/repo/.opencode/logs/td_enforcer.jsonl`. The multi-segment entries are valid and effective. The only concern is maintainability: the `EXCLUDED_DIR_SEGMENTS` Set mixes single-segment entries (e.g. `"node_modules"`) with multi-segment entries (e.g. `".opencode/logs"`), which is non-obvious. A future maintainer adding a single-segment entry like `"logs"` would accidentally exclude all `logs/` directories project-wide. A comment explaining the multi-segment intent would prevent this confusion.

#### `event` Hook (lines 471–520)

**Events handled:**
- `session.created` → starts DB watcher, logs session init
- `session.idle` → shows handoff reminder toast (if active task), logs tracked files, stops DB watcher
- `session.error` → cleans up session files, stops DB watcher

**Review notification flow** (via `startDatabaseWatch` + `checkForReviewTasks`):
- Watches `.todos/issues.db` for changes
- On change (debounced 500ms): calls `checkForReviewTasks()`
- Extracts `reviewable_by_you` tasks from status
- Shows TUI toast for each new reviewable task
- Skips tasks implemented by current session (same-session check)
- Tracks seen reviews in `lastSeenReviews` Set to avoid duplicate toasts

**Correctness**: The review notification logic is sound. The same-session check correctly prevents self-review notifications. The `lastSeenReviews` cleanup (removing IDs no longer in review) is correct.

**Missing event**: No `session.stopped` or `session.ended` event handler — only `session.idle` and `session.error`. If a session ends cleanly without going idle first, the DB watcher may not be stopped. This depends on OpenCode's event model.

---

### 3. AGENTS.md Mandatory Rules Enforcement Gap

| Rule | Text | Enforcement Status | Evidence | Gap Description |
|------|------|--------------------|----------|-----------------|
| **Rule 1** | Before any file edit/write, run `TD(action: "status")`. If no active task, stop. | **Partially enforced** | `td-enforcer.ts` `permission.ask` and `tool.execute.before` hooks block writes without active task | Enforced for MCP write tools only. Shell-level writes via `Bash` tool bypass enforcement entirely. The rule says "run status" but enforcer runs status internally — agent doesn't need to manually call it. |
| **Rule 2** | At session start, run `TD(action: "usage", newSession: true)` | **Prose-only** | `session.created` event in enforcer only starts DB watcher and logs — does NOT call `td usage --new-session` or verify it was called | No mechanism verifies or enforces this. An agent can skip `usage` entirely with no consequence. |
| **Rule 3** | Sub-agents do not inherit TD enforcement. Include explicit TD requirement text in sub-agent prompt. After completion, link changed files. | **Prose-only** | No hook or mechanism can inspect sub-agent prompts or verify TD text inclusion | Entirely dependent on LLM compliance. No tooling enforcement possible at plugin level. |
| **Rule 4** | Before context ends, always write handoff | **Partially enforced (reminder only)** | `session.idle` event shows a toast reminder if active task exists | Toast is dismissible and non-blocking. No enforcement prevents session end without handoff. The `session.idle` event may not fire on all session termination paths. |

**Summary**: Only Rule 1 has meaningful enforcement (via write-blocking hooks). Rules 2, 3, and 4 are prose-only or reminder-only with no hard enforcement.

---

### 4. Parameter Handling Edge Cases

| Parameter | Expected Behavior | Actual Behavior | Severity |
|-----------|------------------|-----------------|----------|
| `dep` + `depAction: "blocking"` | Show what depends on `<task>` | Constructs `td dep <task> --blocking` — **correct** per CLI help | ✅ OK |
| `dep` + `depAction: "list"` | Show what `<task>` depends on | Constructs `td dep <task>` (bare, no sub-action) — **correct** per CLI help | ✅ OK |
| `dep` + `depAction: "add"` | Add dependency | Constructs `td dep add <task> <targetIssue>` — **correct** | ✅ OK |
| `ws tag` + `issueIds` | Tag array of issue IDs | Spreads array: `td ws tag ...issueIds` — **correct** | ✅ OK |
| `create` + `labels` | Comma-separated string | Passes as `--labels <string>` — **correct** (CLI accepts comma-separated) | ✅ OK |
| `block-issue` | Block a task | Calls `td block <task>` — **correct** but no `--reason` exposed | ⚠️ Minor gap |
| `unblock-issue` | Unblock a task | Calls `td unblock <task>` — **correct** but no `--reason` exposed | ⚠️ Minor gap |
| `handoff` + no `task` | Handoff focused task | Calls `td handoff` (no task arg) — CLI requires `<issue-id>` as positional arg per help text | ⚠️ F-09 |
| `log` + `task` param | Log to specific task | `task` param is **silently ignored** — always logs to focused task | ❌ F-02 |
| `log` + `logType: "decision"` | Structured log | Constructs `td log --decision <message>` — **correct** (boolean flag) | ✅ OK |
| `approve`/`reject` + `message` | Reason for action | Constructs `--reason <message>` — **correct** (`--reason` is primary flag, `--message` is alias) | ✅ OK |
| `files` + `files` array | Link files to task | **Silently ignored** — only calls `td files <task>` (list) | ❌ F-01 |
| `update` + `acceptance`/`dependsOn`/`blocks`/`points`/`parent` | Update these fields | These params exist in schema but are **not handled** in `update` case | ⚠️ P2 gap |
| `ws handoff` + `done`/`remaining`/`decision`/`uncertain` | Structured ws handoff | Correctly passes all 4 flags | ✅ OK |
| `handoff` + all 5 fields | Full handoff | All 5 fields (`task`, `done`, `remaining`, `decision`, `uncertain`) correctly handled | ✅ OK |

**Handoff `task` parameter note**: Per CLI help, `td handoff <issue-id>` requires the issue ID as a positional argument. The tool correctly passes it when provided. When omitted, `td handoff` is called with no args — CLI behavior in this case depends on whether a task is focused. If no task is focused, the CLI will error. The tool returns `result.stderr` which surfaces the error, so this is acceptable but could be improved with pre-validation.

---

### 5. td-workflow Skill Cross-Reference

| Skill-Prescribed Command/Action | Exists in td.ts? | Parameters Match? | Notes |
|--------------------------------|-----------------|-------------------|-------|
| `usage` (new session) | ✅ | ✅ `newSession: true` | Correct |
| `status` | ✅ | ✅ | Correct |
| `start` or `focus` | ✅ | ✅ | Correct |
| `log` progress | ✅ | ⚠️ | No `task` targeting in tool |
| `review` (when complete) | ✅ | ✅ | Correct |
| `handoff` | ✅ | ✅ | Correct |
| `ws start` | ✅ | ✅ `wsAction: "start"`, `wsName` required | Correct |
| `ws tag` | ✅ | ✅ `wsAction: "tag"`, `issueIds` array | Correct |
| `ws log` | ✅ | ✅ `wsAction: "log"`, `message` required | Correct |
| `ws handoff` | ✅ | ✅ `wsAction: "handoff"` | Correct |
| `create` | ✅ | ✅ | Correct |
| `epic` | ✅ | ✅ | Correct |
| `tree` | ✅ | ✅ | Correct |
| `update` | ✅ | ⚠️ | Missing `acceptance`, `dependsOn`, `blocks`, `points`, `parent` in update case |
| `dep` | ✅ | ✅ | Correct |
| `critical-path` | ✅ | ✅ | Correct |
| `block-issue` | ✅ | ⚠️ | No `--reason` exposed |
| `unblock-issue` | ✅ | ⚠️ | No `--reason` exposed |
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
| `files` | ✅ | ❌ | Tool lists files, not links them — name/behavior mismatch |
| `dep list` (skill line 59) | ✅ | ✅ | `depAction: "list"` → `td dep <task>` — correct |
| `comment` | ✅ | ✅ | Correct |
| `whoami` | ✅ | ✅ | Correct |
| `link` | ✅ | ✅ | Correct |
| `unlink` | ✅ | ✅ | Correct |

**`td done` check**: The skill does NOT mention `td done`. ✅ The `agent-team-workflow.md` doc uses `td done` incorrectly (F-13).

**Skill workflow accuracy**: The skill's baseline sequence and multi-issue flow are accurate. The "Failure handling" section references `dep list` which maps correctly to `depAction: "list"`. The handoff quality bar (done/remaining/decision/uncertain) matches the tool's parameter schema.

**One discrepancy**: Skill line 59 says "inspect with `dep list`" — in the tool, this is `TD(action: "dep", task: "...", depAction: "list")`. The skill uses CLI syntax in a prose context, which is acceptable. No mismatch.

---

## Risk Assessment

**Verdict: needs-minor-fixes**

The architecture is fundamentally sound. The TD tool correctly wraps the CLI for 29 of 31 actions. The enforcer plugin correctly blocks writes for MCP write tools. The two P0 bugs (`files` action behavior mismatch, `log` task targeting) are isolated and fixable without structural changes. The AGENTS.md enforcement gap for Rules 2–4 is a known limitation of prose-based governance that would require significant plugin work to address fully.

---

## Remediation Priority

| Rank | Finding | Fix | Effort | Impact |
|------|---------|-----|--------|--------|
| 1 | **F-01** — `files` action ignores `files` array, only lists | Add conditional: if `input.files` provided, call `td link`; else call `td files` (list). Or rename action to `list-files` and use `link` for linking. | 30 min | High — agents calling `files` to link get wrong behavior silently |
| 2 | **F-02** — `log` ignores `task` param | Insert task ID before message: `if (input.task) args.splice(1, 0, input.task)` | 15 min | Medium — agents targeting specific tasks get logs on wrong task |
| 3 | **F-06/F-07** — Rules 2 & 4 prose-only | Add `session.created` hook to log warning if `td usage` hasn't been called; add `session.idle` enforcement (not just toast) for handoff | 2–4 hrs | Medium — improves compliance but cannot be fully enforced |
| 4 | **F-13** — `agent-team-workflow.md` uses `td done` | Replace 5 occurrences of `td done` with `td review` + `td approve` flow | 15 min | Medium — misleads agents into using admin-close instead of review flow |
| 5 | **F-14** — `td unblock` positional reason arg | Fix `td unblock td-abc123 "reason"` → `td unblock td-abc123 --reason "reason"` in doc | 5 min | Low — doc fix only |

**Bonus fix (P2)**: Add missing `update` action params (`acceptance`, `dependsOn`, `blocks`, `points`, `parent`) to the `update` case in `td.ts` — these are valid CLI flags that are currently silently dropped.

---

> **Note:** Two prior audit reports exist in `specs/audit/` (td-c0187e, td-972e8b) that are in `in_review` status. This audit (td-7c3679) is independent and covers the TD tool/enforcer specifically. The synthesis task (td-62d464) should incorporate all findings from this report.

> **File hygiene note:** Pre-existing uncommitted changes in `.gitignore`, `bun.lock`, `package.json`, and `.todos/` are present in the repository but were not caused by this audit task. Only `specs/audit/td-7c3679-td-tool-audit.md` was created by this task.
