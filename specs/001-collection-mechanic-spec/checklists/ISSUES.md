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
  **Fixed**: Added `cancelVerb = "< no cancel >"` and `actionVerb = "Close"` to the
  `presentModalDialog` call in `CollectionMechanic.lua`. Same fix applied to Dry Run Results
  and Execution Results sub-dialogs.
- [x] OK, Dry Run and Execute buttons are spread across 2 lines in dialog.
  **Fixed**: Root cause was the default OK+Cancel footer from `presentModalDialog`. With
  `actionVerb = "Close"` and `cancelVerb = "< no cancel >"`, the footer now shows only
  "Close" on one row; Dry Run and Execute remain in the content row above.

## Run 2026/06/04 2151

- [ ] Execute button generated this stack trace:
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