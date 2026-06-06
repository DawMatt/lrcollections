# UI Contract: Collection Mechanic Plugin

**Phase**: 1 | **Date**: 2026-06-05 | **Plan**: [plan.md](../plan.md)

This document defines the UI layout, control behaviour, and interaction contracts for all
dialogs in the Collection Mechanic plugin. It serves as the authoritative reference for
`UI__MainDialog.lua` and any result dialog implementations.

---

## Main Dialog

**Title**: "Collection Mechanic"
**Type**: Modal dialog (`LrDialogs.presentModalDialog`)
**Action button**: "Create Collections" (primary action); "Cancel" (secondary — dismisses without creating)
**Width**: 50% wider than the pre-enhancement baseline dialog width.

### Layout (top to bottom)

```
┌────────────────────────────────────────────────────────────────────────────┐
│  [Label: "Collection Set Filter"]  [Text field]                            │  ← Filter row
│  [Label: "Base Collection Set"]    [Popup menu]                            │  ← Selector row
│  ┌──────────────────────────────────┬───────────────────────────────────┐  │
│  │ Collection Names (one per line)  │ Proposed Collection Names         │  │  ← Column headers
│  ├──────────────────────────────────┼───────────────────────────────────┤  │
│  │ [Multi-line edit field]          │ [Multi-line read-only field]      │  │  ← Names columns
│  └──────────────────────────────────┴───────────────────────────────────┘  │
│  [Hint: "Option+Return (Mac) or Alt+Enter (Win)"]                          │
│────────────────────────────────────────────────────────────────────────────│
│  [Cancel]                                        [Create Collections]      │  ← Button row
└────────────────────────────────────────────────────────────────────────────┘
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

#### Collection Names / Proposed Collection Names Area

The names area is a two-column row. Both columns are placed in a horizontal group that spans
the full content width of the dialog. Each column is equal width (50% of the available content
width, including its scroll bar).

##### Collection Names Field (left column)

| Property | Value |
|----------|-------|
| Label | "Collection Names (one per line)" — appears above the field |
| Type | Multi-line text field (`edit_field`, scrollable) |
| Binding | `props.collectionNamesInput` (two-way) |
| Placeholder | "Enter collection names, one per line" |
| Width | 50% of the names area (equal to the Proposed Collection Names field) |
| Height | Fixed `height_in_lines` — same value as the Proposed Collection Names field |
| Behaviour | Free-form text input. Each non-blank line is treated as one collection name. Every change fires the `collectionNamesInput` observer which updates `proposedNamesText`. |

##### Proposed Collection Names Field (right column)

| Property | Value |
|----------|-------|
| Label | "Proposed Collection Names" — appears above the field |
| Type | Multi-line text field (`edit_field`, read-only) |
| Binding | `props.proposedNamesText` (read from props; user cannot edit) |
| Width | 50% of the names area (equal to the Collection Names field) |
| Height | Fixed `height_in_lines` — same value as the Collection Names field |
| Behaviour | Read-only. Updated automatically by the `collectionNamesInput` observer. Each line shows either the sanitized name or `<ERROR: description>`. Blank input lines produce blank output lines, preserving line correspondence. |

**Sync scrolling note**: The Lightroom Classic SDK does not expose scroll position as a
bindable property. True pixel-level scroll synchronisation is not achievable. Both fields use
identical `height_in_lines` values; for inputs that exceed the visible lines, the user may
scroll each field independently. Line correspondence is always preserved because both fields
derive from the same line-split input.

##### Hint Label

A static label below the two-column names area:
`"To add a new line: Option+Return (Mac) or Alt+Enter (Windows)"`

#### Button Row

| Button | Label | Action |
|--------|-------|--------|
| Cancel | "Cancel" | Dismiss main dialog. No catalog changes. |
| Create Collections | "Create Collections" | Validate inputs → sanitize → create collections → close main dialog → show Execution Results dialog. |

**Button row position**: Both buttons on the same row, aligned to the bottom of the dialog.
Cancel on the left; Create Collections is the standard action button on the right.

**Re-entrance guard**: Create Collections MUST NOT be re-entrant. A boolean flag MUST prevent
a second invocation while an operation is in progress. The button is not visually disabled (LR
SDK limitation) but clicks are silently ignored until the current operation completes.

**Async task requirement**: Button action callbacks run on Lightroom's C event loop and MUST
wrap their entire body in `LrFunctionContext.postAsyncTaskWithContext(name, function(context) ... end)`
before making any SDK call that may yield (catalog reads, `getName()`, `LrDialogs`,
`withWriteAccessDo`, `createCollection`, etc.). `LrTasks.startAsyncTask` is insufficient —
it creates a plain Lua coroutine that does not integrate with LR's internal task scheduler,
so catalog write operations still fail with "Yielding is not allowed within a C or metamethod
call". `postAsyncTaskWithContext` creates a full LR function context that supports catalog
yields. Additionally, `pcall` MUST NOT wrap LR SDK calls that yield — in Lua 5.1, yielding
from within a `pcall` body (a C function) is also forbidden; check return values instead.

---

## Execution Results Dialog

**Title**: "Execution Results"
**Type**: Modal dialog (`LrDialogs.presentModalDialog`)
**Action button**: "Close"

### Layout

```
┌────────────────────────────────────────────────────────┐
│  Successfully created X collection(s).                 │
│  [Y name(s) were skipped due to errors.]               │  ← only if Y > 0
│                                                        │
│  [Error details table — only shown if errors exist]    │
│  ┌────────────────┬────────────────┬──────────────┐    │
│  │ Name           │ Sanitized      │ Reason       │    │
│  ├────────────────┼────────────────┼──────────────┤    │
│  │ ...            │ ...            │ ...          │    │
│  └────────────────┴────────────────┴──────────────┘    │
│───────────────────────────────────────────────────────│
│                                          [Close]       │
└────────────────────────────────────────────────────────┘
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
| Create Collections clicked, no collection set selected | "Please select a collection set before proceeding." |
| Create Collections clicked, no valid collection names | "Please enter at least one collection name." |
| All names result in ERROR after sanitization | "All collection names are invalid after sanitization. Please review and re-enter." |
