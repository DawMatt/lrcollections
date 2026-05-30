--[[
	Localization strings for Collection Mechanic plugin.
	
	These strings support multiple languages. English is provided here.
--]]

return {
	
	en = {
		-- Plugin name and menu item
		["$$$/CollectionMechanic/PluginName"] = "Collection Mechanic",
		["$$$/CollectionMechanic/MenuTitle"] = "Create Collections in Batch",
		
		-- Dialog titles and labels
		["$$$/CollectionMechanic/DialogTitle"] = "Collection Mechanic",
		["$$$/CollectionMechanic/CollectionSetLabel"] = "Root Collection Set:",
		["$$$/CollectionMechanic/CollectionSetHelp"] = "Select the collection set where new collections will be created",
		["$$$/CollectionMechanic/InputLabel"] = "Collection Names (one per line):",
		["$$$/CollectionMechanic/InputHelp"] = "Enter collection names, one per line. Invalid characters will be replaced with underscores.",
		
		-- Button labels
		["$$$/CollectionMechanic/DryRunButton"] = "Dry Run",
		["$$$/CollectionMechanic/ExecuteButton"] = "Execute",
		["$$$/CollectionMechanic/CloseButton"] = "Close",
		
		-- Dialogs and messages
		["$$$/CollectionMechanic/NoCollectionSets/Title"] = "No Collection Sets Found",
		["$$$/CollectionMechanic/NoCollectionSets/Message"] = "Please create at least one collection set before using Collection Mechanic.",
		
		["$$$/CollectionMechanic/NoSelection/Title"] = "Collection Set Required",
		["$$$/CollectionMechanic/NoSelection/Message"] = "Please select a collection set before proceeding.",
		
		["$$$/CollectionMechanic/NoNames/Title"] = "No Collection Names",
		["$$$/CollectionMechanic/NoNames/Message"] = "Please enter at least one collection name.",
		
		["$$$/CollectionMechanic/InvalidNames/Title"] = "Invalid Names",
		["$$$/CollectionMechanic/InvalidNames/Message"] = "All collection names resulted in invalid entries. Please review and try again.",
		
		["$$$/CollectionMechanic/SetDeleted/Title"] = "Collection Set Deleted",
		["$$$/CollectionMechanic/SetDeleted/Message"] = "The selected collection set no longer exists. Please select a different one.",
		
		["$$$/CollectionMechanic/DryRunTitle"] = "Dry Run Preview",
		["$$$/CollectionMechanic/DryRunSummary"] = "Dry Run Results",
		
		["$$$/CollectionMechanic/ExecutionTitle"] = "Execution Results",
		["$$$/CollectionMechanic/ExecutionSummary"] = "Execution Complete",
		
		-- Result statuses
		["$$$/CollectionMechanic/Status/OK"] = "OK",
		["$$$/CollectionMechanic/Status/MODIFIED"] = "MODIFIED",
		["$$$/CollectionMechanic/Status/ERROR"] = "ERROR",
		["$$$/CollectionMechanic/Status/CREATED"] = "CREATED",
		["$$$/CollectionMechanic/Status/FAILED"] = "FAILED",
		
		-- Log messages
		["$$$/CollectionMechanic/Log/StartingDryRun"] = "Starting dry run...",
		["$$$/CollectionMechanic/Log/DryRunCompleted"] = "Dry run completed.",
		["$$$/CollectionMechanic/Log/StartingExecution"] = "Starting execution...",
		["$$$/CollectionMechanic/Log/ExecutionCompleted"] = "Execution completed.",
		["$$$/CollectionMechanic/Log/CreatingCollections"] = "Creating collections...",
	}
}
