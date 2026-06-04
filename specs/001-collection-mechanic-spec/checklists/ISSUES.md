# ISSUES TO RESOLVE

## Run 2026/06/04 0815

General

- [x] No log entries are not being written to the TPG-Collection-Mechanic.log log file.
  **Fixed**: `Info.lua` was missing `LrInitPlugin = 'PluginInit.lua'` — PluginInit never
  executed so `logger:enable()` was never called. Added `LrInitPlugin` to the return table.

Main dialog

- Filter
    - [x] Relabel as Collection Set Filter
      **Fixed**: Label changed to "Collection Set Filter" in `UI__MainDialog.lua` and
      `ui-contract.md`.
- Collection Set field
    - [x] First entry in collection set selector is an instruction "Select a collection set". It is not selected by default and is only visible when you open the drop down list. It needs to be selected by default or removed.
      **Fixed**: Placeholder item has `value = false`; `props.selectedCollectionSet` was
      initialised to `nil`. Changed initialisation to `false` so the placeholder is selected
      on open.
    - [x] The collection set selector has entries such as "Select a collection set", and any nested collection set, that contain strings such as "xc2xbb". I believe these are unicode characters that are supposed to make the list values more aesthetic. The list either needs to be configured to support these characters, or the characters replaced with something that will display correctly.
      **Fixed**: Replaced raw UTF-8 byte sequences with ASCII equivalents — `" > "` for the
      hierarchy separator (`\xc2\xbb`), `"--"` for the em-dash placeholder (`\xe2\x80\x94`),
      and `"..."` for the filter ellipsis (`\xe2\x80\xa6`).
    - [x] Rename label to "Base Collection Set"
      **Fixed**: Label changed to "Base Collection Set" in `UI__MainDialog.lua` and
      `ui-contract.md`.
- Collection Names
    - [x] The collection names text field contains guidance on expected content. Add operating system specific guidance that option + enter (Mac) or alt + enter (Win) must be used when adding additional collections to be created.
      **Fixed**: Added a hint label below the names field: "To add a new line: Option+Return
      (Mac) or Alt+Enter (Windows)".
- [x] Execute button generated this stack trace:
```
Yielding is not allowed within a C or metamethod call
    0: global   assert                         - C
    1: upvalue  ?                              - 179812414:752+5
    2: field    wait                           - 179812414:1133+64
    3:          [unnamed]                      - 345274524:76+42
    4:          [unnamed]                      - tail
    5:          [unnamed]                      - tail
    6: field    getCollectionInfo              - 775833618:147+21
    7: method   getName                        - 929831656:124+10
    8:          [unnamed]                      - UI__MainDialog.lua:168
<end>
```
  **Fixed**: `onExecute` was calling `targetSet:getName()` directly in the button callback
  (a C context that disallows yields). Changed `buildPopupItems` to store the full
  `{displayName, object}` item as the popup value; `onExecute` now uses
  `targetSet.displayName` for logging and passes `targetSet.object` to `createCollections`,
  eliminating all `getName()` calls from button callbacks.
- [x] Cancel button is still visible in the dialog.
  **Fixed**: Added `actionVerb = "Close"` and `cancelVerb = "< exclude >"` to all three
  `presentModalDialog` calls (`CollectionMechanic.lua`, and both result dialogs in
  `UI__MainDialog.lua`). Note: an earlier attempt used `"< no cancel >"` which rendered as a
  button label rather than suppressing Cancel — corrected in Run 2026/06/04 2301 (see below).
- [x] OK, Dry Run and Execute buttons are spread across 2 lines in dialog.
  **Fixed**: Root cause was the default OK+Cancel footer from `presentModalDialog`. With
  `actionVerb = "Close"` and `cancelVerb = "< no cancel >"`, the footer now shows only
  "Close" on one row; Dry Run and Execute remain in the content row above.

## Run 2026/06/04 2151

- [x] Execute button generated this stack trace:
```
Yielding is not allowed within a C or metamethod call
    0: global   assert                         - C
    1: upvalue  ?                              - 179812414:752+5
    2: field    wait                           - 179812414:1133+64
    3:          [unnamed]                      - 345274524:76+42
    4:          [unnamed]                      - tail
    5:          [unnamed]                      - tail
    6: field    getCollectionInfo              - 775833618:147+21
    7: method   getName                        - 929831656:124+10
    8: field    createCollections              - Util__CatalogUtils.lua:33
    9:          [unnamed]                      - UI__MainDialog.lua:187
<end>
```
  **Fixed**: The previous fix removed `getName()` from UI__MainDialog.lua but
  `CatalogUtils.createCollections` still called `targetSet:getName()` on line 33 for
  logging — also in the C callback context. Two changes applied:
  1. `onDryRun` and `onExecute` now wrap their entire body in `LrTasks.startAsyncTask`,
     re-entering a Lua coroutine context where SDK methods that yield are permitted.
  2. `createCollections` signature changed to `createCollections(targetSet, entries, targetName)`;
     the logger call uses the passed-in `targetName` string instead of calling `getName()`,
     so the function never calls `getName()` regardless of calling context.

- [x] Execute button generated this error:
```
An internal error has occurred.
[string "Ul_MainDialog.lua"]:149: attempt to call field 'unpack' (a nil value)
```
  **Fixed**: Lightroom Classic uses Lua 5.1 where `unpack` is a global function — `table.unpack`
  was introduced in Lua 5.2 and does not exist in the LR SDK environment. Changed
  `table.unpack(children)` to `unpack(children)` at `UI__MainDialog.lua:149` in
  `showExecutionResultsDialog`. Also documented the Lua 5.1 constraint in constitution
  Principle II and plan.md Technical Context to prevent recurrence.

## Run 2026/06/04 2301

- [x] Execute button generated this error:
```
2026-06-04 23:01:44.2420000+10:00, INFO	createCollections: starting, target=Set 03 > Set 02_01, count=2
2026-06-04 23:01:44.2430000+10:00, WARN	createCollections: failed to create 'Test 01_': Yielding is not allowed within a C or metamethod call
2026-06-04 23:01:44.2440000+10:00, WARN	createCollections: failed to create 'Test 02': Yielding is not allowed within a C or metamethod call
2026-06-04 23:01:44.2440000+10:00, INFO	createCollections: done, created=0, errors=2
```
  **Fixed**: Two compounding issues resolved:
  1. `LrTasks.startAsyncTask` was replaced with `LrFunctionContext.postAsyncTaskWithContext`
     in both `onDryRun` and `onExecute` in `UI__MainDialog.lua`. `startAsyncTask` creates a
     plain Lua coroutine; `postAsyncTaskWithContext` registers a full LR function context with
     LR's internal task scheduler, which is required for catalog write operations to yield.
  2. `pcall` was removed from around `catalog:createCollection` in `Util__CatalogUtils.lua`.
     In Lua 5.1, yielding from within a `pcall` body (a C function) is forbidden. The call
     now uses direct invocation with a nil-check on the return value for error detection.
  Spec updated first: `ui-contract.md` async task requirement and `plan.md` constraints
  both corrected to reference `postAsyncTaskWithContext` and document the `pcall` restriction.

- [x] The Cancel button in the dialog is still appearing, with a label of "< no cancel >".
  **Fixed**: `"< no cancel >"` is not a valid SDK suppress token — Lightroom renders it as a
  button label. The correct value documented in `LRPLUGINDEVELOPMENT.md` and constitution
  v1.4.0 UI Dialog Standards is `"< exclude >"`. Updated all three `presentModalDialog` calls
  in `CollectionMechanic.lua` and `UI__MainDialog.lua` to `cancelVerb = "< exclude >"`.
  Also corrects the Run 0815 entry above, which recorded the wrong value as the fix.