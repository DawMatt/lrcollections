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
sanitized name. Collect a `ResultRecord` per name. After all attempts, display the aggregate
results. Do not abort on individual failures.

```lua
local results = {}
for _, entry in ipairs(sanitizedEntries) do
    if entry.status == "ERROR" then
        table.insert(results, entry)  -- record without attempting creation
    else
        local ok, created = pcall(function()
            return catalog:createCollection(entry.sanitizedName, targetSet, true)
        end)
        entry.created = ok and created ~= nil
        entry.status = ok and "OK" or "ERROR"
        if not ok then entry.errorMessage = tostring(created) end
        table.insert(results, entry)
    end
end
```

**Rationale**: Spec clarification Q1 — partial success is the required behaviour. `pcall`
wraps each creation call per Principle III. `canReturnPrior=true` (third arg to
`createCollection`) prevents errors for duplicate names (treated as success per FR-012).

---

### D-007: Button Layout

**Decision**: Single row of action buttons: `[Dry Run]  [Execute]  [Close]`. No separate
OK / Cancel buttons. The standard Lightroom dialog action button row is used for Close;
Dry Run and Execute are placed alongside it.

**Rationale**: Original spec TODO: "Keep only 1 of those 3 buttons [Close/OK/Cancel], then
place the Dry Run and Execute buttons on the same line as the standard button(s)." Reduces
visual clutter and aligns with the spec's stated improvement.

**Alternatives considered**: Separate rows for action vs navigation buttons — rejected per
the spec TODO.
