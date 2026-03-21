# TDD: ICM Plugin — LLM-Driven Prune and Distill Tools

**Task:** td-9da879
**Author:** staff-engineer
**Status:** draft
**Date:** 2026-02-28

## Problem statement

Phase 1 of the ICM plugin (td-e2af34) implemented three automatic pruning strategies — deduplication, supersedeWrites, and purgeErrors — that run transparently on every `messages.transform` invocation. These strategies are conservative by design: they only prune content that is provably redundant or stale.

However, automatic strategies cannot address the largest source of context bloat: **large tool outputs that are no longer relevant to the current task but don't match any automatic pattern**. Examples include lengthy file reads from abandoned approaches, verbose build logs from successful operations, or search results that have already been acted upon.

Phase 2 closes this gap by giving the LLM itself the ability to proactively manage its context window through two new tools:

- **prune** — remove completed or noisy tool content without preservation
- **distill** — summarize valuable content into a concise form before removing the raw output

Without these tools, long sessions inevitably hit context limits, forcing expensive compaction or session restarts. The system prompt nudge ensures the LLM uses these tools proactively rather than waiting for context pressure.

## Constraints

- **Single file**: All changes must go into `.opencode/plugins/icm.ts` — no new files or modules.
- **Backward compatibility**: All Phase 1 automatic strategies must continue working identically.
- **Plugin API surface**: Only hooks documented in `@opencode-ai/plugin` are available: `tool`, `config`, `experimental.chat.system.transform`, `experimental.chat.messages.transform`.
- **No SDK import**: The plugin avoids importing `@opencode-ai/sdk` directly (M3 convention from Phase 1). All types are locally defined.
- **Graceful failure**: The plugin must never throw errors that propagate to the host. All tool executions and hooks must catch and handle errors internally.
- **Config-driven**: Tool registration and nudge injection must be fully controllable via `icm.jsonc` without code changes.

## Design options

### Option A: Closure-level persistent state (Recommended)

**Description:** Promote the `pruneSet` from a per-invocation local variable (rebuilt by `buildToolIndex` each call) to a persistent `Map` held in the plugin's closure scope. The `prune` and `distill` tool execute functions write to this persistent map. The `messages.transform` hook merges the persistent prune set with the per-invocation set built by automatic strategies, then applies the combined set.

A new `distillSummaries` array in the closure holds summaries from distill operations. The `messages.transform` hook injects these as synthetic text parts into the message stream.

**Pros:**
- Matches the reference DCP implementation's architecture (`state.prune.tools` is a persistent `Map`)
- Simple mental model: tools write to state, transform reads from state
- No fragile sentinel-based re-detection needed for tool-originated prunes
- Prune requests take effect on the very next transform pass

**Cons:**
- State is lost on plugin reload (acceptable — same as reference DCP)
- Must handle the merge carefully to avoid double-pruning (automatic strategy marks + tool marks)
- Closure state is not serialized to disk (no persistence across process restarts)

**Estimated effort:** M

---

### Option B: Sentinel-based re-detection

**Description:** When the `prune` or `distill` tool is called, immediately mutate the target tool parts in the current message array (by fetching messages via `client.session.messages`). Write a distinctive sentinel string (e.g., `[ICM: content pruned — prune-tool]`) into the output field. On the next `messages.transform` invocation, `buildToolIndex` re-detects these sentinels (it already does this for automatic strategies) and adds them to the per-invocation pruneSet, preventing double-processing.

**Pros:**
- No new closure-level state needed
- Prune markers survive plugin reloads (they're in the message data)
- Consistent with how Phase 1 re-detection already works

**Cons:**
- Requires fetching the full message array inside the tool execute function (expensive API call)
- Tool execution becomes a side-effect-heavy mutation of shared message state — race conditions if transform runs concurrently
- Distill summaries have no natural place to persist (messages are immutable from the tool's perspective — only the transform hook can inject synthetic parts)
- Fragile: depends on the SDK not cloning/freezing message objects between tool execution and the next transform pass

**Estimated effort:** L

---

### Option C: Hybrid — closure state with sentinel fallback

**Description:** Use closure-level state (Option A) as the primary mechanism, but also write sentinel markers into tool outputs during the transform pass. On subsequent invocations, `buildToolIndex` re-detects sentinels and repopulates the closure state if it was lost (e.g., after plugin reload).

**Pros:**
- Resilient to plugin reloads
- Best of both worlds

**Cons:**
- Added complexity for a scenario (plugin reload mid-session) that is rare in practice
- Two sources of truth that must be kept in sync
- Over-engineered for the current requirements

**Estimated effort:** L

## Decision

**Chosen option:** Option A — Closure-level persistent state

**Rationale:** This is the simplest correct approach and directly mirrors the reference DCP implementation. The `pruneSet` persistence problem is solved by lifting state to the plugin closure, which is the natural scope for cross-invocation data in the opencode plugin model. The reference DCP uses `state.prune.tools` as a persistent `Map<string, number>` for exactly this purpose.

Sentinel-based re-detection (Option B) is rejected because it requires an expensive `client.session.messages` fetch inside tool execution and creates race conditions between tool execution and transform passes. The hybrid approach (Option C) adds complexity for a rare edge case (plugin reload mid-session) that doesn't justify the maintenance cost.

**Rejected options summary:**
- Option B (Sentinel re-detection): Requires expensive message fetches in tool execution, creates race conditions, and has no clean mechanism for persisting distill summaries.
- Option C (Hybrid): Over-engineered for the requirements; adds two sources of truth for marginal resilience gain.

## Proposed design

### Overview

Extend `icm.ts` with three new hook handlers returned from the plugin factory function: a `tool` hook (registering `prune` and `distill`), a `config` hook (mutating opencode config), and an `experimental.chat.system.transform` hook (injecting the nudge). A new `PersistentPruneState` object in the plugin closure holds tool-requested prune IDs and distill summaries across transform invocations.

### Component changes

| Component | Change type | Notes |
|-----------|-------------|-------|
| `SessionState` interface | modify | No changes needed — automatic strategies continue using the per-invocation `pruneSet` from `buildToolIndex` |
| `PersistentPruneState` (new) | add | Closure-level state: `toolPruneSet: Map<string, string>`, `distillSummaries: DistillSummary[]` |
| `DistillSummary` interface (new) | add | `{ callIds: string[], summary: string, turn: number }` |
| Plugin factory return object | modify | Add `tool`, `config`, `experimental.chat.system.transform` hooks alongside existing `experimental.chat.messages.transform` |
| `messages.transform` handler | modify | Merge `persistentState.toolPruneSet` into `state.pruneSet` before applying; inject distill summaries as synthetic parts |
| `applyPruning` function | modify | Handle new strategy name `"prune-tool"` and `"distill-tool"` with same output replacement as deduplication |
| `buildToolIndex` function | modify | Re-detect `"prune-tool"` and `"distill-tool"` sentinel strings in already-pruned outputs to prevent double-processing |
| `NUDGE_CONTENT` constant (new) | add | Static nudge text for system prompt injection |

### State changes

#### New closure-level state: `PersistentPruneState`

```typescript
interface DistillSummary {
  callIds: string[]   // tool call IDs that were distilled
  summary: string     // the distilled summary text
  turn: number        // turn when distill was requested
}

interface PersistentPruneState {
  toolPruneSet: Map<string, string>  // callID → strategy name ("prune-tool" | "distill-tool")
  distillSummaries: DistillSummary[]
  nudgeCounter: number               // incremented each transform pass; used for nudge frequency
}
```

This state is initialized once in the plugin factory and shared by reference across all hook handlers via closure.

#### Existing `SessionState` — no changes

The per-invocation `SessionState` returned by `buildToolIndex` continues to work as-is. The `messages.transform` handler merges `persistentState.toolPruneSet` entries into `state.pruneSet` after automatic strategies run but before `applyPruning`.

### Interface contracts

#### Hook: `tool`

```typescript
// Returned from plugin factory as part of the hooks object
tool: {
  prune: {
    description: string,
    parameters: {
      type: "object",
      properties: {
        tool_call_ids: {
          type: "array",
          items: { type: "string" },
          description: "List of tool call IDs to prune from context"
        }
      },
      required: ["tool_call_ids"]
    },
    execute: (args: { tool_call_ids: string[] }) => Promise<string>
  },
  distill: {
    description: string,
    parameters: {
      type: "object",
      properties: {
        tool_call_ids: {
          type: "array",
          items: { type: "string" },
          description: "List of tool call IDs to distill and remove"
        },
        summary: {
          type: "string",
          description: "Concise summary preserving key findings from the pruned content"
        }
      },
      required: ["tool_call_ids", "summary"]
    },
    execute: (args: { tool_call_ids: string[], summary: string }) => Promise<string>
  }
}
```

**Note:** The exact tool registration API depends on whether `@opencode-ai/plugin` exports a `tool()` helper (as the reference DCP uses) or expects raw objects. The reference DCP uses `tool({ description, args, execute })` with `tool.schema` for argument definitions. If the ICM plugin's `@opencode-ai/plugin` version supports this, use it. Otherwise, use the raw object format shown above. The Senior Engineer should check the available API at implementation time.

#### Hook: `config`

```typescript
// Signature: async (opencodeConfig: OpencodeConfig) => void
config: async (opencodeConfig) => {
  // 1. Add tools to primary_tools
  const toolsToAdd: string[] = []
  if (config.tools.prune.permission !== "deny") toolsToAdd.push("prune")
  if (config.tools.distill.permission !== "deny") toolsToAdd.push("distill")

  if (toolsToAdd.length > 0) {
    const existing = opencodeConfig.experimental?.primary_tools ?? []
    opencodeConfig.experimental = {
      ...opencodeConfig.experimental,
      primary_tools: [...existing, ...toolsToAdd],
    }
  }

  // 2. Set permission entries
  const permission = opencodeConfig.permission ?? {}
  opencodeConfig.permission = {
    ...permission,
    ...(config.tools.prune.permission !== "deny" && { prune: config.tools.prune.permission }),
    ...(config.tools.distill.permission !== "deny" && { distill: config.tools.distill.permission }),
  }
}
```

#### Hook: `experimental.chat.system.transform`

```typescript
// Signature: async (input: unknown, output: { system: string }) => void
// OR: async (input: unknown, output: { system: string[] }) => void
// (Check SDK version — reference DCP uses string[], ICM should match)
"experimental.chat.system.transform": async (_input, output) => {
  // Skip if nudge disabled
  if (!config.tools.settings.nudgeEnabled) return

  // Skip for subagent sessions (reuse isSubAgent detection)
  // Note: system.transform may not have access to messages array.
  // See "Open questions" section for detection strategy.

  // Skip for internal agents
  const systemText = typeof output.system === "string"
    ? output.system
    : Array.isArray(output.system) ? output.system.join("\n") : ""
  for (const sig of INTERNAL_AGENT_SIGNATURES) {
    if (systemText.includes(sig)) return
  }

  // Nudge frequency check
  persistentState.nudgeCounter++
  if (persistentState.nudgeCounter % config.tools.settings.nudgeFrequency !== 0) return

  // Inject nudge
  if (typeof output.system === "string") {
    output.system = output.system + "\n\n" + NUDGE_CONTENT
  } else if (Array.isArray(output.system)) {
    if (output.system.length > 0) {
      output.system[output.system.length - 1] += "\n\n" + NUDGE_CONTENT
    } else {
      output.system.push(NUDGE_CONTENT)
    }
  }
}
```

### Tool schemas (JSON Schema)

#### prune

```json
{
  "type": "object",
  "properties": {
    "tool_call_ids": {
      "type": "array",
      "items": { "type": "string" },
      "description": "List of tool call IDs to remove from context. IDs are the callID values from tool parts in the message history."
    }
  },
  "required": ["tool_call_ids"],
  "additionalProperties": false
}
```

#### distill

```json
{
  "type": "object",
  "properties": {
    "tool_call_ids": {
      "type": "array",
      "items": { "type": "string" },
      "description": "List of tool call IDs to distill and remove from context."
    },
    "summary": {
      "type": "string",
      "description": "Concise summary preserving key findings, decisions, and actionable information from the pruned content."
    }
  },
  "required": ["tool_call_ids", "summary"],
  "additionalProperties": false
}
```

### Nudge injection logic

#### Nudge content (constant)

```
You have context management tools available:
- prune: Remove completed or noisy tool content from context without preservation
- distill: Distill valuable context into a concise summary before removing raw content

Use these proactively when context grows large or tool outputs become stale.
Prefer distill for content with valuable findings; use prune for routine/completed operations.
```

#### Injection conditions

The nudge is injected into the system prompt when ALL of the following are true:

1. `config.tools.settings.nudgeEnabled === true`
2. The session is NOT a subagent session
3. The session is NOT an internal agent (title generator, summarizer)
4. `persistentState.nudgeCounter % config.tools.settings.nudgeFrequency === 0` (every N transform passes)

#### Subagent detection in system.transform

The `system.transform` hook does not receive the messages array, so the existing `isSubAgent(messages)` helper cannot be called directly. Two approaches:

- **Preferred:** Cache the `isSubAgent` result in `persistentState` during the first `messages.transform` invocation (which runs after `system.transform` in the hook lifecycle). For the first invocation, check the system prompt text itself for `INTERNAL_AGENT_SIGNATURES` — this covers the internal agent case. For true subagent detection, the `system.transform` hook checks `output.system` for subagent signatures.
- **Fallback:** The reference DCP caches `state.isSubAgent` during session initialization and checks it in the system prompt handler. Our ICM plugin can do the same: set `persistentState.isSubAgent` during the first `messages.transform` call and check it in `system.transform`. On the very first call (before any transform has run), default to `false` (inject the nudge) — this is safe because internal agents are caught by the signature check.

### Error handling

#### Empty arrays

```typescript
// prune tool
if (!args.tool_call_ids || args.tool_call_ids.length === 0) {
  return "No tool call IDs provided. Nothing to prune."
}

// distill tool
if (!args.tool_call_ids || args.tool_call_ids.length === 0) {
  return "No tool call IDs provided. Nothing to distill."
}
if (!args.summary || args.summary.trim().length === 0) {
  return "Summary is required for distill. Provide a concise summary of the content being removed."
}
```

#### Invalid IDs (not found in toolIdList)

```typescript
const validIds: string[] = []
const invalidIds: string[] = []

for (const id of args.tool_call_ids) {
  if (state.toolParameters.has(id) || /* check toolIdList */) {
    validIds.push(id)
  } else {
    invalidIds.push(id)
  }
}

// Process valid IDs, report invalid ones in response
let result = `Pruned ${validIds.length} tool call(s).`
if (invalidIds.length > 0) {
  result += ` Skipped ${invalidIds.length} invalid ID(s): ${invalidIds.join(", ")}`
}
return result
```

#### Protected tools

```typescript
const protectedSet = new Set([
  ...DEFAULT_PROTECTED_TOOLS,
  ...config.tools.settings.protectedTools,
])

for (const id of args.tool_call_ids) {
  const meta = state.toolParameters.get(id)
  if (meta && protectedSet.has(meta.tool)) {
    // Return error message, not exception
    skippedIds.push(id)
    skippedReasons.push(`${id} (protected tool: ${meta.tool})`)
  }
}
```

#### Already-pruned IDs

```typescript
if (persistentState.toolPruneSet.has(id) || state.pruneSet.has(id)) {
  skippedIds.push(id)
  skippedReasons.push(`${id} (already pruned)`)
}
```

#### Transform hook errors

All errors in the transform hook are caught by the existing outer try/catch (lines 679–693 in current code). The merge of persistent state and distill summary injection should be wrapped in their own try/catch blocks following the same pattern as the existing strategy error handling.

### Distill summary injection

When the `distill` tool is called, the summary is stored in `persistentState.distillSummaries`. During the next `messages.transform` invocation, after pruning is applied, the handler injects each pending summary as a synthetic text part.

#### Injection mechanism

The summary is injected as a synthetic `text` part on the last assistant message that precedes the distill tool call. The part should be marked with a distinguishing property so it can be identified on subsequent passes:

```typescript
interface SyntheticTextPart {
  type: "text"
  text: string
  synthetic?: boolean  // if SDK supports this flag
}
```

If the SDK does not support a `synthetic` flag, prefix the text with a sentinel:

```
[ICM: distill summary] <summary text>
```

The Senior Engineer should verify which approach the SDK supports. The reference DCP uses `part.synthetic` and `part.ignored` flags — check if these are available in the ICM plugin's SDK version.

#### Summary persistence across invocations

Once a distill summary is injected as a synthetic part in the message stream, it persists naturally (the SDK preserves message parts across invocations). The `persistentState.distillSummaries` array should be cleared after injection to avoid duplicate injection.

### Data flow diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Plugin Closure Scope                       │
│                                                               │
│  config: ICMConfig (loaded once)                              │
│  persistentState: PersistentPruneState                        │
│    ├── toolPruneSet: Map<string, string>                      │
│    ├── distillSummaries: DistillSummary[]                     │
│    ├── nudgeCounter: number                                   │
│    └── isSubAgent: boolean                                    │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐  │
│  │  tool: prune  │  │ tool: distill│  │ config hook        │  │
│  │  ───────────  │  │ ────────────│  │ ──────────────     │  │
│  │  Writes to    │  │ Writes to   │  │ Mutates opencode   │  │
│  │  toolPruneSet │  │ toolPruneSet│  │ config: primary_   │  │
│  │               │  │ + distill-  │  │ tools, permissions │  │
│  │               │  │ Summaries   │  │                    │  │
│  └──────┬───────┘  └──────┬──────┘  └────────────────────┘  │
│         │                  │                                   │
│         ▼                  ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │         messages.transform handler                       │  │
│  │  ─────────────────────────────────────────────────────  │  │
│  │  1. buildToolIndex() → per-invocation SessionState       │  │
│  │  2. Run automatic strategies (dedup, supersede, purge)   │  │
│  │  3. Merge persistentState.toolPruneSet → state.pruneSet  │  │
│  │  4. applyPruning(messages, state.pruneSet)               │  │
│  │  5. Inject distillSummaries as synthetic text parts      │  │
│  │  6. Clear injected summaries from persistentState        │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │         system.transform handler                         │  │
│  │  ─────────────────────────────────────────────────────  │  │
│  │  1. Check nudgeEnabled, isSubAgent, internal agent sigs  │  │
│  │  2. Check nudgeCounter % nudgeFrequency                  │  │
│  │  3. Append NUDGE_CONTENT to system prompt                │  │
│  └─────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **PruneSet persistence race**: Tool execute and messages.transform run on different invocation paths. If transform runs while a tool execute is mid-flight, the toolPruneSet could be read in an inconsistent state. | low | medium | JavaScript is single-threaded (no true concurrency). The `await` in tool execute completes before the next transform can read the map. Document this assumption. If the host ever moves to worker threads, this needs a mutex. |
| **Synthetic message part format**: The SDK may not support `synthetic` or `ignored` flags on text parts. If the distill summary is injected as a plain text part, it could be confused with real assistant output or re-processed by other plugins. | medium | medium | Use a sentinel prefix (`[ICM: distill summary]`) as a fallback. The Senior Engineer should test both approaches and document which one works. Add a re-detection check in `buildToolIndex` to skip parts with the sentinel prefix. |
| **Subagent detection reliability in system.transform**: The `system.transform` hook doesn't receive the messages array, so `isSubAgent()` can't be called directly. The cached `isSubAgent` flag may not be set on the very first invocation. | medium | low | Default to `false` (inject nudge) on first call. Internal agents are caught by signature check on the system prompt text itself. The worst case is one unnecessary nudge injection on the first transform of a subagent session — this is harmless because subagents don't use the prune/distill tools. |
| **Tool ID format mismatch**: The LLM may provide tool call IDs in a different format than what `buildToolIndex` stores (e.g., with/without prefix, numeric vs string). | medium | medium | Validate IDs against `state.toolParameters` keys. Return a clear error message listing valid ID formats. Consider accepting both raw callIDs and numeric indices (like the reference DCP does). |
| **Nudge counter drift**: The `nudgeCounter` is incremented on every `system.transform` call, but some calls may be for internal agents (which are skipped). This means the counter doesn't perfectly track "user-facing turns." | low | low | Acceptable imprecision. The nudge frequency is a hint, not a guarantee. Increment only when the nudge is not skipped (i.e., after all skip checks pass). |
| **Config hook ordering**: If another plugin also mutates `experimental.primary_tools`, the arrays could conflict or duplicate entries. | low | low | Use spread with existing array (`[...existing, ...toolsToAdd]`). Check for duplicates before adding. |
| **Phase 1 regression**: Merging persistent prune state into the per-invocation pruneSet could cause automatic strategies to skip IDs they should process (if a tool-pruned ID is re-detected by buildToolIndex). | low | high | Merge persistent state AFTER automatic strategies run, not before. Automatic strategies only see the per-invocation pruneSet from buildToolIndex. The merge happens just before applyPruning. |

## Acceptance mapping

| # | Acceptance criterion | Satisfied by | Verification method |
|---|----------------------|-------------|---------------------|
| 1 | Plugin registers 'prune' tool via the tool hook; tool is callable by the AI with `{ tool_call_ids: string[] }` parameter. | `tool` hook in plugin return object; conditional registration based on `config.tools.prune.permission !== "deny"` | Unit test: mock plugin factory, verify `tool.prune` is present when permission is "allow"; verify JSON schema matches expected shape |
| 2 | Plugin registers 'distill' tool via the tool hook; tool is callable by the AI with `{ tool_call_ids: string[], summary: string }` parameters. | `tool` hook in plugin return object; conditional registration based on `config.tools.distill.permission !== "deny"` | Unit test: mock plugin factory, verify `tool.distill` is present when permission is "allow"; verify JSON schema matches expected shape |
| 3 | When prune tool is called, specified tool call IDs are added to the prune set; their content is replaced with placeholder on next LLM request. | `prune` tool execute writes to `persistentState.toolPruneSet`; `messages.transform` merges into `state.pruneSet`; `applyPruning` replaces output with `[ICM: content pruned — prune-tool]` | Integration test: call prune execute with valid IDs, then run messages.transform, verify output field is replaced with sentinel |
| 4 | When distill tool is called, specified tool call IDs are pruned AND the summary is injected as a synthetic message part that persists in context. | `distill` tool execute writes to `persistentState.toolPruneSet` AND `persistentState.distillSummaries`; `messages.transform` prunes IDs and injects summary as synthetic text part | Integration test: call distill execute, run messages.transform, verify (a) outputs are pruned and (b) synthetic text part with summary exists in message stream |
| 5 | Config hook mutates opencode config to add prune/distill to `experimental.primary_tools`. | `config` hook spreads existing `primary_tools` array and appends enabled tool names | Unit test: call config hook with mock opencodeConfig, verify `experimental.primary_tools` contains "prune" and "distill" |
| 6 | Config hook sets permission entries for prune and distill from DCP config values. | `config` hook sets `opencodeConfig.permission.prune` and `opencodeConfig.permission.distill` from ICM config | Unit test: call config hook, verify permission entries match ICM config values |
| 7 | System prompt transform injects DCP nudge instructions when `tools.settings.nudgeEnabled` is true. | `experimental.chat.system.transform` hook appends `NUDGE_CONTENT` to system prompt when conditions are met | Unit test: call system.transform with nudgeEnabled=true, verify output.system contains nudge text |
| 8 | System prompt nudge is NOT injected for subagent sessions. | `system.transform` checks `persistentState.isSubAgent` flag (cached from messages.transform) and `INTERNAL_AGENT_SIGNATURES` in system text | Unit test: call system.transform with subagent system prompt, verify nudge is NOT appended |
| 9 | Setting `tools.prune.permission` to 'deny' prevents prune tool registration; same for distill. | Conditional spread in `tool` hook: `...(config.tools.prune.permission !== "deny" && { prune: ... })` | Unit test: initialize plugin with prune.permission="deny", verify `tool.prune` is undefined in returned hooks |
| 10 | Tools respect protected tools list — attempting to prune a protected tool ID returns an error message (not an exception). | Tool execute checks `DEFAULT_PROTECTED_TOOLS` and `config.tools.settings.protectedTools`; returns descriptive string instead of throwing | Unit test: call prune with a protected tool ID (e.g., "write"), verify return string contains "protected" and no exception is thrown |
| 11 | All Phase 1 automatic strategies continue to work correctly alongside the new tools. | Automatic strategies run on per-invocation `state.pruneSet` BEFORE persistent state merge; no changes to strategy functions | Regression test: run deduplication, supersedeWrites, purgeErrors with same test fixtures as Phase 1; verify identical results |
| 12 | No runtime errors when tools are called with empty arrays or invalid IDs (graceful handling). | Input validation at top of each tool execute function; returns descriptive message instead of throwing | Unit test: call prune with `[]`, call prune with `["nonexistent"]`, call distill with empty summary; verify no exceptions and descriptive return messages |

## Open questions

1. **`tool` hook API shape**: Does the ICM plugin's version of `@opencode-ai/plugin` export a `tool()` helper function (like the reference DCP uses), or should tools be registered as raw objects with `description`, `parameters`, and `execute` fields? The Senior Engineer should check the available API and use whichever is supported.

2. **`system.transform` output shape**: Is `output.system` a `string` or `string[]`? The reference DCP uses `string[]`. The Senior Engineer should verify and handle both cases defensively.

3. **Synthetic part flags**: Does the SDK support `part.synthetic` and/or `part.ignored` flags on text parts? If so, use them for distill summary injection. If not, use the sentinel prefix approach. This affects how distill summaries are identified on subsequent passes.

4. **Tool call ID format**: Are tool call IDs opaque strings (UUIDs) or do they follow a predictable format? The reference DCP uses numeric indices into a `toolIdList` array rather than raw callIDs. Should the ICM plugin follow the same pattern (expose numeric indices to the LLM) or use raw callIDs? Using raw callIDs is simpler but the LLM needs to know them; using indices requires injecting a `<prunable-tools>` list into context.

5. **Nudge counter scope**: Should the nudge counter reset when the session changes, or persist across sessions? The reference DCP resets on session change. Recommend resetting.

## Implementation notes for Senior Engineer

### Files to modify

- `.opencode/plugins/icm.ts` — all changes in this single file

### Patterns to follow

1. **Conditional tool registration** — Follow the reference DCP pattern:
   ```typescript
   tool: {
     ...(config.tools.prune.permission !== "deny" && { prune: createPruneTool(...) }),
     ...(config.tools.distill.permission !== "deny" && { distill: createDistillTool(...) }),
   }
   ```

2. **Config mutation** — Follow the reference DCP pattern exactly (see Interface contracts > Hook: config above). Spread existing `primary_tools` to avoid clobbering other plugins' entries.

3. **Error handling in tool execute** — Return descriptive strings for user-facing errors (empty arrays, invalid IDs, protected tools). Only throw for truly unexpected errors. Wrap the entire execute body in try/catch.

4. **Persistent state initialization** — Create `persistentState` in the plugin factory, before the `return {}` block:
   ```typescript
   const persistentState: PersistentPruneState = {
     toolPruneSet: new Map(),
     distillSummaries: [],
     nudgeCounter: 0,
     isSubAgent: false,
   }
   ```

5. **Merge order in messages.transform** — Critical: merge persistent state AFTER automatic strategies, BEFORE applyPruning:
   ```typescript
   // ... existing strategy calls ...
   // Merge tool-requested prunes
   for (const [id, strategy] of persistentState.toolPruneSet) {
     if (!state.pruneSet.has(id)) {
       state.pruneSet.set(id, strategy)
     }
   }
   // Apply pruning (combined automatic + tool-requested)
   applyPruning(messages, state.pruneSet)
   // Inject distill summaries
   injectDistillSummaries(messages, persistentState)
   ```

6. **Distill summary injection** — Find the last assistant message before the distill tool call and append a text part. Clear `persistentState.distillSummaries` after injection.

7. **isSubAgent caching** — In the `messages.transform` handler, after the existing `isSubAgent(messages)` check, cache the result:
   ```typescript
   const subAgent = isSubAgent(messages)
   persistentState.isSubAgent = subAgent
   if (subAgent) return
   ```

### Test expectations

- Unit tests for each tool's execute function (valid IDs, invalid IDs, empty arrays, protected tools, already-pruned IDs)
- Unit test for config hook (primary_tools mutation, permission setting)
- Unit test for system.transform (nudge injection, subagent skip, internal agent skip, frequency gating)
- Integration test: full flow — register tools, call prune, run messages.transform, verify output replacement
- Integration test: full flow — call distill, run messages.transform, verify pruning + summary injection
- Regression tests: all Phase 1 strategy tests pass unchanged

### Edge cases

- Tool called before any messages.transform has run (persistentState.toolPruneSet is empty, toolParameters map is empty) — tool should return "No tool calls found in context" or similar
- Same ID passed to both prune and distill in the same turn — first write wins (Map.set is idempotent)
- Distill called with a very long summary — no truncation needed (the LLM controls summary length)
- Multiple distill calls in the same turn — all summaries should be injected (append to array, inject all)
- Plugin disabled (`config.enabled === false`) — no hooks returned, tools not registered (existing behavior)
