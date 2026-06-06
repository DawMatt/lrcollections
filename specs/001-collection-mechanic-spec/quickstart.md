# Quickstart: Collection Mechanic Plugin

**Date**: 2026-06-03 | **Plan**: [plan.md](plan.md)

Step-by-step guide for installing the plugin in Lightroom Classic and verifying the happy path.

---

## Prerequisites

- Adobe Lightroom Classic 15.3 or later
- An active catalog with at least one collection set

---

## Installation

1. In Lightroom Classic, open **File → Plug-in Manager…**
2. Click **Add** (bottom-left).
3. Navigate to and select the `lrcollectionmechanic.lrdevplugin` directory.
4. Confirm the plugin status shows **Installed and running**.
5. Click **Done**.

> **Important**: If you add new `.lua` files to the plugin directory after Lightroom is already
> running, you must **quit and restart Lightroom** for the new files to be detected. Reloading
> the plugin via Plug-in Manager is not sufficient for new files.

---

## Launching the Plugin

From Lightroom's **Library** module:

- **Library menu → Plug-in Extras → Create Collections in Batch**, or
- **File → Plug-in Extras → Create Collections in Batch**

The Collection Mechanic dialog opens.

---

## Happy Path: Create Three Collections

1. (Optional) Type a word in the **Filter** field to narrow the collection set list.
2. Select a collection set from the **Collection Set** dropdown.
3. In the **Collection Names** field, enter:
   ```
   Event Photos
   Product Shots
   Portraits 2024
   ```
   - The **Proposed Collection Names** field on the right updates live as you type, showing
     the sanitized name for each line. All three names should appear unchanged.
4. Click **Create Collections**.
   - The main dialog closes automatically.
   - Results dialog opens and should show: "Successfully created 3 collection(s)."
5. Click **Close** on the results dialog.
6. In Lightroom's Collections panel, expand the selected collection set — the three new
   collections should appear.

---

## Verifying Character Sanitization

1. In the **Collection Names** field, enter:
   ```
   Summer/Beach 2024
   "Best Shots"
   Normal Name
   ```
2. Observe the **Proposed Collection Names** field updating live as you type:
   - `Summer/Beach 2024` → `Summer_Beach 2024` then eventually `Summer_Beach_2024`
   - `"Best Shots"` → `_Best Shots_` then eventually `_Best_Shots_`
   - `Normal Name` → `Normal Name` (unchanged)
3. Click **Create Collections** — the main dialog closes and all three collections are
   created with the sanitized names shown in the Proposed Collection Names field.

---

## Cancelling Without Creating

If you open the dialog but decide not to create any collections:

1. Click **Cancel** at any point before clicking Create Collections.
2. The dialog closes immediately — no collections are created and no changes are made to the
   catalog.

> **Note**: If you have already clicked Create Collections and collection creation is
> underway, Cancel has no effect. Creation always runs to completion once started.

---

## Checking the Log

Plugin log output is written to the Lightroom log file. To view it:

1. In Lightroom, open **Help → System Info…**
2. Note the log file path shown near the top.
3. Open the log file in a text editor — entries from the plugin are prefixed with the plugin
   name (set in `Info.PLUGINNAME`).

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Plugin not listed in Plug-in Extras | Plugin not installed or a new `.lua` file added after launch | Restart Lightroom |
| "Could not load toolkit script" error | `require` references a file that does not exist or was added after last restart | Check file name spelling; restart Lightroom if file is new |
| Collection set dropdown is empty | No collection sets in the active catalog | Create at least one collection set in Lightroom first |
| Collections not appearing after Execute | Lightroom may need a moment to refresh | Scroll the Collections panel or switch modules and return |
