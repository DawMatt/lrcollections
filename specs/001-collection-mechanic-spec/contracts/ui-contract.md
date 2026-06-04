# UI Contract: Collection Mechanic Plugin

**Phase**: 1 | **Date**: 2026-06-03 | **Plan**: [plan.md](../plan.md)

This document defines the UI layout, control behaviour, and interaction contracts for all
dialogs in the Collection Mechanic plugin. It serves as the authoritative reference for
`UI__MainDialog.lua` and any result dialog implementations.

---

## Main Dialog

**Title**: "Collection Mechanic"
**Type**: Modal dialog (`LrDialogs.presentModalDialog`)
**Action button**: "Close" (single standard action button — no OK/Cancel)

### Layout (top to bottom)

```
┌──────────────────────────────────────────────────────┐
│  [Label: "Collection Set Filter"]  [Text field]      │  ← Filter row
│  [Label: "Base Collection Set"]    [Popup menu]      │  ← Selector row
│  [Label: "Collection Names (one per line)"]          │
│  [Multi-line text area: collectionNamesInput]        │  ← Names input
│  [Hint: "Option+Return (Mac) or Alt+Enter (Win)"]    │
│──────────────────────────────────────────────────────│
│  [Dry Run]  [Execute]                    [Close]     │  ← Button row
└──────────────────────────────────────────────────────┘
```

**Initial focus**: On dialog open, keyboard focus MUST be placed on the Collection Set Filter
field so the user can begin filtering immediately without a mouse click.

### Controls

#### Filter Field

| Property | Value |
|----------|-------|
| Label | "Collection Set Filter" |
| Type | Single-line text field |
| Binding | `props.filterText` (two-way) |
| Placeholder | "Type to filter collection sets…" |
| Position | Above the collection set popup |
| Behaviour | On every change to `filterText`, recompute `filteredCollectionSets` from `allCollectionSets` using case-insensitive plain-text `string.find`. Update popup items. |

#### Collection Set Popup

| Property | Value |
|----------|-------|
| Label | "Base Collection Set" |
| Type | Popup/dropdown menu |
| Binding | Items from `props.filteredCollectionSets`; selected value → `props.selectedCollectionSet` |
| Placeholder item | `"-- Select a collection set --"` (disabled, shown when nothing selected) |
| Display format | `CollectionSetItem.displayName` (e.g., `"Events > 2024 > Summer"`) — ASCII `" > "` is used as the hierarchy separator; Unicode `»` is not supported by LrView string rendering |
| Default state | On dialog open, `selectedCollectionSet` MUST be initialised to `false` so the placeholder item is the active selection. No set is pre-selected. |
| Binding type | `selectedCollectionSet` holds `{displayName, object}` when a real set is chosen, or `false` when the placeholder is active. Raw `LrCollectionSet` objects MUST NOT be stored directly — `getName()` cannot be called from button callbacks (C event loop context). |
| Behaviour | Populated from `filteredCollectionSets`. Filter changes update items without clearing the current selection if the selected item remains. When `filteredCollectionSets` is empty (no sets match the filter), the popup shows only the placeholder item. |

#### Collection Names Input

| Property | Value |
|----------|-------|
| Label | "Collection Names (one per line)" |
| Type | Multi-line text field (scrollable) |
| Binding | `props.collectionNamesInput` (two-way) |
| Placeholder | "Enter collection names, one per line" |
| Hint label | "To add a new line: Option+Return (Mac) or Alt+Enter (Windows)" — displayed as a static label below the text area |
| Behaviour | Free-form text. Each non-blank line is treated as one collection name. No character restrictions in input. |

#### Button Row

| Button | Label | Action |
|--------|-------|--------|
| Dry Run | "Dry Run" | Validate input → sanitize names → show Dry Run Results dialog. Does NOT close main dialog. |
| Execute | "Execute" | Validate inputs → sanitize → create collections → show Execution Results dialog. Does NOT close main dialog unless user then clicks Close. |
| Close | "Close" | Dismiss main dialog. No catalog changes. (Standard LrDialogs action button.) |

**Button row position**: All three buttons on the same row, aligned to the bottom of the dialog.
Dry Run and Execute on the left; Close is the standard action button on the right.

**Re-entrance guard**: Dry Run and Execute MUST NOT be re-entrant. A boolean flag MUST prevent
a second invocation while an operation is in progress. The buttons are not visually disabled
(LR SDK limitation) but clicks are silently ignored until the current operation completes.

**Async task requirement**: Button action callbacks run on Lightroom's C event loop and MUST
wrap their entire body in `LrTasks.startAsyncTask(function() ... end)` before making any SDK
call that may yield (catalog reads, `getName()`, `LrDialogs`, `withWriteAccessDo`, etc.).
Calling a yielding SDK method directly from a button callback produces a fatal
"Yielding is not allowed within a C or metamethod call" error at runtime.

---

## Dry Run Results Dialog

**Title**: "Dry Run Results"
**Type**: Modal dialog (`LrDialogs.presentModalDialog`)
**Action button**: "Close"

### Layout

```
┌──────────────────────────────────────────────────────┐
│  Dry Run complete. No collections were created.       │
│                                                      │
│  ┌────────────────┬────────────────┬──────────┐      │
│  │ Original Name  │ Sanitized Name │ Status   │      │
│  ├────────────────┼────────────────┼──────────┤      │
│  │ ...            │ ...            │ OK       │      │
│  │ ...            │ ...            │ MODIFIED │      │
│  │ ...            │ ...            │ ERROR    │      │
│  └────────────────┴────────────────┴──────────┘      │
│─────────────────────────────────────────────────────│
│                                          [Close]     │
└──────────────────────────────────────────────────────┘
```

### Behaviour

- Results table is scrollable when the row count exceeds the visible area.
- Each row shows: `originalName`, `sanitizedName`, `status`.
- Status values: `OK`, `MODIFIED`, `ERROR`.
- If all names have status `OK`: summary line reads "All names are ready to be created."
- If any names have status `MODIFIED`: summary includes "Some names were modified."
- If any names have status `ERROR`: summary includes "Some names are invalid and will be skipped."

---

## Execution Results Dialog

**Title**: "Execution Results"
**Type**: Modal dialog (`LrDialogs.presentModalDialog`)
**Action button**: "Close"

### Layout

```
┌──────────────────────────────────────────────────────┐
│  Successfully created X collection(s).               │
│  [Y name(s) were skipped due to errors.]             │  ← only if Y > 0
│                                                      │
│  [Error details table — only shown if errors exist]  │
│  ┌────────────────┬────────────────┬──────────────┐  │
│  │ Name           │ Sanitized      │ Reason       │  │
│  ├────────────────┼────────────────┼──────────────┤  │
│  │ ...            │ ...            │ ...          │  │
│  └────────────────┴────────────────┴──────────────┘  │
│─────────────────────────────────────────────────────│
│                                          [Close]     │
└──────────────────────────────────────────────────────┘
```

### Behaviour

- Summary line always shown: "Successfully created X collection(s)."
- Error line shown only if at least one name resulted in ERROR: "Y name(s) were skipped due
  to errors."
- Error details table shown only when at least one ERROR exists. Columns: original name,
  sanitized name (or empty if sanitization itself failed), reason.
- If all names succeeded (zero errors), no table is shown — summary line only.

---

## Validation Error Dialogs

Shown via `LrDialogs.message()` when user input fails validation. The main dialog remains
open after dismissal.

| Trigger | Message |
|---------|---------|
| Execute clicked, no collection set selected | "Please select a collection set before proceeding." |
| Dry Run or Execute clicked, no valid collection names | "Please enter at least one collection name." |
| All names result in ERROR after sanitization | "All collection names are invalid after sanitization. Please review and re-enter." |
