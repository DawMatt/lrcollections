# Data Model: Collection Mechanic Plugin

**Phase**: 1 | **Date**: 2026-06-03 | **Plan**: [plan.md](plan.md)

All state is transient — held in a `LrBinding` property table for the duration of the dialog
session. Nothing is persisted to disk or to the catalog beyond the collections themselves.

---

## PropertyTable (LrBinding Observable)

The single property table instance is created when the dialog opens and passed to all
components. It is the sole source of truth for dialog state.

| Field | Type | Description | Default |
|-------|------|-------------|---------|
| `filterText` | string | Current value of the filter/search field | `""` |
| `allCollectionSets` | array of `CollectionSetItem` | Full flat list loaded at dialog open | `{}` |
| `filteredCollectionSets` | array of `CollectionSetItem` | Subset matching `filterText` (case-insensitive) | `{}` (set on load) |
| `selectedCollectionSet` | `CollectionSetItem` or nil | The set chosen in the popup | `nil` |
| `collectionNamesInput` | string | Raw multi-line text from the names input field | `""` |
| `dryRunResults` | array of `ResultRecord` | Output of the last Dry Run | `{}` |
| `executionResults` | array of `ResultRecord` | Output of the last Execute | `{}` |

### Derived State Rules

- `filteredCollectionSets` is recomputed whenever `filterText` changes:
  - If `filterText` is empty: equals `allCollectionSets`
  - Otherwise: contains every `CollectionSetItem` whose `displayName` contains `filterText`
    (case-insensitive plain-text match)
- The popup menu items are bound directly to `filteredCollectionSets`.
- `selectedCollectionSet` is NOT reset when the filter changes (the selection persists if the
  selected item remains in the filtered list; it is hidden but not cleared if filtered out).

---

## CollectionSetItem

Represents one entry in the collection set selector.

| Field | Type | Description |
|-------|------|-------------|
| `displayName` | string | Full hierarchical path, e.g. `"Events » 2024 » Summer"` |
| `object` | LrCollectionSet | The SDK object — used for catalog write operations |

**Construction**: Built by recursive traversal of `catalog:getChildCollectionSets()` and each
set's `getChildCollectionSets()`. Depth-first, so parents appear before children. `displayName`
is constructed by prepending the parent display name and ` » ` separator at each level.

**Identity**: Two items represent the same collection set if their `object` references are
equal. `displayName` is for display only — not used for identity checks.

---

## CollectionNameEntry (transient, per-operation)

Represents one parsed line from `collectionNamesInput`. Created during Dry Run and Execute.
Never stored in the property table.

| Field | Type | Description |
|-------|------|-------------|
| `originalName` | string | The line as entered by the user (after trimming) |
| `sanitizedName` | string | Result of applying sanitization rules; may equal `originalName` |
| `status` | string | `"OK"`, `"MODIFIED"`, or `"ERROR"` |

**Status rules**:
- `OK`: `sanitizedName == originalName` and `sanitizedName` is non-empty
- `MODIFIED`: `sanitizedName ~= originalName` and `sanitizedName` is non-empty
- `ERROR`: `sanitizedName` is empty after sanitization

---

## ResultRecord

Extends `CollectionNameEntry` with the outcome of an Execute attempt.
Stored in `props.dryRunResults` or `props.executionResults`.

| Field | Type | Description |
|-------|------|-------------|
| `originalName` | string | As entered |
| `sanitizedName` | string | After sanitization |
| `status` | string | `"OK"`, `"MODIFIED"`, or `"ERROR"` |
| `errorMessage` | string or nil | Populated for `ERROR` status — reason for failure |
| `created` | boolean | `true` if the collection was successfully created or already existed; `false` otherwise. Only meaningful for Execute results. |

---

## Sanitization Rules (Functional)

Input: a single trimmed string (one line from `collectionNamesInput`).
Output: `{sanitizedName, status}`.

1. Trim leading and trailing whitespace from input.
2. Replace each of the following characters with `_`: `"`, `*`, `/`, `\`, `:`, `|`, `?`, `<`, `>`
3. Collapse consecutive `_` characters into a single `_`.
4. If the result is empty: status = `ERROR`; sanitizedName = `""`.
5. If result equals original (step 1 trimmed): status = `OK`.
6. Otherwise: status = `MODIFIED`.

---

## State Transitions

### Dialog Lifecycle

```
[Open dialog]
  → Load allCollectionSets from catalog
  → Set filteredCollectionSets = allCollectionSets
  → Initialize props with defaults
  → Display dialog

[User types in filter field]
  → filterText changes → filteredCollectionSets recomputed → popup updates

[User selects collection set]
  → selectedCollectionSet set in props

[User enters collection names]
  → collectionNamesInput updated in props

[Dry Run clicked]
  → Parse collectionNamesInput → array of CollectionNameEntry
  → Validate: at least one non-ERROR entry → ERROR dialog if not
  → Produce dryRunResults
  → Display Dry Run results dialog

[Execute clicked]
  → Validate: selectedCollectionSet not nil → ERROR dialog if nil
  → Parse collectionNamesInput → array of CollectionNameEntry
  → Validate: at least one non-ERROR entry → ERROR dialog if not
  → For each entry with status != ERROR: attempt createCollection via withWriteAccessDo
  → Produce executionResults
  → Display Execution results dialog

[Close clicked]
  → Dialog dismissed, no catalog changes
```
