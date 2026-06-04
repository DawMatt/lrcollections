# Implementation Plan: Collection Mechanic Plugin

**Branch**: `001-collection-mechanic-spec` | **Date**: 2026-06-03 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-collection-mechanic-spec/spec.md`

## Summary

The Collection Mechanic Plugin enables Lightroom Classic users to batch-create collections
under a chosen collection set from a single modal dialog. The dialog provides a case-insensitive
filter field (above the collection set selector), a multi-line collection names input, and Dry
Run / Execute actions. Invalid characters in names are replaced with underscores; partial-success
batches (some names valid, some ERROR) are supported — valid names are created and errors
reported per-name in the results summary.

The existing plugin has functional code but requires two remediation items before feature work
proceeds: file renaming to double-underscore convention (Principle II) and introduction of
`PluginInit.lua` for centralised logging initialisation (Principle V).

## Technical Context

**Language/Version**: Lua 5.1 (Lightroom Classic SDK variant). Lua 5.2+ functions MUST NOT
be used — `table.unpack` does not exist; use the global `unpack`. No standard I/O stdlib.

**Primary Dependencies**: Lightroom Classic SDK namespaces:
`LrFunctionContext`, `LrView`, `LrBinding`, `LrDialogs`, `LrLogger`, `LrApplication`,
`LrTasks` (for async operations if needed)

**Storage**: N/A — all state is transient within the dialog session; catalog writes via SDK only

**Testing**: Manual testing inside Lightroom Classic 15.3+ (no automated unit test framework
is available for LR SDK interactions; Lightroom's sandbox prevents external test runners)

**Target Platform**: Lightroom Classic 15.3+ on macOS and Windows

**Project Type**: Lightroom Classic plugin (`.lrdevplugin` directory)

**Performance Goals**:
- Dialog opens and collection set list populates within 2 seconds
- 20 collections created and confirmed within 30 seconds of clicking Execute
- Filter field narrows the collection set selector immediately on each keystroke (no perceptible
  lag for catalogs with up to 500 collection sets)

**Constraints**:
- No external network calls or file system access beyond the plugin directory
- All operations within Lightroom's sandbox
- Sub-directory `require` is not supported — all Lua files must be at plugin root
- New files added after Lightroom launch require a full Lightroom restart to be detected
- Button action callbacks in `presentModalDialog` run on LR's C event loop and cannot yield;
  any SDK call that yields MUST be wrapped in
  `LrFunctionContext.postAsyncTaskWithContext(name, function(context) ... end)`.
  `LrTasks.startAsyncTask` is insufficient — catalog writes still fail because it does not
  register the task with LR's internal scheduler. Additionally, `pcall` MUST NOT wrap LR SDK
  calls that yield (Lua 5.1 cannot yield across a `pcall` C boundary); use return-value
  checks instead

**Scale/Scope**: Single user, single active catalog, no enforced batch size limit

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|-----------|-------|--------|
| I. LR SDK Compliance | `LrApplication.activeCatalog()` inside functions; `withWriteAccessDo` for writes; context-sensitive namespaces (`LrDialogs`) imported inside functions | ✅ Pass — planned design complies |
| II. Lua Module Conventions | Double-underscore prefixes required | ⚠️ **Pre-existing violation** — current files use single underscore (`UI_MainDialog.lua`, `Util_CatalogUtils.lua`, `Util_StringUtils.lua`). **Plan: rename all three as Phase 1 remediation task.** |
| III. Safe Catalog Operations | `pcall` wrapping; object existence checks; user-facing error messages | ✅ Pass — planned design complies |
| IV. Thin Entry Points | `CollectionMechanic.lua` entry point delegates immediately to orchestrator function | ✅ Pass |
| V. Observability | Logging via `LrLogger(Info.PLUGINNAME)`; level from `Info.LOGGERTARGET` | ⚠️ **Pre-existing violation** — no `PluginInit.lua` exists. Logging is currently initialised ad-hoc. **Plan: add `PluginInit.lua` as Phase 1 remediation task.** |

> Violations are pre-existing and will be resolved in Phase 1 remediation tasks before new
> feature work begins. No complexity justification needed — these are straightforward renames
> and a new file addition.

**Post-Phase 1 Re-check**: All principles satisfied after remediation tasks complete.

## Project Structure

### Documentation (this feature)

```text
specs/001-collection-mechanic-spec/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── ui-contract.md   # Phase 1 output — main dialog UI contract
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (plugin root)

```text
lrcollectionmechanic.lrdevplugin/
├── Info.lua                  # Plugin metadata, Info object, menu registration
├── PluginInit.lua             # Logger initialisation, startup diagnostics  [NEW]
├── CollectionMechanic.lua     # Entry point + orchestrator (dialog lifecycle, workflows)
├── UI__MainDialog.lua         # Main dialog layout (LrView, LrBinding)     [RENAMED]
├── Util__StringUtils.lua      # String sanitization utilities               [RENAMED]
└── Util__CatalogUtils.lua     # Catalog read/write operations               [RENAMED]
```

**Structure Decision**: Single plugin directory at repository root. No sub-directories within
the plugin (Lightroom's `require` does not support sub-directory paths). File grouping is
conveyed through the double-underscore prefix naming convention.

## Complexity Tracking

> No unjustified violations. Pre-existing naming and logging violations are resolved in Phase 1
> remediation — no architectural complexity introduced.
