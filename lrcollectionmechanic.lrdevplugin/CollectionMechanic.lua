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
        props.filterText            = ""
        props.allCollectionSets     = allSets
        props.filteredCollectionSets = allSets
        props.selectedCollectionSet = nil
        props.collectionNamesInput  = ""
        props.dryRunResults         = {}
        props.executionResults      = {}

        logger:info("showCollectionMechanicDialog: loaded " .. #allSets .. " collection sets")

        -- Filter observer: recompute filteredCollectionSets on every filterText change
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

        local contents = UIMainDialog.createMainDialog(props)

        LrDialogs.presentModalDialog {
            title    = "Collection Mechanic",
            contents = contents,
        }
    end)
end

CollectionMechanic.showCollectionMechanicDialog()
