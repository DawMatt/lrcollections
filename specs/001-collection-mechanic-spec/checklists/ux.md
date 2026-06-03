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

- [ ] CHK001 — Are layout ordering requirements defined for all main dialog sections (filter, selector, names input, buttons) beyond the single stated constraint that filter appears above the selector? [Completeness, Gap — UI contract defines vertical order implicitly via diagram but no formal ordering requirement in spec]
- [ ] CHK002 — Is a minimum and/or preferred height requirement specified for the multi-line collection names input field? [Completeness, Gap — UI contract names it scrollable but no sizing defined]
- [ ] CHK003 — Is a requirement defined for the initial focus state when the dialog opens (which control receives keyboard focus first)? [Completeness, Gap — neither spec nor UI contract defines this]
- [ ] CHK004 — Are placeholder text requirements defined for both the filter field and the names input field? [Completeness — UI contract defines both; verify spec does not conflict]
- [ ] CHK005 — Is a requirement defined for the visual state of the collection set popup when no selection has been made (e.g., placeholder/prompt item)? [Completeness — UI contract defines a placeholder item; confirm spec FR-001 aligns]
- [ ] CHK006 — Are requirements defined for whether button labels change or buttons become disabled during an Execute operation in progress? [Completeness, Gap — spec and UI contract are silent on in-progress button state]
- [ ] CHK007 — Is a requirement defined for the maximum visible height of the collection set dropdown before it becomes scrollable? [Completeness, Gap]

---

## Requirement Clarity

- [ ] CHK008 — Is "immediately" (filter response on keystroke) quantified with a specific latency threshold in the requirements? [Clarity — plan Technical Context states "no perceptible lag"; spec SC-004 says "without becoming unresponsive" — neither provides a measurable ms target]
- [ ] CHK009 — Is "above" (filter field above collection set selector) defined as a vertical layout constraint only, or does it imply specific spacing/padding between the two controls? [Clarity — UI contract diagram shows adjacency but no spacing requirement, Spec FR-016]
- [ ] CHK010 — Is the term "filter/search" used consistently across spec (FR-011, FR-016), UI contract, and US3, or does the inconsistency between "filter" and "search" need to be resolved in the requirements? [Clarity — Ambiguity flagged in clarification session; dual term retained but not formally resolved in spec]
- [ ] CHK011 — Is the collection set popup's behaviour when `filteredCollectionSets` becomes empty (filter matches nothing) clearly defined in the requirements? [Clarity — US3 AC3 describes narrowing; no requirement for the zero-match state, Gap]
- [ ] CHK012 — Is "scrollable" (names input) defined with criteria for when scrolling activates (e.g., after N lines, after a pixel height threshold)? [Clarity, Spec §US2, UI contract — condition for scroll onset is unspecified]

---

## Requirement Consistency

- [ ] CHK013 — Are the input validation requirements consistent between Dry Run and Execute? Specifically: do both require "at least one non-empty name" using identical criteria, or do they differ? [Consistency — spec FR-010 applies to Execute; Dry Run scenario US2 AC5 uses same wording; verify no divergence]
- [ ] CHK014 — Does the button row requirement (Dry Run, Execute, Close on one row) in the UI contract align with the original spec's TODO note about removing duplicate close buttons, with no conflicting requirements left in the spec? [Consistency — original SPECIFICATION.md TODO described the desired change; verify no remnant contradictory requirement remains]
- [ ] CHK015 — Are requirements for how the selected collection set is displayed in the popup consistent between FR-013 (hierarchical format) and the UI contract's display format (`"Events » 2024 » Summer"`)? [Consistency — both use ` » ` separator; confirm no divergence in depth or truncation handling]

---

## Interaction & State Coverage

- [ ] CHK016 — Is a requirement defined for whether the current selection in the collection set popup is preserved or reset when the user modifies the filter text? [Coverage — data-model.md states selection persists; confirm this is formally captured as a spec or UI contract requirement, not only in design docs]
- [ ] CHK017 — Is a requirement defined for what happens when the user clears all text from the filter field (i.e., all collection sets reappear)? [Coverage — US3 AC4 defines this; confirm UI contract requirement is consistent]
- [ ] CHK018 — Are requirements defined for the collection names input behaviour when the user pastes text containing mixed line endings (Windows `\r\n` vs Unix `\n`)? [Coverage, Gap — spec FR-002 says "one name per line" but does not specify line ending normalisation]
- [ ] CHK019 — Is a requirement defined for whether the Dry Run results from a previous run are cleared or retained when the user modifies the collection names input after a Dry Run? [Coverage, Gap — not addressed in spec or UI contract]

---

## Empty & Error States (Main Dialog)

- [ ] CHK020 — Is a requirement defined for the state of the main dialog when the active catalog contains no collection sets at all (empty dropdown, no filter results possible)? [Coverage, Gap — spec Assumption states "at least one collection set exists"; no requirement for the zero-sets case if that assumption is violated]
- [ ] CHK021 — Is a requirement defined for how the dialog behaves if collection set loading fails or takes unexpectedly long (e.g., very large catalog)? [Coverage, Gap — plan notes synchronous load; no timeout or failure requirement stated]
- [ ] CHK022 — Are requirements defined for how the main dialog recovers if a validation error dialog is dismissed — specifically, is it clear that the main dialog remains open and fully interactive? [Coverage — spec US1 AC3 and US1 AC4 state "dialog remains open"; confirm UI contract aligns]

---

## Accessibility Requirements

- [ ] CHK023 — Are keyboard navigation requirements defined for the main dialog — specifically, is a tab order specified for filter field → popup → names input → buttons? [Accessibility, Gap — neither spec nor UI contract defines tab order or keyboard navigation]
- [ ] CHK024 — Are screen reader label requirements defined for the filter field, collection set popup, and names input (e.g., ARIA labels or Lightroom SDK label associations)? [Accessibility, Gap]
- [ ] CHK025 — Is a requirement defined for how keyboard users activate the Dry Run and Execute buttons (e.g., Enter key, Space key, or shortcut key)? [Accessibility, Gap]
- [ ] CHK026 — Are focus management requirements defined for when a results or error dialog is dismissed — specifically, where keyboard focus returns in the main dialog? [Accessibility, Gap]
- [ ] CHK027 — Is a requirement defined for whether the plugin UI must meet any accessibility standard (e.g., WCAG 2.1 AA) or whether accessibility support is explicitly deferred? [Accessibility — no accessibility standard referenced in spec or constitution; an explicit in/out-of-scope decision should be recorded]

---

## Acceptance Criteria Quality

- [ ] CHK028 — Can SC-004 ("without the dropdown or search becoming unresponsive" with 500+ collection sets) be objectively verified without a quantified latency threshold? [Measurability — "unresponsive" is subjective; a ms-level threshold would make this testable, Spec §SC-004]
- [ ] CHK029 — Can SC-005 ("error messages are self-explanatory — a first-time user can resolve every validation error without consulting documentation") be measured objectively, or does it require a usability study to verify? [Measurability — criterion is qualitative; consider whether a specific error message content requirement would be a more testable proxy, Spec §SC-005]
- [ ] CHK030 — Are the acceptance scenarios in US3 sufficient to verify the filter field requirement independently of the collection set selection requirement, as called out in the Independent Test? [Acceptance Criteria Quality, Spec §US3]

---

## Notes

- Check items off as completed: `[x]`
- Add findings inline (e.g., `[x] CHK001 — Confirmed: ordering requirement added to UI contract v2`)
- Items marked `[Gap]` indicate missing requirements that should be added to the spec or UI contract before implementation begins
- Items marked `[Ambiguity]` indicate existing requirements that need wording clarification
- Items marked `[Consistency]` should result in one canonical version of the requirement across all docs
