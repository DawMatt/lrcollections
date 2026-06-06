# Research: Collection Mechanic Plugin

**Phase**: 0 | **Date**: 2026-06-03 | **Plan**: [plan.md](plan.md)

## Decision Log

### D-001: File Naming Convention

**Decision**: Rename existing single-underscore files to double-underscore convention.

| Current | Renamed |
|---------|---------|
| `UI_MainDialog.lua` | `UI__MainDialog.lua` |
| `Util_CatalogUtils.lua` | `Util__CatalogUtils.lua` |
| `Util_StringUtils.lua` | `Util__StringUtils.lua` |

**Rationale**: Constitution Principle II mandates double-underscore prefixes. The existing
single-underscore names violate this. Renaming requires a full Lightroom restart to take effect
(plugin reload does not detect renamed files).

**Alternatives considered**: Keeping single-underscore names — rejected because it violates the
constitution and creates inconsistency if more utility files are added later.

---

### D-002: Logger Initialisation Strategy

**Decision**: Add `PluginInit.lua`. Initialise the logger there with `logger:enable(...)`.
All other modules import the logger by name only (no repeated `:enable()` call).

```lua
-- PluginInit.lua
require "Info"
local LrLogger = import 'LrLogger'
local logger = LrLogger(Info.PLUGINNAME)
logger:enable(Info.LOGGERTARGET)
logger:info("Plugin initialised: " .. Info.PLUGINNAME)
```

```lua
-- Any other module
require "Info"
local LrLogger = import 'LrLogger'
local logger = LrLogger(Info.PLUGINNAME)
-- No :enable() call needed — already enabled in PluginInit
```

**Rationale**: Constitution Principle V requires centralised logger initialisation in
`PluginInit.lua`. Single `:enable()` call avoids duplicate enablement and keeps per-module
code minimal.

**Alternatives considered**: Initialising logging in `Info.lua` — rejected because `Info.lua`
is a data file; side-effects (logging setup) belong in `PluginInit.lua`.

---

### D-003: Case-Insensitive String Matching

**Decision**: Use `string.lower()` on both sides of all name comparisons — for the collection
set filter and for duplicate detection.

```lua
-- Filter match
local function matchesFilter(name, filterText)
    if filterText == "" then return true end
    return string.find(string.lower(name), string.lower(filterText), 1, true) ~= nil
end

-- Duplicate check (conceptual — actual check is via canReturnPrior=true)
local function namesMatch(a, b)
    return string.lower(a) == string.lower(b)
end
```

**Rationale**: Spec clarification Q2 — case-insensitive for both filter and duplicate
detection. `string.lower` is available in the Lightroom Lua environment. The `true` fourth
argument to `string.find` disables pattern matching (plain text search), preventing reserved
pattern characters in collection names from causing errors.

**Alternatives considered**: Lua `string.match` with `%l`/`%u` patterns — rejected because it
is more complex and the plain `find` with lowercased strings is simpler and correct.

---

### D-004: Collection Set List Population

**Decision**: Load all collection sets synchronously when the dialog opens. Cache the full list
in the property table (`props.allCollectionSets`). The filter derives `props.filteredCollectionSets`
from the cached list on each filter text change. Reload is not needed for the dialog's lifetime.

**Rationale**: Collection set lists rarely change while a dialog is open. Synchronous load at
open avoids loading-state complexity. Caching avoids repeated catalog traversals on each
keystroke. The spec (SC-004) requires responsiveness with 500+ sets — filtering an in-memory
array is O(n) and well within interactive thresholds.

**Alternatives considered**: Lazy load on first filter interaction — rejected because the
dropdown must be immediately usable when the dialog opens. Async load with spinner — rejected
as over-engineering for a local catalog operation.

---

### D-005: Recursive Collection Set Traversal

**Decision**: Traverse the collection set hierarchy recursively, building a flat list of
`{displayName, object}` pairs where `displayName` shows the full ancestry path
(e.g., `"Events » 2024 » Summer"`).

```lua
local function collectSets(parent, prefix, results)
    local sets = parent:getChildCollectionSets()
    for _, set in ipairs(sets) do
        local name = set:getName()
        local display = prefix == "" and name or (prefix .. " \xc2\xbb " .. name)
        table.insert(results, { displayName = display, object = set })
        collectSets(set, display, results)
    end
end
```

**Rationale**: The `»` separator (U+00BB, encoded as UTF-8 `\xc2\xbb`) is the Lightroom
convention for hierarchical display (confirmed in original spec). Depth-first traversal ensures
parents appear before their children, which is natural for reading.

**Alternatives considered**: Breadth-first traversal — rejected because it intermixes sets
from different branches, making hierarchy harder to read.

---

### D-006: Partial-Success Execute Pattern

**Decision**: Sanitize all names first. Attempt creation for every name that produces a non-empty
sanitized name inside a single `withWriteAccessDo` block. Collect a `ResultRecord` per name.
After all attempts, display the aggregate results. Do not abort on individual failures.

```lua
catalog:withWriteAccessDo("Create Collections", function(context)
    for _, entry in ipairs(sanitizedEntries) do
        if entry.status == "ERROR" then
            table.insert(results, entry)  -- record without attempting creation
        else
            local created = catalog:createCollection(entry.sanitizedName, targetSet, true)
            entry.created = created ~= nil
            if not entry.created then
                entry.status = "ERROR"
                entry.errorMessage = "Collection could not be created."
            end
            table.insert(results, entry)
        end
    end
end)
```

**Rationale**: Spec clarification Q1 — partial success is the required behaviour. Constitution
Principle III mandates `withWriteAccessDo` for catalog writes and prohibits `pcall` around LR
SDK calls that may yield (Lua 5.1 cannot yield across a `pcall` C boundary). `canReturnPrior=true`
(third arg to `createCollection`) prevents errors for duplicate names (treated as success per
FR-012). Return-value checking (`created ~= nil`) is used instead of `pcall`.

**Alternatives considered**: `pcall` wrapping per creation call — rejected because `pcall`
cannot wrap yielding SDK calls in Lua 5.1 (Constitution Principle III). Separate
`withWriteAccessDo` per name — rejected as unnecessary overhead; a single transaction is
simpler and sufficient.

---

### D-007: Button Layout

**Decision**: Single row of action buttons: `[Cancel]  [Create Collections]`. No Dry Run or
Execute buttons. Cancel is the standard `cancelVerb` button (dismisses dialog, no catalog
changes). Create Collections is the primary action — validates inputs, creates collections,
closes the dialog, and opens the results summary.

**Rationale**: The Dry Run button was replaced by the live Proposed Collection Names field
(FR-003, FR-022 — spec v4). The Execute push button was subsequently replaced by the standard
dialog action button labelled "Create Collections" (FR-023, FR-024 — spec v6), which closes
the dialog on success. Cancel is restored (FR-025 — spec v6) so the user can exit the dialog
without creating any collections. This is standard modal dialog UX.

**Alternatives considered**: Keeping Dry Run alongside live preview — rejected (redundant).
Keeping a separate Execute push button — rejected in favour of the conventional OK/Cancel
pattern. Labelling the action button "OK" — rejected; "Create Collections" is more
self-explanatory (spec assumption, v6).

---

### D-009: Cancel Behaviour During Active Creation

**Decision**: Once collection creation begins (after Create Collections validation passes),
any Cancel click is silently ignored. Creation runs to completion regardless.

**Rationale**: The LR SDK provides no API to disable the Cancel button at runtime. Aborting
a mid-batch write would leave the catalog in a partially-modified state with no rollback
mechanism. Running to completion is safer and simpler; the results summary reports exactly
what was created (FR-028, spec v7 clarification).

**Alternatives considered**: Aborting creation mid-batch — rejected due to SDK limitations
and catalog integrity risk. Showing a progress indicator — beyond scope for v1; the
re-entrance guard silently prevents a second invocation if Create Collections is clicked again.

---

### D-008: Live Sanitization Update Strategy

**Decision**: Watch `collectionNamesInput` via `props:addObserver` and update
`proposedNamesText` by splitting the input on newlines, sanitizing each line, and joining
results back into a single string. The Proposed Collection Names field binds read-only to
`proposedNamesText`.

```lua
props:addObserver("collectionNamesInput", function(_, _, newValue)
    local lines = splitLines(newValue)
    local proposed = {}
    for _, line in ipairs(lines) do
        if line == "" then
            table.insert(proposed, "")
        else
            local sanitized, err = sanitizeName(line)
            if err then
                table.insert(proposed, "<ERROR: " .. err .. ">")
            else
                table.insert(proposed, sanitized)
            end
        end
    end
    props.proposedNamesText = table.concat(proposed, "\n")
end)
```

**Sync scrolling constraint**: The Lightroom Classic SDK does not expose scroll position as a
bindable property on `edit_field` controls. True pixel-level scroll synchronisation between
two separate `edit_field` instances is not achievable with standard LrView. The practical
mitigation is to make both fields tall enough to display all content without scrolling for
typical input sizes (up to ~20 lines by default), relying on `height_in_lines` to match both
fields identically. For larger inputs the user may scroll each field independently; this is a
known SDK limitation. The fields will always remain line-count-aligned because both bind to
text derived from the same input.

**Read-only field**: The Proposed Collection Names field uses `edit_field` with no binding to
a writable property (or a view-only binding) so the user cannot type into it. The `value` is
set programmatically via `proposedNamesText`.

**Rationale**: `props:addObserver` fires synchronously whenever the bound property changes,
providing per-keystroke updates (FR-022). Splitting and rejoining the text preserves the
line-by-line correspondence required by FR-003.

**Alternatives considered**: Polling via `LrTasks` — rejected as unnecessarily complex and
not per-keystroke. Separate observer per line — not viable since the input is a single string.
Autogrow field — Lightroom's `edit_field` does not support autogrow; fixed `height_in_lines`
is the available option.
