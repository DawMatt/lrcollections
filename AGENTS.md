# AGENTS.md

## Purpose

This file helps AI coding agents understand the `lrcollections` project quickly so they can make safe, useful changes without needing a lot of manual discovery.

## What this project is

- A Lightroom Classic plugin named **Collection Mechanic**.
- Written in **Lua 5.1** using the **Lightroom Classic SDK v3.0**.
- Installed from the plugin folder: `lrcollectionmechanic.lrdevplugin`
- Main functionality: batch-create collections under a selected collection set with dry-run preview and execution.

## Important files

- `lrcollectionmechanic.lrdevplugin/Info.lua` — plugin registration, menu items, metadata.
- `lrcollectionmechanic.lrdevplugin/CollectionMechanic.lua` — main plugin entrypoint and dialog lifecycle.
- `lrcollectionmechanic.lrdevplugin/UI_MainDialog.lua` — UI layout and dialog rendering.
- `lrcollectionmechanic.lrdevplugin/Util_CatalogUtils.lua` — Lightroom catalog operations.
- `lrcollectionmechanic.lrdevplugin/Util_StringUtils.lua` — collection name sanitization and parsing.
- `lrcollectionmechanic.lrdevplugin/README.md` — user-facing documentation.
- `lrcollectionmechanic.lrdevplugin/DEVELOPMENT.md` — technical implementation notes.
- `LRPLUGINDEVELOPMENT.md` — project-specific Lightroom plugin conventions.
- `SPECIFICATION.md` — product requirements and UX expectations.
- `TROUBLESHOOTING.md` — support guidance and common plugin errors.

## Key conventions for edits

- `Info.lua` is the primary Lightroom plugin manifest. Changes here affect menu placement, supported SDK version, and menu enablement.
- Use `LrView`, `LrBinding`, and `LrFunctionContext` at module scope if needed.
- Import `LrCatalog`, `LrLogger`, `LrDialogs`, and other context-sensitive SDK namespaces inside functions or inside `LrFunctionContext.callWithContext()`.
- `require` is not folder-aware in Lightroom plugins. Use actual script names like `require 'Util_CatalogUtils'` for `Util_CatalogUtils.lua`.
- The plugin has a UI/dialog-first workflow; there is no build system. Validation is manual via Lightroom Classic.

## How to test changes

1. Copy the plugin folder into Lightroom Classic's plugin directory.
2. Restart Lightroom Classic.
3. Open the plugin from either the **Library** menu or **File → Plug-in Extras**.
4. Use the UI to run `Dry Run` first, then `Execute`.

## What agents should do first

- Read `LRPLUGINDEVELOPMENT.md` for Lightroom-specific Lua rules.
- Read `lrcollectionmechanic.lrdevplugin/Info.lua` to understand the current menu registration.
- Read `lrcollectionmechanic.lrdevplugin/CollectionMechanic.lua` for workflow and context requirements.
- Link rather than duplicate existing documentation when possible.

## Docs to consult

- `LRPLUGINDEVELOPMENT.md`
- `SPECIFICATION.md`
- `TROUBLESHOOTING.md`
- `lrcollectionmechanic.lrdevplugin/README.md`
- `lrcollectionmechanic.lrdevplugin/DEVELOPMENT.md`
