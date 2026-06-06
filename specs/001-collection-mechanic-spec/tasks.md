---
description: "Task list for Collection Mechanic Plugin implementation"
---

# Tasks: Collection Mechanic Plugin

**Input**: Design documents from `specs/001-collection-mechanic-spec/`

**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅ | contracts/ui-contract.md ✅

**Tests**: Not requested — no test tasks generated.

**Organization**: Tasks are grouped by phase. Phase 1 (remediation) and Phase 2 (foundational)
must complete before any user story phase begins. User stories then proceed in priority order.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- File paths are relative to the repository root

---

## Phase 1: Setup — Constitution Remediation

**Purpose**: Bring existing code into compliance with constitution Principles II and V before any
feature work. File renames require a Lightroom restart to take effect.

**⚠️ CRITICAL**: Complete all Phase 1 tasks and perform the Lightroom restart (T007) before
beginning Phase 2. Lightroom will not detect renamed or new `.lua` files without a full restart.

- [X] T001 Rename `lrcollectionmechanic.lrdevplugin/UI_MainDialog.lua` to `UI__MainDialog.lua` (double underscore — Principle II)
- [X] T002 [P] Rename `lrcollectionmechanic.lrdevplugin/Util_StringUtils.lua` to `Util__StringUtils.lua` (double underscore — Principle II)
- [X] T003 [P] Rename `lrcollectionmechanic.lrdevplugin/Util_CatalogUtils.lua` to `Util__CatalogUtils.lua` (double underscore — Principle II)
- [X] T004 Update all `require` statements across `lrcollectionmechanic.lrdevplugin/CollectionMechanic.lua` and any other file that references the old single-underscore filenames to use the new double-underscore names
- [X] T005 [P] Verify `lrcollectionmechanic.lrdevplugin/Info.lua` defines `Info.PLUGINNAME` and `Info.LOGGERTARGET` on the `Info` object; add either field if missing
- [X] T005a [P] Verify `lrcollectionmechanic.lrdevplugin/Info.lua` registers the entry point under both `LrLibraryMenuItems` and `LrExportMenuItems`; add the missing registration if either is absent (FR-014)
- [X] T006 Create `lrcollectionmechanic.lrdevplugin/PluginInit.lua` — initialise `LrLogger(Info.PLUGINNAME)` and call `logger:enable(Info.LOGGERTARGET)`, then log a startup message (Principle V)
- [ ] T007 **[MANUAL]** Quit and restart Lightroom Classic so renamed files and `PluginInit.lua` are detected; reload plugin via Plug-in Manager and confirm no "Could not load toolkit script" errors in the log

**Checkpoint**: Plugin loads cleanly with double-underscore filenames and startup log entry visible.

---

## Phase 2: Foundational — Shared Infrastructure

**Purpose**: Core utilities and property table that ALL user stories depend on. No user story
work can begin until this phase is complete.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T008 Implement `StringUtils.sanitizeCollectionName(name)` in `lrcollectionmechanic.lrdevplugin/Util__StringUtils.lua` — trim whitespace, replace `"*/:|\?<>` and `\` with `_`, collapse consecutive underscores; return `{sanitizedName, status}` where status is `"OK"`, `"MODIFIED"`, or `"ERROR"` per data-model.md sanitization rules; also return an `errorMessage` string when status is `"ERROR"`
- [X] T009 [P] Implement `StringUtils.parseCollectionNames(input)` in `lrcollectionmechanic.lrdevplugin/Util__StringUtils.lua` — split on newlines (normalise `\r\n` and `\r` to `\n` first), trim each line, skip blank lines, apply `sanitizeCollectionName` to each, return array of `CollectionNameEntry` per data-model.md
- [X] T010 Implement `CatalogUtils.getCollectionSets()` in `lrcollectionmechanic.lrdevplugin/Util__CatalogUtils.lua` — depth-first recursive traversal of `catalog:getChildCollectionSets()` and each set's `getChildCollectionSets()`; build flat array of `{displayName, object}` where `displayName` is the full ancestry path joined with ` » `; obtain catalog via `LrApplication.activeCatalog()` inside the function per Principle I
- [X] T011 Define `PropertyTable` in `lrcollectionmechanic.lrdevplugin/CollectionMechanic.lua` using `LrBinding.makePropertyTable(context)` with fields: `filterText=""`, `allCollectionSets={}`, `filteredCollectionSets={}`, `selectedCollectionSet=false`, `collectionNamesInput=""`, `proposedNamesText=""`, `executionResults={}` — note: `dryRunResults` is NOT present; `selectedCollectionSet` initialises to `false` (not nil) so the placeholder popup item is active on open per ui-contract.md
- [X] T012 Add module-level logger import to each of `CollectionMechanic.lua`, `UI__MainDialog.lua`, `Util__StringUtils.lua`, `Util__CatalogUtils.lua` in `lrcollectionmechanic.lrdevplugin/` — `local logger = import 'LrLogger'(Info.PLUGINNAME)` with no `:enable()` call (PluginInit handles that) per Principle V

**Checkpoint**: Foundation ready — `sanitizeCollectionName`, `parseCollectionNames`, and
`getCollectionSets` all callable; PropertyTable initialises without error; no `dryRunResults` field present.

---

## Phase 3: User Story 1 — Batch Create Collections (Priority: P1) 🎯 MVP

**Goal**: User selects a collection set, enters names, clicks Execute, and collections are
created with sanitized names. Partial-success batches supported.

**Independent Test**: Select a collection set, enter three names (one with a special character),
click Execute — verify the execution results dialog shows 3 entries and all three collections
appear in Lightroom under the selected set.

### Implementation for User Story 1

- [X] T013 [US1] Populate `props.allCollectionSets` and `props.filteredCollectionSets` on dialog open in `lrcollectionmechanic.lrdevplugin/CollectionMechanic.lua` — call `CatalogUtils.getCollectionSets()` inside `LrFunctionContext` and assign results to both fields before showing dialog; log the count of sets found
- [X] T014 [US1] Build main dialog skeleton in `lrcollectionmechanic.lrdevplugin/UI__MainDialog.lua` — collection set popup row (bound to `props.filteredCollectionSets` / `props.selectedCollectionSet`), collection names multi-line text field (bound to `props.collectionNamesInput`), placeholder for Proposed Collection Names column (to be expanded in US2), and button row with Create Collections (primary action) and Cancel buttons per ui-contract.md; return view to `CollectionMechanic.showCollectionMechanicDialog` for presentation via `LrDialogs.presentModalDialog`
- [X] T015 [US1] Implement `CatalogUtils.createCollections(targetSet, entries)` in `lrcollectionmechanic.lrdevplugin/Util__CatalogUtils.lua` — wrap all creation in a single `catalog:withWriteAccessDo("Create Collections", func)` call; within the callback iterate entries with status `~= "ERROR"`, check for existing collection using `string.lower` comparison (FR-012 case-insensitive duplicate detection) and if found mark as success without creating, otherwise call `catalog:createCollection(entry.sanitizedName, targetSet, true)` and check return value (`~= nil`) for success — do NOT use `pcall` around any LR SDK call (Principle III); populate `entry.created` and `entry.errorMessage`; return full results array (partial-success pattern from research.md D-006)
- [X] T016 [US1] Implement Create Collections validation in `lrcollectionmechanic.lrdevplugin/UI__MainDialog.lua` — check `props.selectedCollectionSet ~= false` (show "Please select a collection set before proceeding." via `LrDialogs.message` if false/nil); check parsed names contain at least one non-ERROR entry (show "Please enter at least one collection name." if not); abort if either check fails; dialog MUST remain open on validation failure
- [X] T017 [US1] Implement Create Collections button handler in `lrcollectionmechanic.lrdevplugin/UI__MainDialog.lua` — wrap body in `LrFunctionContext.postAsyncTaskWithContext`; call `StringUtils.parseCollectionNames(props.collectionNamesInput)`, run validation (T016), call `CatalogUtils.createCollections`, store results in `props.executionResults`, close main dialog, trigger Execution Results dialog; implement re-entrance guard boolean flag per ui-contract.md
- [X] T018 [US1] Build Execution Results dialog in `lrcollectionmechanic.lrdevplugin/UI__MainDialog.lua` — summary line "Successfully created X collection(s)", error details table (columns: Name | Sanitized | Reason) shown only when at least one ERROR exists, single Close button per ui-contract.md Execution Results Dialog section; use `cancelVerb = "< exclude >"`
- [X] T019 [US1] Log Create Collections operations in `lrcollectionmechanic.lrdevplugin/UI__MainDialog.lua` and `Util__CatalogUtils.lua` — `logger:info` for operation start (collection set name, name count), `logger:warn` per skipped ERROR entry, `logger:info` for completion summary (created count, error count)

**Checkpoint**: User Story 1 fully functional — batch creation works, partial failures reported,
results dialog shows correct summary. Test independently before moving to US2.

---

## Phase 4: User Story 2 — Live Sanitization Preview (Priority: P2)

**Goal**: As the user types collection names, the read-only Proposed Collection Names field
alongside the input shows the sanitized equivalent of each name (or `<ERROR: description>`) in
real time — no button press required. The main dialog is 50% wider and the names area is
split into two equal-width columns.

**Independent Test**: Enter names including special characters in the Collection Names field —
observe the Proposed Collection Names field updating live on each keystroke without pressing
any button. Enter a name that consists entirely of reserved characters and confirm the
corresponding line shows `<ERROR: ...>`. Verify both fields are equal width and height and
that no collections are created by typing alone.

### Implementation for User Story 2

- [X] T020 [US2] Widen the main dialog in `lrcollectionmechanic.lrdevplugin/UI__MainDialog.lua` — locate the current `width` or `min_width` value passed to `LrDialogs.presentModalDialog` (or the top-level view); multiply it by 1.5 (50% wider) and update; if no explicit width is set, add one at 1.5× the default narrow width (FR-017)
- [X] T021 [US2] Replace the single Collection Names input with a two-column `horizontal_group` in `lrcollectionmechanic.lrdevplugin/UI__MainDialog.lua` — left column: existing Collection Names `edit_field` (editable, multi-line, `fill_horizontal`, bound two-way to `props.collectionNamesInput`, labelled "Collection Names (one per line)"); right column: new Proposed Collection Names `edit_field` (read-only, multi-line, `fill_horizontal`, value from `props.proposedNamesText`, labelled "Proposed Collection Names"); both columns use identical `height_in_lines`; the `horizontal_group` itself spans the full content width of the dialog (FR-018, FR-019, FR-021)
- [X] T022 [US2] Implement live sanitization observer in `lrcollectionmechanic.lrdevplugin/CollectionMechanic.lua` — after PropertyTable is created, call `props:addObserver("collectionNamesInput", function(_, _, newValue) ... end)`; inside the observer split `newValue` on `\n`, for each line: if blank emit blank, otherwise call `StringUtils.sanitizeCollectionName(line)` — if ERROR emit `"<ERROR: " .. errorMessage .. ">"`, otherwise emit the sanitized name; join all results with `\n` and assign to `props.proposedNamesText`; no LR SDK calls that may yield are made inside this observer (D-008, FR-003, FR-022)
- [X] T023 [US2] Remove all Dry Run code from `lrcollectionmechanic.lrdevplugin/UI__MainDialog.lua` — delete: the Dry Run button definition from the button row, the Dry Run button action callback, the Dry Run validation function, and the Dry Run Results dialog builder; ensure no references to `props.dryRunResults` remain in the file
- [X] T024 [US2] Log live sanitization updates in `lrcollectionmechanic.lrdevplugin/CollectionMechanic.lua` — on observer fire, log at `logger:debug` level the line count and error count in the proposed output (avoids per-keystroke noise at info level); no catalog interactions are logged here

**Checkpoint**: User Stories 1 AND 2 both work independently. Dialog is visibly wider. Proposed
Collection Names field updates live on each keystroke. No Dry Run button present. Execute still
creates collections correctly using the same sanitization logic as the live preview.

---

## Phase 5: User Story 3 — Collection Set Filter (Priority: P3)

**Goal**: Filter field above the collection set selector narrows the list by case-insensitive
partial name match. Selection persists when filter changes.

**Independent Test**: Open the dialog on a catalog with 5+ collection sets. Type a partial name
in the filter field — selector narrows to matching sets. Clear the filter — all sets reappear.
Select a set, then type a different filter — selected set remains in `props.selectedCollectionSet`
even if hidden. Click Execute — operation uses the still-selected set.

### Implementation for User Story 3

- [X] T025 [US3] Add filter field row above the collection set popup in `lrcollectionmechanic.lrdevplugin/UI__MainDialog.lua` — single-line text field with label "Collection Set Filter", bound two-way to `props.filterText`, placeholder "Type to filter collection sets...", positioned immediately above the collection set selector per ui-contract.md Filter Field spec; collection set popup label is "Base Collection Set"
- [X] T026 [US3] Implement filter observer in `lrcollectionmechanic.lrdevplugin/CollectionMechanic.lua` or `UI__MainDialog.lua` — observe `props.filterText` changes; recompute `props.filteredCollectionSets` from `props.allCollectionSets` using `string.find(string.lower(displayName), string.lower(filterText), 1, true) ~= nil`; assign full list when `filterText` is empty (case-insensitive plain-text match per research.md D-003)
- [X] T027 [US3] Verify selection-persistence in `lrcollectionmechanic.lrdevplugin/UI__MainDialog.lua` — confirm `props.selectedCollectionSet` is NOT reset when `props.filteredCollectionSets` changes; Execute must use the stored selection regardless of current filter state

**Checkpoint**: All three user stories independently functional. Filter narrows correctly,
clears correctly, and does not disturb existing selection.

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Final quality pass across all user stories.

- [X] T028 Verify button row layout in `lrcollectionmechanic.lrdevplugin/UI__MainDialog.lua` — Cancel button on the left side of the action row, Create Collections as the primary action button on the right; no Execute or Dry Run buttons present per ui-contract.md Button Row spec (FR-023, FR-024, FR-025)
- [X] T029 [P] Audit all `logger:*` calls across `lrcollectionmechanic.lrdevplugin/` — confirm `logger:info` for normal operations, `logger:warn` for recoverable issues (e.g., skipped ERROR names), `logger:error` for unexpected failures; no important operation left unlogged per constitution Principle V
- [X] T030 [P] Search all `.lua` files in `lrcollectionmechanic.lrdevplugin/` for any remaining `require` or `import` references to single-underscore filenames (`UI_`, `Util_`) and update to double-underscore equivalents per constitution Principle II
- [ ] T031 **[MANUAL]** Follow `specs/001-collection-mechanic-spec/quickstart.md` happy path in Lightroom Classic — install plugin, verify live sanitization updates as names are typed, create 3 collections, verify character sanitization workflow, check log output; confirm all three user stories pass their independent tests end-to-end

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup/Remediation)**: No dependencies — start immediately. T007 (restart) MUST complete before Phase 2.
- **Phase 2 (Foundational)**: Depends on Phase 1 + T007 restart — BLOCKS all user stories.
- **Phase 3 (US1)**: Depends on Phase 2. T013 → T014 → T015 → T016/T017 → T018 → T019.
- **Phase 4 (US2)**: Depends on Phase 3 (T014 dialog skeleton, T008 sanitization). T020 → T021 → T022 (in parallel with T023) → T024.
- **Phase 5 (US3)**: Depends on Phase 2. T025 requires T014 (main dialog skeleton) to exist.
- **Polish (Phase N)**: Depends on all desired user story phases being complete.

### Within Phase 3 (US1)

```
T013 (populate sets on open)
  ↓
T014 (dialog skeleton) ← required by T015, T016, T017, T018
  ↓
T015 [P] (createCollections)   T016 [P] (Execute validation)
  ↓                                   ↓
T017 (Execute handler — depends on T015 + T016)
  ↓
T018 (Execution Results dialog)
  ↓
T019 (logging — can be woven in throughout)
```

### Within Phase 4 (US2)

```
T020 (widen dialog)
  ↓
T021 (two-column names layout) [P] T023 (remove Dry Run code)
  ↓
T022 (live sanitization observer — requires T011 proposedNamesText field)
  ↓
T024 (debug logging for observer)
```

### Parallel Opportunities

```
# Phase 1 — run together after T001:
T002, T003 (file renames — different files)
T005, T005a (Info.lua checks — same file, can read/verify together)

# Phase 2 — run together:
T008, T009 (StringUtils functions — same file, sequence within file)
T010 (CatalogUtils — different file from T008/T009)
T012 (logger imports — multiple files, independent)

# Phase 3 — after T014:
T015 (createCollections) and T016 (validation) can be written in parallel

# Phase 4 — after T020+T021:
T022 (observer) and T023 (remove dry run) can be written in parallel
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup/Remediation (includes Lightroom restart)
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Follow quickstart.md Execute happy path independently
5. Proceed to US2 when US1 is confirmed working

### Incremental Delivery

1. Phase 1 + Phase 2 → Foundation ready
2. Phase 3 → Execute works → Test US1 independently
3. Phase 4 → Live preview works, dialog wider → Test US2 independently
4. Phase 5 → Filter works → Test US3 independently
5. Phase N → Polish and full end-to-end validation

---

## Notes

- `[P]` tasks = different files or independent functions, no blocking dependencies
- `[US1/US2/US3]` label maps task to its user story for traceability
- **[MANUAL]** tasks require developer action in Lightroom; cannot be automated
- File renames (T001–T003) are git operations: `git mv` preserves history
- After T007 (restart), verify plugin loads before proceeding — check log for startup message
- `createCollection` is called inside `withWriteAccessDo`, NOT wrapped in `pcall` — Principle III forbids pcall around yielding SDK calls in Lua 5.1 (research.md D-006)
- The live sanitization observer (T022) must NOT make any yielding SDK calls — it runs synchronously on the property change event
- `selectedCollectionSet` initialises to `false` (not `nil`) so the popup placeholder item is the active selection on dialog open (ui-contract.md)
- The filter observer (T026) uses `props:addObserver`, not polling
- The main dialog uses the standard `cancelVerb` for the Cancel button (FR-025); `cancelVerb = "< exclude >"` is NOT used on the main dialog — Cancel is the intended secondary action
