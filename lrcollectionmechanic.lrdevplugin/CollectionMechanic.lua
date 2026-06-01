--[[
	CollectionMechanic.lua
	
	Main plugin orchestrator for Collection Mechanic.
	Handles dialog initialization, user interactions, and workflows.
--]]

CollectionMechanic = {}

require 'Info'

local LrApplication = import 'LrApplication'
local LrFunctionContext = import 'LrFunctionContext'

local logger = import 'LrLogger'( Info.PLUGINNAME or "Debug" )
logger:enable( Info.LOGGERTARGET or "logfile" ) -- Enable logging to console
logger:info("*** CollectionMechanic loaded")

require 'Util_StringUtils'
require 'Util_CatalogUtils'
require 'UI_MainDialog'


--[[
	Main entry point for the Collection Mechanic plugin.
	Called when user selects the plugin from the menu.
--]]
function CollectionMechanic.showCollectionMechanicDialog()
	LrFunctionContext.postAsyncTaskWithContext("CollectionMechanic", function(context)
		
		-- Import SDK namespaces inside context
		local LrBinding = import 'LrBinding'
		local LrDialogs = import 'LrDialogs'
		
		-- Get all available collection sets
		local collectionSetOptions = CatalogUtils.getAllCollectionSets()
		
		if #collectionSetOptions == 0 then
			UIManager.showErrorDialog(
				"No Collection Sets Found",
				"Please create at least one collection set before using Collection Mechanic."
			)
			return
		end
		
		-- Create the observable property table
		local props = LrBinding.makePropertyTable(context)
		props.selectedCollectionSet = nil
		props.collectionNamesInput = ""
		props.dryRunResults = {}
		props.executionResults = {}
		
		-- Define button callbacks
		local callbacks = {
			onDryRun = function()
				CollectionMechanic.performDryRun(props, collectionSetOptions)
			end,
			onExecute = function()
				CollectionMechanic.performExecution(props, collectionSetOptions)
			end,
			onClose = function()
				LrDialogs.stopModalDialog("ok")
			end
		}
		
		-- Create and display the main dialog
		local dialogContents = UIManager.createMainDialog(props, collectionSetOptions, callbacks)
		
		LrDialogs.presentModalDialog {
			title = "Collection Mechanic",
			contents = dialogContents
		}
		
	end) -- end context
end

--[[
	Perform a dry run: preview name sanitization without creating collections.
	
	@param props (table) Observable properties table
	@param collectionSetOptions (array) Collection set options
--]]
function CollectionMechanic.performDryRun(props, collectionSetOptions)
	logger:info("Starting dry run...")
	
	-- Validate input
	if not props.selectedCollectionSet then
		UIManager.showErrorDialog(
			"Collection Set Required",
			"Please select a collection set before proceeding."
		)
		return
	end
	
	-- Parse collection names from input
	local rawNames = StringUtils.parseCollectionNames(props.collectionNamesInput)
	
	if #rawNames == 0 then
		UIManager.showErrorDialog(
			"No Collection Names",
			"Please enter at least one collection name."
		)
		return
	end
	
	-- Sanitize all names and build results
	local results = {}
	local validCount = 0
	
	for _, rawName in ipairs(rawNames) do
		local sanitized = StringUtils.sanitizeCollectionName(rawName)
		local status = StringUtils.getStatusFromResult(sanitized)
		
		if status ~= "ERROR" then
			validCount = validCount + 1
		end
		
		table.insert(results, {
			originalName = rawName,
			sanitizedName = sanitized.sanitizedName,
			status = status
		})
	end
	
	-- Check if any names are valid
	if validCount == 0 then
		UIManager.showErrorDialog(
			"Invalid Names",
			"All collection names resulted in invalid entries. Please review and try again."
		)
		return
	end
	
	-- Show results
	local summary = string.format("Dry Run Results: %d valid name(s) ready to be created", validCount)
	UIManager.showResultsDialog("Dry Run Preview", results, summary)
	
	logger:info("Dry run completed. Valid names: " .. validCount)
end

--[[
	Execute the collection creation.
	
	@param props (table) Observable properties table
	@param collectionSetOptions (array) Collection set options
--]]
function CollectionMechanic.performExecution(props, collectionSetOptions)
	logger:info("Starting execution...")
	
	-- Validate input
	if not props.selectedCollectionSet then
		UIManager.showErrorDialog(
			"Collection Set Required",
			"Please select a collection set before proceeding."
		)
		return
	end
	
	-- Verify collection set still exists
	if not CatalogUtils.collectionSetExists(props.selectedCollectionSet) then
		UIManager.showErrorDialog(
			"Collection Set Deleted",
			"The selected collection set no longer exists. Please select a different one."
		)
		props.selectedCollectionSet = nil
		return
	end
	
	-- Parse collection names from input
	local rawNames = StringUtils.parseCollectionNames(props.collectionNamesInput)
	
	if #rawNames == 0 then
		UIManager.showErrorDialog(
			"No Collection Names",
			"Please enter at least one collection name."
		)
		return
	end
	
	-- Sanitize all names
	local sanitizedNames = {}
	local results = {}
	
	for _, rawName in ipairs(rawNames) do
		local sanitized = StringUtils.sanitizeCollectionName(rawName)
		local status = StringUtils.getStatusFromResult(sanitized)
		
		-- Only include valid names for creation
		if status ~= "ERROR" then
			table.insert(sanitizedNames, sanitized.sanitizedName)
		end
		
		table.insert(results, {
			originalName = rawName,
			sanitizedName = sanitized.sanitizedName,
			status = status
		})
	end
	
	if #sanitizedNames == 0 then
		UIManager.showErrorDialog(
			"Invalid Names",
			"All collection names resulted in invalid entries. Please review and try again."
		)
		return
	end
	
	-- Create collections
	logger:info("Creating " .. #sanitizedNames .. " collection(s)...")
	local creationResults = CatalogUtils.createCollections(props.selectedCollectionSet, sanitizedNames)
	
	local successful = creationResults.successful
	local failed = creationResults.failed
	
	-- Build results display
	local displayResults = {}
	for _, result in ipairs(successful) do
		table.insert(displayResults, {
			originalName = result.collectionName,
			sanitizedName = result.collectionName,
			status = "CREATED"
		})
	end
	for _, result in ipairs(failed) do
		table.insert(displayResults, {
			originalName = result.collectionName,
			sanitizedName = result.message,
			status = "FAILED"
		})
	end
	
	-- Show results
	local successCount = #successful
	local failureCount = #failed
	local summary = string.format(
		"Execution Complete: %d collection(s) created successfully",
		successCount
	)
	
	if failureCount > 0 then
		summary = summary .. string.format(", %d failed", failureCount)
	end
	
	UIManager.showResultsDialog("Execution Results", displayResults, summary)
	
	logger:info("Execution completed. Created: " .. successCount .. ", Failed: " .. failureCount)
end

-- Entry point
CollectionMechanic.showCollectionMechanicDialog()
