<!--
SYNC IMPACT REPORT
==================
Version change: [TEMPLATE] → 1.0.0
Added sections:
  - Core Principles (I–V)
  - LR Plugin Layout Standards
  - Development Workflow & Quality Gates
  - Governance
Modified principles: N/A (initial population)
Removed sections: N/A (initial population)
Templates requiring updates:
  - .specify/templates/plan-template.md ✅ Constitution Check section aligned
  - .specify/templates/spec-template.md ✅ No structural changes required
  - .specify/templates/tasks-template.md ✅ No structural changes required
Deferred TODOs: None
-->

# LR Collections Constitution

## Core Principles

### I. LR SDK Compliance (NON-NEGOTIABLE)

Code MUST follow the Lightroom Classic SDK import rules precisely:

- Only items documented as **namespaces** (or namespace+class) in the SDK reference MAY be
  imported via `import 'Lr...'`. Pure classes (e.g. `LrCatalog`, `LrCollection`,
  `LrCollectionSet`) MUST NOT be imported — they are obtained via object methods instead.
- Catalog access MUST be obtained inside a function via `LrApplication.activeCatalog()`, never
  at module level.
- Context-sensitive SDK namespaces (`LrDialogs`, catalog objects) MUST be imported or
  instantiated inside the function that uses them, not at module scope.
- All catalog write operations MUST be wrapped in `catalog:withWriteAccessDo()`.

**Rationale**: Violating these rules produces cryptic "Could not find namespace" errors at
runtime and cannot be caught before the plugin is loaded into Lightroom.

### II. Lua Module Conventions

Every Lua source file MUST define a single named object table and expose all functionality
through it:

- Module-level imports (e.g. `LrView`, `LrBinding`) are acceptable at the top of the file.
- Sub-directory require is **not supported** by Lightroom. Files MUST reside in the plugin root
  and MUST use a double-underscore prefix as a namespace grouping signal
  (e.g. `Util__StringUtils.lua`, `UI__MainDialog.lua`). The prefix is omitted in the
  object/namespace name declared inside the file.
- Shared static configuration (plugin name, log target) MUST live in `Info.lua` via an `Info`
  object. Other modules MUST `require "Info"` and read values from it — no hardcoding of
  plugin-wide constants.

**Rationale**: Lightroom's `require` constraint makes file-level namespacing the only available
modularity mechanism. The prefix convention makes grouping visible without directory hierarchy.

### III. Safe Catalog Operations

All interactions with the Lightroom catalog MUST be defensive:

- Write operations MUST use `catalog:withWriteAccessDo(actionName, func)`.
- Operations that may fail (collection creation, object method calls on potentially deleted
  objects) MUST be wrapped in `pcall()`.
- Before relying on a retrieved object (e.g. a collection set), existence MUST be verified
  (e.g. check `collectionSet:getName()` does not return nil).
- Error messages shown to the user MUST be clear and actionable; raw SDK errors MUST NOT be
  surfaced verbatim.

**Rationale**: Lightroom catalog state can change while a plugin is running. Unguarded errors
crash the plugin dialog with no user-recoverable path.

### IV. Thin Entry Points

Menu item module files (the Lua files registered in `Info.lua` under `LrLibraryMenuItems` /
`LrExportMenuItems`) MUST be minimal:

- They MUST only set up the async task context (`LrFunctionContext.postAsyncTaskWithContext`)
  and delegate immediately to the core module function.
- Business logic, UI construction, and catalog access MUST NOT live in entry point files.

**Rationale**: Keeps entry points readable, testable in isolation, and consistent with LR SDK's
async model.

### V. Observability

All meaningful plugin operations MUST be logged:

- Logging MUST be initialised in `PluginInit.lua` (and optionally re-enabled at module level
  where needed) using `LrLogger(Info.PLUGINNAME)`.
- Log level and target (print / logfile) MUST be controlled by `Info.LOGGERTARGET` — not
  hardcoded per module.
- The available log levels are: `fatal`, `error`, `warn`, `info`, `debug`, `trace`.
  Use the appropriate level — do not log everything at `info`.
- Operations logged MUST include: operation type, key inputs, and outcome.

**Rationale**: Lightroom plugins run inside a host application with no attached debugger.
Structured log output is the primary diagnostic tool.

## LR Plugin Layout Standards

The plugin directory (`*.lrdevplugin/`) MUST conform to this layout:

```
*.lrdevplugin/
├── Info.lua              # Plugin metadata + menu registration + Info object
├── PluginInit.lua        # Logger initialisation, startup diagnostics
├── [Feature].lua         # Orchestrator(s) — dialog lifecycle, workflow coordination
├── UI__[Name].lua        # UI view/layout definitions (LrView, LrBinding)
└── Util__[Name].lua      # Utility modules (string ops, catalog helpers, etc.)
```

Rules:
- `Info.lua` MUST be the plugin entry point and MUST define `LrLibraryMenuItems` and
  `LrExportMenuItems` for any user-invocable functionality.
- New scripts added after Lightroom is already running require a **Lightroom restart** to be
  detected — plugin reload alone is insufficient. This MUST be communicated to developers.

## Development Workflow & Quality Gates

1. **Specification first**: Features MUST have a spec (`SPECIFICATION.md` or
   `specs/.../spec.md`) reviewed before implementation begins.
2. **Constitution Check in plan**: Every implementation plan MUST include a Constitution Check
   gate before Phase 0 research and MUST re-verify after Phase 1 design.
3. **Manual verification**: Because Lightroom's sandbox prevents automated unit testing of SDK
   interactions, each feature MUST be manually tested inside Lightroom Classic against the
   acceptance scenarios in the spec before being considered complete.
4. **Dry-run before execute**: Any destructive or catalog-modifying operation MUST offer a
   dry-run/preview mode that shows intended changes without touching the catalog.
5. **No external I/O**: Plugin operations MUST NOT make external network calls or access the
   file system beyond Lightroom's own catalog and plugin directory.

## Governance

This constitution supersedes all other project conventions and coding standards. Where guidance
in `LRPLUGINDEVELOPMENT.md` or the SDK reference conflicts with this constitution, raise the
conflict explicitly before implementing.

**Amendment procedure**:
- Any principle change MUST be recorded here with an updated version number and `LAST_AMENDED`
  date.
- MAJOR bump: removal or redefinition of a principle.
- MINOR bump: new principle or material guidance addition.
- PATCH bump: clarifications, wording, or non-semantic refinements.
- After amendment, run `/speckit-constitution` to propagate updates to templates.

**Compliance review**: Every plan's Constitution Check section MUST explicitly confirm or flag
violations against Principles I–V before implementation is approved.

**Runtime development guidance**: See `LRPLUGINDEVELOPMENT.md` for Lightroom-specific Lua
patterns, SDK class/namespace tables, and worked examples.

**Version**: 1.0.0 | **Ratified**: 2026-06-03 | **Last Amended**: 2026-06-03
