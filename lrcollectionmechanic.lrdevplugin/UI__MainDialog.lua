require "Info"
local LrLogger = import 'LrLogger'
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

-- Validates dialog inputs. Returns the parsed entries array on success, or nil + error
-- message string on failure. Called from CollectionMechanic.lua after the actionVerb
-- button is clicked (FR-026).
function UIMainDialog.validateInputs(props)
    if not props.selectedCollectionSet or props.selectedCollectionSet == false then
        return nil, "Please select a collection set before proceeding."
    end
    local entries = StringUtils.parseCollectionNames(props.collectionNamesInput)
    local hasValid = false
    for _, e in ipairs(entries) do
        if e.status ~= "ERROR" then hasValid = true; break end
    end
    if not hasValid then
        return nil, "Please enter at least one collection name."
    end
    return entries
end

-- Shows the Execution Results dialog after collection creation completes.
-- Called from CollectionMechanic.lua once the main dialog has already closed (FR-024).
function UIMainDialog.showResultsDialog(results)
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
--   names area split into two equal-width columns (40 chars each).
-- No push_buttons in the view — Create Collections (actionVerb) and Cancel (cancelVerb)
-- are provided by presentModalDialog in CollectionMechanic.lua (FR-023, FR-024, FR-025).
function UIMainDialog.createMainDialog(props)
    local LrView = import 'LrView'
    local f = LrView.osFactory()

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
                    placeholder_string = "Enter collection names, one per line, using "
                        .. ((WIN_ENV and "Alt+Enter") or "Option+Return") .. " to create a new line",
                },
            },

            -- Right column: live sanitization preview (read-only; updated by observer in CollectionMechanic.lua)
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
                    enabled         = false,
                },
            },
        },
    }
end

return UIMainDialog
