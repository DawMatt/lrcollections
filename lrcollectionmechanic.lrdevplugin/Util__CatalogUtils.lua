require "Info"
local LrLogger = import 'LrLogger'
local LrApplication = import 'LrApplication'
local logger = LrLogger(Info.PLUGINNAME)

CatalogUtils = {}

local function collectSets(parent, prefix, results)
    local sets = parent:getChildCollectionSets()
    for _, set in ipairs(sets) do
        local name = set:getName()
        local display = prefix == "" and name or (prefix .. " > " .. name)
        table.insert(results, { displayName = display, object = set })
        collectSets(set, display, results)
    end
end

-- Returns flat array of {displayName, object} for all collection sets
function CatalogUtils.getCollectionSets()
    local catalog = LrApplication.activeCatalog()
    local results = {}
    collectSets(catalog, "", results)
    logger:info("getCollectionSets: found " .. #results .. " sets")
    return results
end

-- entries: array of CollectionNameEntry {originalName, sanitizedName, status}
-- Returns entries array with added fields: created (bool), errorMessage (string|nil)
function CatalogUtils.createCollections(targetSet, entries, targetName)
    local catalog = LrApplication.activeCatalog()
    local results = {}

    logger:info("createCollections: starting, target=" .. (targetName or "?") .. ", count=" .. #entries)

    catalog:withWriteAccessDo("Create Collections", function()
        for _, entry in ipairs(entries) do
            if entry.status == "ERROR" then
                logger:warn("createCollections: skipping ERROR entry: " .. entry.originalName)
                table.insert(results, {
                    originalName  = entry.originalName,
                    sanitizedName = entry.sanitizedName,
                    status        = entry.status,
                    created       = false,
                    errorMessage  = "Invalid name — skipped",
                })
            else
                -- Case-insensitive duplicate check
                local existingCollections = targetSet:getChildCollections()
                local alreadyExists = false
                for _, col in ipairs(existingCollections) do
                    if string.lower(col:getName()) == string.lower(entry.sanitizedName) then
                        alreadyExists = true
                        break
                    end
                end

                if alreadyExists then
                    logger:info("createCollections: already exists (case-insensitive): " .. entry.sanitizedName)
                    table.insert(results, {
                        originalName  = entry.originalName,
                        sanitizedName = entry.sanitizedName,
                        status        = entry.status,
                        created       = true,
                        errorMessage  = nil,
                    })
                else
                    local ok, created = pcall(function()
                        return catalog:createCollection(entry.sanitizedName, targetSet, true)
                    end)
                    local resultEntry = {
                        originalName  = entry.originalName,
                        sanitizedName = entry.sanitizedName,
                        status        = entry.status,
                        created       = ok and created ~= nil,
                        errorMessage  = ok and nil or tostring(created),
                    }
                    if not ok then
                        logger:warn("createCollections: failed to create '" .. entry.sanitizedName .. "': " .. tostring(created))
                    end
                    table.insert(results, resultEntry)
                end
            end
        end
    end)

    local createdCount = 0
    local errorCount = 0
    for _, r in ipairs(results) do
        if r.created then createdCount = createdCount + 1 else errorCount = errorCount + 1 end
    end
    logger:info("createCollections: done, created=" .. createdCount .. ", errors=" .. errorCount)

    return results
end

return CatalogUtils
