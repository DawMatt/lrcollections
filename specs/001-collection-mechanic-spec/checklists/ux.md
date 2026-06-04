# UX Checklist: Collection Mechanic Plugin — Main Dialog

**Purpose**: Validate UX requirements quality for the main dialog — completeness, clarity,
consistency, and measurability of requirements as written in the spec, UI contract, and plan.
Includes accessibility requirement coverage.
**Created**: 2026-06-03
**Feature**: [spec.md](../spec.md) | [UI contract](../contracts/ui-contract.md)

**Scope**: Main dialog only (filter field, collection set selector, names input, button row).
Results dialogs and validation error dialogs are out of scope for this run.

---

## Requirement Completeness

- [x] CHK001 — Are layout ordering requirements defined for all main dialog sections (filter, selector, names input, buttons) beyond the single stated constraint that filter appears above the selector? [Completeness, Gap — UI contract defines vertical order implicitly via diagram but no formal ordering requirement in spec]
  **Resolved**: UI contract diagram updated to reflect all four sections in explicit top-to-bottom order.
- [x] CHK002 — Is a minimum and/or preferred height requirement specified for the multi-line collection names input field? [Completeness, Gap — UI contract names it scrollable but no sizing defined]
  **Resolved**: Implementation uses `height_in_lines = 8`; ui-contract updated to confirm 8-line default height.
- [x] CHK003 — Is a requirement defined for the initial focus state when the dialog opens (which control receives keyboard focus first)? [Completeness, Gap — neither spec nor UI contract defines this]
  **Resolved**: Added to ui-contract: "On dialog open, keyboard focus MUST be placed on the Collection Set Filter field."
- [x] CHK004 — Are placeholder text requirements defined for both the filter field and the names input field? [Completeness — UI contract defines both; verify spec does not conflict]
  **Confirmed**: UI contract placeholder values unchanged and consistent with implementation.
- [x] CHK005 — Is a requirement defined for the visual state of the collection set popup when no selection has been made (e.g., placeholder/prompt item)? [Completeness — UI contract defines a placeholder item; confirm spec FR-001 aligns]
  **Resolved**: Placeholder item `"-- Select a collection set --"` confirmed in ui-contract; initialisation bug fixed (selectedCollectionSet = false matches placeholder value).
- [x] CHK006 — Are requirements defined for whether button labels change or buttons become disabled during an Execute operation in progress? [Completeness, Gap — spec and UI contract are silent on in-progress button state]
  **Resolved**: Added re-entrance guard to ui-contract Button Row section; implemented via `executing` flag in `createMainDialog`.
- [ ] CHK007 — Is a requirement defined for the maximum visible height of the collection set dropdown before it becomes scrollable? [Completeness, Gap]
  **Deferred**: LR SDK controls popup height automatically based on item count and screen space. No configurable max-height property exists. Deferral noted — no action required.

---

## Requirement Clarity

- [x] CHK008 — Is "immediately" (filter response on keystroke) quantified with a specific latency threshold in the requirements? [Clarity — plan Technical Context states "no perceptible lag"; spec SC-004 says "without becoming unresponsive" — neither provides a measurable ms target]
  **Resolved**: SC-004 updated to "within 200ms per keystroke on a catalog with 500+ sets".
- [ ] CHK009 — Is "above" (filter field above collection set selector) defined as a vertical layout constraint only, or does it imply specific spacing/padding between the two controls? [Clarity — UI contract diagram shows adjacency but no spacing requirement, Spec FR-016]
  **Deferred**: Spacing is controlled by LR SDK `control_spacing()`. No pixel-level override planned for v1; spacing is LR-default.
- [x] CHK010 — Is the term "filter/search" used consistently across spec (FR-011, FR-016), UI contract, and US3, or does the inconsistency between "filter" and "search" need to be resolved in the requirements? [Clarity — Ambiguity flagged in clarification session; dual term retained but not formally resolved in spec]
  **Resolved**: Label renamed to "Collection Set Filter" throughout spec, ui-contract, and code. "Filter" is now the canonical term.
- [x] CHK011 — Is the collection set popup's behaviour when `filteredCollectionSets` becomes empty (filter matches nothing) clearly defined in the requirements? [Clarity — US3 AC3 describes narrowing; no requirement for the zero-match state, Gap]
  **Resolved**: Added to ui-contract Collection Set Popup Behaviour: "When `filteredCollectionSets` is empty, the popup shows only the placeholder item."
- [ ] CHK012 — Is "scrollable" (names input) defined with criteria for when scrolling activates (e.g., after N lines, after a pixel height threshold)? [Clarity, Spec §US2, UI contract — condition for scroll onset is unspecified]
  **Deferred**: LR SDK `edit_field` with `height_in_lines = 8` activates scrolling automatically once content exceeds 8 visible lines. No explicit trigger threshold is configurable or needed.

---

## Requirement Consistency

- [x] CHK013 — Are the input validation requirements consistent between Dry Run and Execute? Specifically: do both require "at least one non-empty name" using identical criteria, or do they differ? [Consistency — spec FR-010 applies to Execute; Dry Run scenario US2 AC5 uses same wording; verify no divergence]
  **Confirmed**: `validateDryRun` and `validateExecute` both check `e.status ~= "ERROR"` using the same logic. No divergence.
- [x] CHK014 — Does the button row requirement (Dry Run, Execute, Close on one row) in the UI contract align with the original spec's TODO note about removing duplicate close buttons, with no conflicting requirements left in the spec? [Consistency — original SPECIFICATION.md TODO described the desired change; verify no remnant contradictory requirement remains]
  **Resolved**: `presentModalDialog` updated with `actionVerb = "Close"` and `cancelVerb = "< no cancel >"`. Cancel button removed. No conflicting requirement remains.
- [x] CHK015 — Are requirements for how the selected collection set is displayed in the popup consistent between FR-013 (hierarchical format) and the UI contract's display format (`"Events » 2024 » Summer"`)? [Consistency — both use ` » ` separator; confirm no divergence in depth or truncation handling]
  **Confirmed**: Both use the same separator convention. Unicode `»` replaced with ASCII `" > "` throughout; ui-contract example updated to `"Events > 2024 > Summer"`.

---

## Interaction & State Coverage

- [x] CHK016 — Is a requirement defined for whether the current selection in the collection set popup is preserved or reset when the user modifies the filter text? [Coverage — data-model.md states selection persists; confirm this is formally captured as a spec or UI contract requirement, not only in design docs]
  **Confirmed**: T026 implements selection persistence; ui-contract Behaviour row for Collection Set Popup states "Filter changes update items without clearing the current selection if the selected item remains."
- [x] CHK017 — Is a requirement defined for what happens when the user clears all text from the filter field (i.e., all collection sets reappear)? [Coverage — US3 AC4 defines this; confirm UI contract requirement is consistent]
  **Confirmed**: US3 AC4 and the filter observer in CollectionMechanic.lua both cover this. No inconsistency.
- [x] CHK018 — Are requirements defined for the collection names input behaviour when the user pastes text containing mixed line endings (Windows `\r\n` vs Unix `\n`)? [Coverage, Gap — spec FR-002 says "one name per line" but does not specify line ending normalisation]
  **Resolved**: FR-002 updated — "`\r\n` and `\r` MUST be normalised to `\n` before parsing." Implementation already handles this in `parseCollectionNames`.
- [x] CHK019 — Is a requirement defined for whether the Dry Run results from a previous run are cleared or retained when the user modifies the collection names input after a Dry Run? [Coverage, Gap — not addressed in spec or UI contract]
  **Resolved**: Added `collectionNamesInput` observer in `CollectionMechanic.lua` that resets `props.dryRunResults = {}` on every change.

---

## Empty & Error States (Main Dialog)

- [x] CHK020 — Is a requirement defined for the state of the main dialog when the active catalog contains no collection sets at all (empty dropdown, no filter results possible)? [Coverage, Gap — spec Assumption states "at least one collection set exists"; no requirement for the zero-sets case if that assumption is violated]
  **Resolved**: Added to spec Assumptions — "If the active catalog contains no collection sets, the plugin opens with an empty selector; the user cannot proceed. No special empty-state UI is required."
- [ ] CHK021 — Is a requirement defined for how the dialog behaves if collection set loading fails or takes unexpectedly long (e.g., very large catalog)? [Coverage, Gap — plan notes synchronous load; no timeout or failure requirement stated]
  **Deferred**: Synchronous load via `getCollectionSets()` is acceptable for v1. Timeout/failure handling deferred to a future performance-hardening pass.
- [x] CHK022 — Are requirements defined for how the main dialog recovers if a validation error dialog is dismissed — specifically, is it clear that the main dialog remains open and fully interactive? [Coverage — spec US1 AC3 and US1 AC4 state "dialog remains open"; confirm UI contract aligns]
  **Confirmed**: US1 AC3, US1 AC4, and the Validation Error Dialogs section of ui-contract all state "The main dialog remains open after dismissal."

---

## Accessibility Requirements

- [x] CHK023 — Are keyboard navigation requirements defined for the main dialog — specifically, is a tab order specified for filter field → popup → names input → buttons? [Accessibility, Gap — neither spec nor UI contract defines tab order or keyboard navigation]
  **Resolved**: Accessibility deferred — added to spec Assumptions. LR SDK does not support configuring tab order; system default order applies.
- [x] CHK024 — Are screen reader label requirements defined for the filter field, collection set popup, and names input (e.g., ARIA labels or Lightroom SDK label associations)? [Accessibility, Gap]
  **Resolved**: Deferred — see CHK023 note in Assumptions.
- [x] CHK025 — Is a requirement defined for how keyboard users activate the Dry Run and Execute buttons (e.g., Enter key, Space key, or shortcut key)? [Accessibility, Gap]
  **Resolved**: Deferred — see CHK023 note in Assumptions.
- [x] CHK026 — Are focus management requirements defined for when a results or error dialog is dismissed — specifically, where keyboard focus returns in the main dialog? [Accessibility, Gap]
  **Resolved**: Deferred — see CHK023 note in Assumptions.
- [x] CHK027 — Is a requirement defined for whether the plugin UI must meet any accessibility standard (e.g., WCAG 2.1 AA) or whether accessibility support is explicitly deferred? [Accessibility — no accessibility standard referenced in spec or constitution; an explicit in/out-of-scope decision should be recorded]
  **Resolved**: Added explicit deferral to spec Assumptions — "Accessibility support is explicitly deferred from v1 scope."

---

## Acceptance Criteria Quality

- [x] CHK028 — Can SC-004 ("without the dropdown or search becoming unresponsive" with 500+ collection sets) be objectively verified without a quantified latency threshold? [Measurability — "unresponsive" is subjective; a ms-level threshold would make this testable, Spec §SC-004]
  **Resolved**: SC-004 updated to "within 200ms per keystroke on a catalog with 500+ sets."
- [ ] CHK029 — Can SC-005 ("error messages are self-explanatory — a first-time user can resolve every validation error without consulting documentation") be measured objectively, or does it require a usability study to verify? [Measurability — criterion is qualitative; consider whether a specific error message content requirement would be a more testable proxy, Spec §SC-005]
  **Accepted as-is**: SC-005 is verified by manual review of the specific error messages defined in ui-contract.md Validation Error Dialogs table. The table constitutes the testable proxy — if all four messages match the spec, SC-005 passes.
- [x] CHK030 — Are the acceptance scenarios in US3 sufficient to verify the filter field requirement independently of the collection set selection requirement, as called out in the Independent Test? [Acceptance Criteria Quality, Spec §US3]
  **Confirmed**: US3 AC1–AC5 cover: presence, empty-filter all-sets, partial-match narrowing, clear-filter restore, and selected-set used by Execute/Dry Run. Independent Test is achievable without US1/US2.

---

## Notes

- Check items off as completed: `[x]`
- Add findings inline (e.g., `[x] CHK001 — Confirmed: ordering requirement added to UI contract v2`)
- Items marked `[Gap]` indicate missing requirements that should be added to the spec or UI contract before implementation begins
- Items marked `[Ambiguity]` indicate existing requirements that need wording clarification
- Items marked `[Consistency]` should result in one canonical version of the requirement across all docs
