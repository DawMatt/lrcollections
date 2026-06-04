require "Info"
local LrLogger = import 'LrLogger'
local LrTasks  = import 'LrTasks'
local logger = LrLogger(Info.PLUGINNAME)

UIMainDialog = {}

-- Popup items: placeholder value = false; real items value = {displayName, object}
-- Storing the full item avoids calling getName() in button callbacks (which yields in C context)
local function buildPopupItems(sets)
    local items = { { title = "-- Select a collection set --", value = false } }
    for _, item in ipairs(sets) do
        table.insert(items, { title = item.displayName, value = item })
    end
    return items
end

local function validateDryRun(props)
    local LrDialogs = import 'LrDialogs'
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

local function showDryRunResultsDialog(entries)
    local LrView    = import 'LrView'
    local LrDialogs = import 'LrDialogs'
    local f = LrView.osFactory()

    local okCount, modifiedCount, errorCount = 0, 0, 0
    local rows = {}
    for _, e in ipairs(entries) do
        if e.status == "OK" then okCount = okCount + 1
        elseif e.status == "MODIFIED" then modifiedCount = modifiedCount + 1
        else errorCount = errorCount + 1 end
        table.insert(rows, f:row {
            spacing = f:label_spacing(),
            f:static_text { title = e.originalName,  width_in_chars = 28 },
            f:static_text { title = e.sanitizedName, width_in_chars = 28 },
            f:static_text { title = e.status,        width_in_chars = 10 },
        })
    end

    local summary
    if errorCount > 0 and modifiedCount > 0 then
        summary = "Some names were modified. Some names are invalid and will be skipped."
    elseif errorCount > 0 then
        summary = "Some names are invalid and will be skipped."
    elseif modifiedCount > 0 then
        summary = "Some names were modified."
    else
        summary = "All names are ready to be created."
    end

    local headerRow = f:row {
        spacing = f:label_spacing(),
        f:static_text { title = "Original Name",  width_in_chars = 28, font = "<system/bold>" },
        f:static_text { title = "Sanitized Name", width_in_chars = 28, font = "<system/bold>" },
        f:static_text { title = "Status",         width_in_chars = 10, font = "<system/bold>" },
    }
    local tableRows = { headerRow }
    for _, row in ipairs(rows) do table.insert(tableRows, row) end

    local contents = f:column {
        spacing = f:control_spacing(),
        f:static_text { title = "Dry Run complete. No collections were created." },
        f:static_text { title = summary },
        f:scrolled_view {
            width = 580, height = 300,
            f:column(tableRows),
        },
    }
    LrDialogs.presentModalDialog {
        title      = "Dry Run Results",
        contents   = contents,
        actionVerb = "Close",
        cancelVerb = "< no cancel >",
    }
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
        cancelVerb = "< no cancel >",
    }
end

-- Returns main dialog view for presentation by CollectionMechanic.lua
function UIMainDialog.createMainDialog(props)
    local LrView = import 'LrView'
    local f = LrView.osFactory()
    local executing = false  -- re-entrance guard for Dry Run and Execute

    -- Button callbacks run in Lightroom's C event loop and cannot yield.
    -- LrTasks.startAsyncTask re-enters a Lua coroutine context where SDK calls that
    -- yield (catalog reads, LrDialogs) are permitted.
    local function onDryRun()
        if executing then return end
        executing = true
        LrTasks.startAsyncTask(function()
            local entries = validateDryRun(props)
            if not entries then executing = false; return end
            props.dryRunResults = entries
            local ok, mod, err = 0, 0, 0
            for _, e in ipairs(entries) do
                if e.status == "OK" then ok = ok + 1
                elseif e.status == "MODIFIED" then mod = mod + 1
                else err = err + 1 end
            end
            logger:info("Dry Run: OK=" .. ok .. " MODIFIED=" .. mod .. " ERROR=" .. err)
            showDryRunResultsDialog(entries)
            executing = false
        end)
    end

    local function onExecute()
        if executing then return end
        executing = true
        LrTasks.startAsyncTask(function()
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
                width_in_chars     = 40,
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
                width_in_chars = 40,
            },
        },

        -- Collection Names input
        f:static_text { title = "Collection Names (one per line)" },
        f:edit_field {
            value              = LrView.bind("collectionNamesInput"),
            height_in_lines    = 8,
            width_in_chars     = 50,
            font               = "<monospace>",
            placeholder_string = "Enter collection names, one per line",
        },
        f:static_text {
            title   = "To add a new line: Option+Return (Mac) or Alt+Enter (Windows)",
            enabled = false,
        },

        -- Button row: Dry Run + Execute left; Close is the standard action button (right, via presentModalDialog)
        f:row {
            spacing = f:control_spacing(),
            f:push_button { title = "Dry Run", action = onDryRun },
            f:push_button { title = "Execute", action = onExecute },
        },
    }
end

return UIMainDialog
