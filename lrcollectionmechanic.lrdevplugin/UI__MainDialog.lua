require "Info"
local LrLogger          = import 'LrLogger'
local LrFunctionContext = import 'LrFunctionContext'
local logger = LrLogger(Info.PLUGINNAME)

UIMainDialog = {}

-- Popup items: placeholder value = false; real items value = {displayName, object}.
-- Storing the full item avoids calling getName() in button callbacks (C event loop context).
local function buildPopupItems(sets)
    local items = { { title = "-- Select a collection set --", value = false } }
    for _, item in ipairs(sets) do
        table.insert(items, { title = item.displayName, value = item })
    end
    return items
end

local function validateExecute(props)
    local LrDialogs = import 'LrDialogs'
    if not props.selectedCollectionSet or props.selectedCollectionSet == false then
        LrDialogs.message("Please select a collection set before proceeding.", "", "info")
        return nil
    end
    local entries = StringUtils.parseCollectionNames(props.collectionNamesInput)
    local hasValid = false
    for _, e in ipairs(entries) do
        if e.status ~= "ERROR" then hasValid = true; break end
    end
    if not hasValid then
        LrDialogs.message("Please enter at least one collection name.", "", "info")
        return nil
    end
    return entries
end

local function showExecutionResultsDialog(results)
    local LrView    = import 'LrView'
    local LrDialogs = import 'LrDialogs'
    local f = LrView.osFactory()

    local createdCount, errorCount = 0, 0
    local errorRows = {}
    for _, r in ipairs(results) do
        if r.created then
            createdCount = createdCount + 1
        else
            errorCount = errorCount + 1
            table.insert(errorRows, f:row {
                spacing = f:label_spacing(),
                f:static_text { title = r.originalName,       width_in_chars = 24 },
                f:static_text { title = r.sanitizedName,      width_in_chars = 24 },
                f:static_text { title = r.errorMessage or "", width_in_chars = 24 },
            })
        end
    end

    local children = {
        f:static_text { title = "Successfully created " .. createdCount .. " collection(s)." },
    }
    if errorCount > 0 then
        table.insert(children, f:static_text {
            title = errorCount .. " name(s) were skipped due to errors."
        })
        local tableRows = {
            f:row {
                spacing = f:label_spacing(),
                f:static_text { title = "Name",      width_in_chars = 24, font = "<system/bold>" },
                f:static_text { title = "Sanitized", width_in_chars = 24, font = "<system/bold>" },
                f:static_text { title = "Reason",    width_in_chars = 24, font = "<system/bold>" },
            }
        }
        for _, row in ipairs(errorRows) do table.insert(tableRows, row) end
        table.insert(children, f:scrolled_view {
            width = 580, height = 200,
            f:column(tableRows),
        })
    end

    local contents = f:column { spacing = f:control_spacing(), unpack(children) }
    LrDialogs.presentModalDialog {
        title      = "Execution Results",
        contents   = contents,
        actionVerb = "Close",
        cancelVerb = "< exclude >",
    }
end

-- Returns main dialog view for presentation by CollectionMechanic.lua.
-- Dialog is 50% wider than the pre-enhancement baseline:
--   filter/popup fields widened from 40 → 60 chars;
--   names area split into two equal-width columns (40 chars each = 80 chars total vs 50 before).
function UIMainDialog.createMainDialog(props)
    local LrView = import 'LrView'
    local f = LrView.osFactory()
    local executing = false  -- re-entrance guard for Execute

    -- Button callbacks run in Lightroom's C event loop and cannot yield.
    -- LrFunctionContext.postAsyncTaskWithContext creates a full LR function context
    -- that integrates with LR's task scheduler, enabling catalog writes to yield correctly.
    -- (LrTasks.startAsyncTask is insufficient — it does not register with LR's scheduler.)
    local function onExecute()
        if executing then return end
        executing = true
        LrFunctionContext.postAsyncTaskWithContext("CollectionMechanic.Execute", function(_context)
            local entries = validateExecute(props)
            if not entries then executing = false; return end
            local targetSet = props.selectedCollectionSet  -- {displayName, object}
            logger:info("Execute: target=" .. (targetSet.displayName or "?") .. ", count=" .. #entries)
            local results = CatalogUtils.createCollections(targetSet.object, entries, targetSet.displayName)
            props.executionResults = results
            showExecutionResultsDialog(results)
            executing = false
        end)
    end

    return f:column {
        bind_to_object = props,
        spacing        = f:control_spacing(),

        -- Filter row
        f:row {
            spacing = f:label_spacing(),
            f:static_text { title = "Collection Set Filter", width = LrView.share("label_width") },
            f:edit_field {
                value              = LrView.bind("filterText"),
                width_in_chars     = 60,
                placeholder_string = "Type to filter collection sets...",
            },
        },

        -- Collection Set selector
        f:row {
            spacing = f:label_spacing(),
            f:static_text { title = "Base Collection Set", width = LrView.share("label_width") },
            f:popup_menu {
                value = LrView.bind {
                    key            = "selectedCollectionSet",
                    bind_to_object = props,
                },
                items = LrView.bind {
                    key            = "filteredCollectionSets",
                    bind_to_object = props,
                    transform      = function(value)
                        return buildPopupItems(value or {})
                    end,
                },
                width_in_chars = 60,
            },
        },

        -- Two-column names area: Collection Names (editable) | Proposed Collection Names (read-only).
        -- Both columns are equal width and height; equal height_in_lines preserves line alignment
        -- when input exceeds the visible area (FR-019, FR-020).
        f:row {
            spacing = f:control_spacing(),
            fill_horizontal = 1,

            -- Left column: user input
            f:column {
                fill_horizontal = 1,
                spacing = f:label_spacing(),
                f:static_text { title = "Collection Names (one per line)" },
                f:edit_field {
                    value              = LrView.bind("collectionNamesInput"),
                    height_in_lines    = 8,
                    width_in_chars     = 40,
                    fill_horizontal    = 1,
                    font               = "<monospace>",
                    placeholder_string = "Enter collection names, one per line",
                },
            },

            -- Right column: live sanitization preview (read-only)
            f:column {
                fill_horizontal = 1,
                spacing = f:label_spacing(),
                f:static_text { title = "Proposed Collection Names" },
                f:edit_field {
                    value           = LrView.bind("proposedNamesText"),
                    height_in_lines = 8,
                    width_in_chars  = 40,
                    fill_horizontal = 1,
                    font            = "<monospace>",
                    enabled         = false,  -- read-only; updated by observer in CollectionMechanic.lua
                },
            },
        },

        f:static_text {
            title   = "To add a new line: Option+Return (Mac) or Alt+Enter (Windows)",
            enabled = false,
        },

        -- Button row: Execute on the left; Close is the standard action button (right, via presentModalDialog)
        f:row {
            spacing = f:control_spacing(),
            f:push_button { title = "Execute", action = onExecute },
        },
    }
end

return UIMainDialog
