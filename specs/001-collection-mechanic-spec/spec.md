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

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Batch Create Collections (Priority: P1)

A Lightroom Classic user wants to create many collections at once under a chosen collection
set, rather than creating them one by one through the standard Lightroom UI.

The user opens the plugin from the Library menu, selects the collection set that will contain
the new collections, types the desired collection names (one per line), and clicks Execute. The
plugin creates all listed collections in the chosen set and confirms how many were created.

**Why this priority**: Core value of the plugin — without batch creation there is no feature.

**Independent Test**: Open the plugin, select any collection set, enter three collection names,
click Execute, then verify those three collections appear in Lightroom under the selected set.

**Acceptance Scenarios**:

1. **Given** the plugin dialog is open and a collection set is selected, **When** the user
   enters one or more collection names (one per line) and clicks Execute, **Then** each
   non-empty line becomes a new collection under the selected set and a results summary is shown.
2. **Given** a collection name that already exists in the selected set, **When** the user
   clicks Execute, **Then** the existing collection is preserved (not duplicated) and the
   operation is counted as a success.
3. **Given** no collection set has been selected, **When** the user clicks Execute, **Then**
   an error message prompts the user to select a set before proceeding; the dialog remains open.
4. **Given** the collection names field is empty or contains only blank lines, **When** the
   user clicks Execute, **Then** an error message prompts the user to enter at least one name;
   no collections are created.

---

### User Story 2 - Dry Run Preview (Priority: P2)

Before committing to creating collections, a user wants to preview exactly what names will be
used — particularly to see how any special characters will be transformed — without modifying
the catalog.

**Why this priority**: Prevents unintended names from being created and builds user confidence
before the irreversible Execute step.

**Independent Test**: Enter collection names containing special characters, click Dry Run,
verify the preview table shows the original names alongside their sanitized equivalents and a
status indicator, and confirm no collections have been created in the catalog.

**Acceptance Scenarios**:

1. **Given** one or more collection names are entered, **When** the user clicks Dry Run, **Then**
   a results table is shown with three columns: original name, sanitized name, and status
   (OK / MODIFIED / ERROR) — and no collections are created.
2. **Given** a name that requires no changes, **When** Dry Run is run, **Then** its status is
   OK and the original and sanitized names are identical.
3. **Given** a name containing reserved characters, **When** Dry Run is run, **Then** its
   status is MODIFIED and the sanitized name shows the replacements applied.
4. **Given** a name that becomes empty after sanitization, **When** Dry Run is run, **Then**
   its status is ERROR and a reason is shown.
5. **Given** no collection names are entered, **When** the user clicks Dry Run, **Then** an
   error message prompts the user to enter at least one name.

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
sets reappear. Select a set and confirm Dry Run and Execute both use that selection.

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
5. **Given** the user selects a collection set after filtering, **When** Execute or Dry Run
   is clicked, **Then** the operation uses the selected set as the destination.

---

### Edge Cases

- What happens when a collection name consists entirely of reserved characters (sanitized name
  would be empty)?
- What happens when the catalog becomes unavailable mid-operation (e.g., another process locks
  it)?
- How does the plugin handle very long collection names (beyond system limits)?
- What happens when a collection set is deleted in Lightroom while the plugin dialog is open?
- How does the plugin behave when Execute is clicked multiple times rapidly?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The plugin MUST allow the user to select any collection set present in the active
  catalog as the destination for new collections.
- **FR-002**: The plugin MUST accept multiple collection names as free-form text input, one name
  per line. Line endings `\r\n` and `\r` MUST be normalised to `\n` before parsing.
- **FR-003**: The plugin MUST provide a Dry Run action that shows a preview of all name
  transformations without creating any collections.
- **FR-004**: The plugin MUST provide an Execute action that creates collections in the selected
  set using sanitized names.
- **FR-005**: The plugin MUST sanitize collection names by replacing reserved characters with
  underscores and collapsing consecutive underscores into one.
- **FR-006**: The plugin MUST trim leading and trailing whitespace from each collection name.
- **FR-007**: The plugin MUST skip blank lines in the collection names input.
- **FR-008**: The plugin MUST display a results summary after Execute showing the count of
  collections created and, for each name that resulted in ERROR status, the name and reason it
  was skipped — partial success (some created, some errored) is a valid outcome.
- **FR-009**: The plugin MUST prevent execution when no collection set is selected, with a clear
  error message.
- **FR-010**: The plugin MUST prevent execution only when *no* collection names would produce a
  valid sanitized name (i.e., the entire batch is ERROR); if at least one name is valid, Execute
  MUST proceed and report per-name outcomes.
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
- **FR-015**: The Dry Run results MUST show status per name: OK (no changes), MODIFIED
  (characters replaced), or ERROR (name invalid after sanitization).

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
- **Result Record**: The per-name outcome of a Dry Run or Execute operation — original name,
  sanitized name, status, and optional error detail.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can create 20 collections in a single operation in under 30 seconds from
  opening the plugin to seeing the confirmation summary.
- **SC-002**: Dry Run accurately reflects the names that Execute will use — zero discrepancies
  between previewed and created names across all test cases.
- **SC-003**: 100% of reserved characters in collection names are replaced during sanitization
  with no reserved characters present in any created collection name.
- **SC-004**: The plugin handles a catalog containing 500+ collection sets with filter keystrokes
  updating the collection set selector within 200ms per keystroke.
- **SC-005**: Error messages are self-explanatory — a first-time user can resolve every
  validation error without consulting documentation.
- **SC-006**: No unintended changes are made to the catalog during a Dry Run operation.

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
