--[[
	Util_CatalogUtils.lua
	
	Utility functions for catalog operations and collection management.
--]]

CatalogUtils = {}

require 'Info'

local LrApplication = import 'LrApplication'

local logger = import 'LrLogger'( Info.PLUGINNAME or "Debug" )
logger:enable( Info.LOGGERTARGET or "logfile" ) -- Enable logging to console
logger:info("*** CatalogUtils module loaded")

--[[
	Build a hierarchical list of all collection sets in the catalog.
	
	@return array of collection set options {displayName, collectionSet}
--]]
function CatalogUtils.getAllCollectionSets()
	local options = {}
	local catalog = LrApplication.activeCatalog()
	
	-- Get top-level collection sets
	local topSets = catalog:getChildCollectionSets()
	
	for _, collectionSet in ipairs(topSets) do
		CatalogUtils._addCollectionSetOption(collectionSet, "", options)
	end
	
	return options
end

--[[
	Recursively add collection set options with hierarchical names.
	
	@param collectionSet (LrCollectionSet) The collection set to add
	@param prefix (string) Current hierarchy prefix
	@param options (table) Array to accumulate options
--]]
function CatalogUtils._addCollectionSetOption(collectionSet, prefix, options)
	local name = collectionSet:getName()
	local displayName = prefix
	
	if displayName == "" then
		displayName = name
	else
		displayName = displayName .. " » " .. name
	end
	
	table.insert(options, {
		displayName = displayName,
		collectionSet = collectionSet
	})
	
	-- Add nested collection sets
	local childSets = collectionSet:getChildCollectionSets()
	for _, childSet in ipairs(childSets) do
		CatalogUtils._addCollectionSetOption(childSet, displayName, options)
	end
end

--[[
	Create multiple collections under a specified collection set.
	
	@param collectionSet (LrCollectionSet) The parent collection set
	@param collectionNames (array of string) Names of collections to create
	@return {
		successful = array of result objects,
		failed = array of result objects
	}
--]]
function CatalogUtils.createCollections(collectionSet, collectionNames)
	local successful = {}
	local failed = {}
	local catalog = LrApplication.activeCatalog()
	
	if not collectionSet or not collectionNames or #collectionNames == 0 then
		logger:warn("Invalid arguments to createCollections")
		return { successful = successful, failed = failed }
	end
	
	-- Check if catalog is accessible for writing
	if not catalog:canFileAccess() then
		logger:warn("Catalog file access not available")
		failed = {
			{
				collectionName = "N/A",
				status = "ERROR",
				message = "Catalog is not accessible"
			}
		}
		return { successful = successful, failed = failed }
	end
	
	-- Create collections within write access context
	local status = catalog:withWriteAccessDo(
		"Create Collections",
		function()
			for _, collectionName in ipairs(collectionNames) do
				local success = false
				local errorMsg = nil
				
				-- Use pcall to catch any errors
				local ok, result = pcall(function()
					-- Try to create the collection
					-- canReturnPrior = true means if collection already exists, return it instead of error
					return catalog:createCollection(
						collectionName,
						collectionSet,
						true  -- canReturnPrior
					)
				end)
				
				if ok and result then
					success = true
					logger:info("Created collection: " .. collectionName)
					table.insert(successful, {
						collectionName = collectionName,
						status = "OK",
						message = "Collection created successfully"
					})
				else
					errorMsg = tostring(result) or "Unknown error"
					logger:warn("Failed to create collection: " .. collectionName .. " - " .. errorMsg)
					table.insert(failed, {
						collectionName = collectionName,
						status = "ERROR",
						message = errorMsg
					})
				end
			end
		end,
		{
			timeout = 60,
			callback = function()
				logger:warn("Collection creation operation timed out")
			end
		}
	)
	
	return {
		successful = successful,
		failed = failed
	}
end

--[[
	Check if a collection set still exists in the catalog.
	
	@param collectionSet (LrCollectionSet) The collection set to verify
	@return boolean True if collection set exists
--]]
function CatalogUtils.collectionSetExists(collectionSet)
	if not collectionSet then
		return false
	end
	-- Note: No imports needed here, just using object methods
	
	-- Try to get the name; if it fails, the collection set has been deleted
	local ok, result = pcall(function()
		return collectionSet:getName()
	end)
	
	return ok and result and result ~= ""
end

return CatalogUtils
