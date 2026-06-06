# Feature Specification: Collection Mechanic Plugin

**Feature Branch**: `001-collection-mechanic-spec`

**Created**: 2026-06-03

**Status**: Draft

**Input**: User description: "Build a replacement specification based upon the existing specification within SPECIFICATION.md."

## Clarifications

### Session 2026-06-03

- Q: When Execute runs a batch where some names sanitize to ERROR and others are valid, what happens? → A: Create all names that sanitize successfully; include ERROR names in the results summary with their reason — partial success is allowed.
- Q: Are duplicate detection (FR-012) and the collection set filter field (FR-011/FR-016) case-sensitive or case-insensitive? → A: Case-insensitive for both.
- Q: Is there a maximum number of collection names that can be submitted in a single batch? → A: No enforced limit — accept any number of names.

### Session 2026-06-06

- Q: If Cancel is clicked while collection creation is in progress (after Create Collections was clicked), what should happen? → A: The LR SDK cannot disable the Cancel button at runtime, so Cancel is silently ignored during active creation; creation runs to completion and the results summary is displayed normally.
- Q: After the results dialog is dismissed following successful collection creation, what state is the plugin in? → A: Workflow complete; the main dialog does not reappear. Control returns to Lightroom; the user must re-open the plugin for another batch.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Batch Create Collections (Priority: P1)

A Lightroom Classic user wants to create many collections at once under a chosen collection
set, rather than creating them one by one through the standard Lightroom UI.

The user opens the plugin from the Library menu, selects the collection set that will contain
the new collections, types the desired collection names (one per line, using Option+Return
(Mac) or Alt+Enter (Windows) to create a newline), and clicks Create Collections. The plugin
creates all listed collections in the chosen set, closes the dialog, and confirms how many
were created.

**Why this priority**: Core value of the plugin — without batch creation there is no feature.

**Independent Test**: Open the plugin, select any collection set, enter three collection names,
click Create Collections — verify the dialog closes, the results summary appears showing three
collections created, and those three collections appear in Lightroom under the selected set.

**Acceptance Scenarios**:

1. **Given** the plugin dialog is open and a collection set is selected, **When** the user
   enters one or more collection names (one per line, using Option+Return
(Mac) or Alt+Enter (Windows) to create a newline) and clicks Create Collections, **Then**
   the dialog closes, each non-empty line becomes a new collection under the selected set, and
   a results summary is shown.
2. **Given** a collection name that already exists in the selected set, **When** the user
   clicks Create Collections, **Then** the existing collection is preserved (not duplicated)
   and the operation is counted as a success.
3. **Given** no collection set has been selected, **When** the user clicks Create Collections,
   **Then** an error message prompts the user to select a set before proceeding; the dialog
   remains open.
4. **Given** the collection names field is empty or contains only blank lines, **When** the
   user clicks Create Collections, **Then** an error message prompts the user to enter at least
   one name; no collections are created.

---

### User Story 2 - Live Sanitization Preview (Priority: P2)

Before committing to creating collections, a user wants to see exactly what names will be
used — particularly how any special characters will be transformed — without any additional
button press or waiting. As the user types collection names, a second read-only field
alongside the input immediately shows the sanitized equivalent of each name, or an error
message if a name cannot be used.

**Why this priority**: Prevents unintended names from being created and builds user confidence
before the irreversible Execute step. Live preview is faster and more intuitive than a
separate button press, and eliminates the round-trip of clicking Dry Run then returning to
edit names.

**Independent Test**: Enter collection names containing special characters in the Collection
Names field and observe that the Proposed Collection Names field immediately updates to show
sanitized equivalents (or `<ERROR: ...>` messages) without pressing any button. Verify both
fields are equal height and that no collections have been created in the catalog.

**Acceptance Scenarios**:

1. **Given** the user is entering collection names, **When** any change is made to the
   Collection Names field (including individual keystrokes), **Then** the Proposed Collection
   Names field updates without any button press to show the sanitized result for every line.
2. **Given** a name that requires no changes, **When** it appears in the Proposed Collection
   Names field, **Then** the proposed name is identical to the entered name.
3. **Given** a name containing reserved characters, **When** it appears in the Proposed
   Collection Names field, **Then** the reserved characters are replaced and the proposed
   name reflects the sanitized result.
4. **Given** a name that becomes empty after sanitization, **When** it appears in the Proposed
   Collection Names field, **Then** that line shows `<ERROR: description>` explaining why the
   name is invalid.
5. **Given** both fields contain more lines than are visible at once, **When** the user
   scrolls either field, **Then** each field may be scrolled independently; corresponding
   lines remain identifiable because both fields are the same height and line count.
6. **Given** the Collection Names field is empty, **When** the dialog is open, **Then** the
   Proposed Collection Names field is also empty.

---

### User Story 3 - Collection Set Filter (Priority: P3)

Within the main plugin dialog, a user working with a large Lightroom catalog needs to quickly
narrow down the collection set list without scrolling through hundreds of entries. A filter
field sits above the collection set selector in the same dialog: the user types any fragment of
a set name and the selector immediately shrinks to show only matching entries. Each entry
displays its full ancestry path (e.g., "Events » 2024 » Summer"), so the collection set's
context within the hierarchy is always visible regardless of which level matches.

**Why this priority**: The core dialog already works without the filter (US1 and US2 are
independently functional), but the filter is essential for usability in large catalogs.

**Independent Test**: Open the plugin dialog (the same dialog used for US1 and US2), type a
partial name into the filter field at the top of the collection set section, and verify the
collection set selector below it narrows to matching entries. Clear the filter and verify all
sets reappear. Select a set and confirm Execute uses that selection.

**Acceptance Scenarios**:

1. **Given** the main plugin dialog is open, **When** the collection set section is displayed,
   **Then** a filter field appears above the collection set selector within the same dialog.
2. **Given** the filter field is empty, **When** the collection set selector is displayed,
   **Then** all collection sets in the catalog are listed with hierarchy indicated
   (e.g., "Parent » Child » Grandchild").
3. **Given** text is entered in the filter field, **When** the collection set selector updates,
   **Then** only entries whose full hierarchical display name contains the filter text
   (case-insensitive) are shown — ancestry is visible via the display name
   (e.g., filtering "2024" shows "Events » 2024 » Summer" with the parent path included).
4. **Given** the filter field is cleared, **When** the selector updates, **Then** all collection
   sets reappear.
5. **Given** the user selects a collection set after filtering, **When** Create Collections is
   clicked, **Then** the operation uses the selected set as the destination.

---

### User Story 4 - Cancel Without Creating (Priority: P1)

A user who has opened the plugin dialog — perhaps to inspect the collection set list or by
accident — wants to exit without creating any collections. A dedicated Cancel button dismisses
the dialog without touching the catalog.

**Why this priority**: Cancel is a fundamental safety mechanism. Without it, any dismissal of
the dialog would risk creating collections; users expect to be able to abandon a dialog without
side effects.

**Independent Test**: Open the dialog, select a collection set, enter collection names, then
click Cancel — verify the dialog closes and no new collections appear in the catalog under any
collection set.

**Acceptance Scenarios**:

1. **Given** the dialog is open with any content, **When** the user clicks Cancel, **Then**
   the dialog closes and no collections are created.
2. **Given** the user has typed collection names and selected a collection set, **When** the
   user clicks Cancel, **Then** none of the entered names are created as collections.
3. **Given** the dialog is open with no inputs entered, **When** the user clicks Cancel,
   **Then** the dialog closes with no side effects.

---

### Edge Cases

- What happens when a collection name consists entirely of reserved characters (sanitized name
  would be empty)?
- What happens when the catalog becomes unavailable mid-operation (e.g., another process locks
  it)?
- How does the plugin handle very long collection names (beyond system limits)?
- What happens when a collection set is deleted in Lightroom while the plugin dialog is open?
- How does the plugin behave when Create Collections is clicked multiple times rapidly (double-click)? → Subsequent clicks are silently ignored until the current operation completes (FR-028).
- What happens if Cancel is clicked immediately after Create Collections while collection creation is in progress? → Cancel is silently ignored; creation runs to completion and the results summary is shown (FR-028).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The plugin MUST allow the user to select any collection set present in the active
  catalog as the destination for new collections.
- **FR-002**: The plugin MUST accept multiple collection names as free-form text input, one name
  per line. Line endings `\r\n` and `\r` MUST be normalised to `\n` before parsing.
- **FR-003**: The plugin MUST display a read-only Proposed Collection Names field adjacent to
  the Collection Names input field. For each line in the Collection Names field, the Proposed
  Collection Names field MUST show exactly one of: the sanitized collection name (which may be
  identical to the input if no changes are needed), or `<ERROR: description>` if sanitization
  fails or would produce an empty name. This field is system-generated output and its content
  is not subject to the character sanitization rules that apply to user input.
- **FR-004**: The plugin MUST provide a Create Collections action that creates collections in
  the selected set using sanitized names. This action is associated with the primary action
  button of the main dialog (FR-024); there is no separate Execute push button (FR-023).
- **FR-005**: The plugin MUST sanitize collection names by replacing reserved characters with
  underscores and collapsing consecutive underscores into one.
- **FR-006**: The plugin MUST trim leading and trailing whitespace from each collection name.
- **FR-007**: The plugin MUST skip blank lines in the collection names input.
- **FR-008**: The plugin MUST display a results summary after collection creation showing the
  count of collections created and, for each name that resulted in ERROR status, the name and
  reason it was skipped — partial success (some created, some errored) is a valid outcome.
- **FR-009**: The plugin MUST prevent collection creation when no collection set is selected,
  with a clear error message; the dialog MUST remain open.
- **FR-010**: The plugin MUST prevent collection creation only when *no* collection names would
  produce a valid sanitized name (i.e., the entire batch is ERROR); if at least one name is
  valid, the Create Collections action MUST proceed and report per-name outcomes.
- **FR-011**: The plugin MUST provide a filter field within the main dialog that narrows
  the collection set selector by case-insensitive partial name match.
- **FR-016**: The filter field MUST appear above the collection set selector within the
  same dialog section, so the user filters first and then selects.
- **FR-012**: If a collection with the same name already exists in the target set (compared
  case-insensitively), the plugin MUST treat it as a success rather than an error.
- **FR-013**: The plugin MUST display collection sets in a hierarchical format to distinguish
  sets with the same name at different levels.
- **FR-014**: The plugin MUST be accessible from both the Library menu and the Plug-in Extras
  menu.
- **FR-017**: The main plugin dialog MUST be 50% wider than the dialog width before this
  enhancement.
- **FR-018**: The Collection Names input area MUST be divided into two equal-width adjacent
  columns: the left column labelled "Collection Names" and the right column labelled "Proposed
  Collection Names". Together both columns and their respective scroll bars MUST span the full
  width of the dialog content area.
- **FR-019**: The Proposed Collection Names field MUST be the same height as the Collection
  Names field.
- **FR-020**: The Collection Names and Proposed Collection Names fields SHOULD maintain visible
  alignment between corresponding lines. Both fields MUST use identical height configuration.
  When input exceeds the visible area, individual scrolling of each field is acceptable; line
  correspondence is preserved by the equal height of both fields.
- **FR-021**: The Proposed Collection Names field MUST be read-only; the user MUST NOT be able
  to type or paste directly into it.
- **FR-022**: The Proposed Collection Names field MUST update in response to every change in
  the Collection Names field — whether the change is a single keystroke, completing a line,
  or focus leaving the Collection Names field.

- **FR-023**: The main dialog MUST NOT contain a separate Execute push button. The collection
  creation action MUST be associated with the primary action button of the dialog (FR-024).
- **FR-024**: The main dialog MUST provide a primary action button labelled "Create Collections"
  that, when clicked, validates inputs and — if valid — creates collections in the selected
  collection set using sanitized names and displays the execution results summary.
- **FR-025**: The main dialog MUST provide a Cancel button that dismisses the dialog without
  creating any collections, regardless of what has been entered in the dialog.
- **FR-026**: Clicking the primary action button MUST perform input validation: a collection
  set MUST be selected and at least one collection name MUST produce a valid sanitized name;
  if either condition is unmet, an error message MUST be shown and the dialog MUST remain open.
- **FR-027**: The partial-success behaviour defined in FR-010 MUST be preserved: if some names
  are valid and some are invalid, valid names are created and all outcomes are reported in the
  results summary.
- **FR-028**: Once collection creation begins (after Create Collections validation passes),
  any Cancel interaction MUST be silently ignored until creation completes and the results
  summary is displayed. Collection creation MUST always run to completion; it cannot be
  interrupted mid-batch.

### Character Sanitization Rules

Reserved characters that MUST be replaced with an underscore (`_`):

- Quotation mark `"`
- Asterisk `*`
- Forward slash `/`
- Backslash `\`
- Colon `:`
- Pipe `|`
- Question mark `?`
- Less-than `<` and greater-than `>`

Post-replacement: consecutive underscores MUST be collapsed to a single underscore.

### Key Entities

- **Collection Set**: A named folder-like grouping in the catalog that can contain collections
  and other collection sets. Selected by the user as the destination.
- **Collection**: A named group of photos within a collection set. Created by the plugin.
- **Collection Name Entry**: A single line of user input representing one intended collection
  name, before or after sanitization.
- **Sanitized Name**: The collection name after reserved characters are replaced and the result
  is trimmed and collapsed.
- **Result Record**: The per-name outcome of an Execute operation — original name, sanitized
  name, status, and optional error detail.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can create 20 collections in a single operation in under 30 seconds from
  opening the plugin to seeing the confirmation summary.
- **SC-002**: The Proposed Collection Names field accurately reflects the names that Execute
  will use — zero discrepancies between the live preview and the names of collections actually
  created across all test cases.
- **SC-003**: 100% of reserved characters in collection names are replaced during sanitization
  with no reserved characters present in any created collection name.
- **SC-004**: The plugin handles a catalog containing 500+ collection sets with filter keystrokes
  updating the collection set selector within 200ms per keystroke.
- **SC-005**: Error messages are self-explanatory — a first-time user can resolve every
  validation error without consulting documentation.
- **SC-006**: The Proposed Collection Names field is purely read-only and does not create,
  modify, or delete any catalog entries; all catalog changes are confined to the Create
  Collections action.
- **SC-007**: A user can create collections and see the results summary via the Create
  Collections button in under 30 seconds from dialog open to results summary — the same total
  time as the previous Execute button path.
- **SC-008**: Clicking Cancel never results in any collections being created — 100% of Cancel
  interactions leave the catalog unchanged.
- **SC-009**: The Create Collections button and Cancel button are immediately visible and
  distinguishable to a first-time user without consulting documentation.

## Assumptions

- The user has Lightroom Classic open with an active catalog when using the plugin.
- The catalog contains at least one collection set for the destination selector to populate.
- Collection names up to 255 characters are considered valid; names exceeding this limit are
  treated as errors.
- There is no enforced upper limit on the number of collection names submitted in a single
  batch; the plugin accepts any quantity.
- Unicode characters that are not in the reserved list are acceptable in collection names.
- The plugin does not need to support undo — Lightroom's catalog undo system covers collection
  creation.
- No preferences panel or persistent settings are required for v1.
- The plugin operates on the currently active catalog only; multi-catalog scenarios are out of
  scope.
- Mobile app synchronisation behaviour of collections is out of scope for this specification.
- If the active catalog contains no collection sets, the plugin opens with an empty "Base
  Collection Set" selector showing only the placeholder item; the user cannot proceed until
  a collection set is available. No special empty-state UI is required.
- Accessibility support (keyboard tab order, screen reader labels, keyboard shortcuts for
  buttons) is explicitly deferred from v1 scope. Lightroom Classic SDK limitations prevent
  full WCAG compliance.
- Pixel-level scroll position synchronisation between the Collection Names and Proposed
  Collection Names fields is not achievable within the plugin hosting environment; equal
  field heights (FR-019, FR-020) ensure line-level correspondence is always maintained.
- After the results dialog is dismissed, the plugin workflow is complete. The main dialog
  does not reappear; the user must re-open the plugin via the Library menu to create another
  batch. No persistent dialog state is carried between sessions.
- The Cancel button cannot be programmatically disabled at runtime within the plugin hosting
  environment. FR-028's "silently ignored" behaviour is enforced in code rather than through
  UI disablement.
