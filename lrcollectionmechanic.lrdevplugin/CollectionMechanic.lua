CollectionMechanic = {}

require 'Info'
require 'Util__StringUtils'
require 'Util__CatalogUtils'
require 'UI__MainDialog'

local LrFunctionContext = import 'LrFunctionContext'
local LrLogger = import 'LrLogger'
local logger = LrLogger(Info.PLUGINNAME)

function CollectionMechanic.showCollectionMechanicDialog()
    LrFunctionContext.postAsyncTaskWithContext("CollectionMechanic", function(context)
        local LrBinding = import 'LrBinding'
        local LrDialogs = import 'LrDialogs'

        local allSets = CatalogUtils.getCollectionSets()

        local props = LrBinding.makePropertyTable(context)
        props.filterText             = ""
        props.allCollectionSets      = allSets
        props.filteredCollectionSets = allSets
        props.selectedCollectionSet  = false  -- false matches placeholder item value; nil does not
        props.collectionNamesInput   = ""
        props.proposedNamesText      = ""
        props.executionResults       = {}

        logger:info("showCollectionMechanicDialog: loaded " .. #allSets .. " collection sets")

        -- Recompute filteredCollectionSets on every filterText change (US3)
        props:addObserver("filterText", function(_, _, newValue)
            local filter = newValue or ""
            if filter == "" then
                props.filteredCollectionSets = props.allCollectionSets
            else
                local lower = string.lower(filter)
                local filtered = {}
                for _, item in ipairs(props.allCollectionSets) do
                    if string.find(string.lower(item.displayName), lower, 1, true) then
                        table.insert(filtered, item)
                    end
                end
                props.filteredCollectionSets = filtered
            end
        end)

        -- Compute proposedNamesText on every collectionNamesInput change (US2 live preview).
        -- Processes each line individually: blank lines stay blank, non-blank lines are
        -- sanitized. No LR SDK calls are made here — pure Lua string operations only.
        props:addObserver("collectionNamesInput", function(_, _, newValue)
            local input = newValue or ""
            local normalized = input:gsub("\r\n", "\n"):gsub("\r", "\n")
            local outputLines = {}
            local errorCount = 0
            local lineCount = 0
            for line in (normalized .. "\n"):gmatch("([^\n]*)\n") do
                lineCount = lineCount + 1
                local trimmed = line:match("^%s*(.-)%s*$")
                if trimmed == "" then
                    table.insert(outputLines, "")
                else
                    local result = StringUtils.sanitizeCollectionName(trimmed)
                    if result.status == "ERROR" then
                        errorCount = errorCount + 1
                        table.insert(outputLines, "<ERROR: " .. (result.errorMessage or "invalid name") .. ">")
                    else
                        table.insert(outputLines, result.sanitizedName)
                    end
                end
            end
            -- Remove the trailing empty entry added by the sentinel newline above
            if #outputLines > 0 and outputLines[#outputLines] == "" and
               (normalized == "" or normalized:sub(-1) ~= "\n") then
                table.remove(outputLines)
            end
            props.proposedNamesText = table.concat(outputLines, "\n")
            logger:debug("proposedNamesText updated: lines=" .. lineCount .. " errors=" .. errorCount)
        end)

        local contents = UIMainDialog.createMainDialog(props)

        -- Present the dialog in a loop so it can be re-shown when validation fails (FR-026).
        -- Create Collections (actionVerb) closes the dialog; Cancel (cancelVerb default) exits.
        -- FR-028: the dialog closes before creation begins, so Cancel cannot fire during creation.
        local keepShowing = true
        while keepShowing do
            local result = LrDialogs.presentModalDialog {
                title      = "Collection Mechanic",
                contents   = contents,
                actionVerb = "Create Collections",
            }

            if result == "cancel" then
                logger:info("showCollectionMechanicDialog: cancelled by user")
                keepShowing = false
            else  -- result == "ok"
                local entries, errMsg = UIMainDialog.validateInputs(props)
                if errMsg then
                    LrDialogs.message(errMsg, "", "info")
                    -- keepShowing remains true; dialog re-presents with existing props state
                else
                    local targetSet = props.selectedCollectionSet
                    logger:info("Create Collections: target=" .. (targetSet.displayName or "?") .. ", count=" .. #entries)
                    local results = CatalogUtils.createCollections(targetSet.object, entries, targetSet.displayName)
                    props.executionResults = results
                    UIMainDialog.showResultsDialog(results)
                    keepShowing = false
                end
            end
        end
    end)
end

CollectionMechanic.showCollectionMechanicDialog()
