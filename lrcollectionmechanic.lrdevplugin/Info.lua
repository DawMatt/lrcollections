--[[
	Collection Mechanic - Adobe Lightroom Classic Plugin
	Version 1.0
	
	A plugin for batch creating collections under a specified collection set.
	Includes dry-run mode for previewing name transformations and execution mode
	for creating collections in the catalog.
--]]

return {
	
	LrSdkVersion = 3.0,
	LrSdkMinimumVersion = 3.0,

	LrToolkitIdentifier = 'com.thephotogeek.lrcollectionmechanic',

	LrPluginName = LOC "$$$/CollectionMechanic/PluginName=1 TPG Collection Mechanic",
	
	-- Add the command to the Library menu and File > Plug-in Extras menu
	LrLibraryMenuItems = {
		{
			title = LOC "$$$/CollectionMechanic/MenuTitle=Create Collections in Batch",
			file = "CollectionMechanic.lua",
		},
	},

	LrExportMenuItems = {
		{
			title = LOC "$$$/CollectionMechanic/MenuTitle=Create Collections in Batch",
			file = "CollectionMechanic.lua",
		},
	},

	VERSION = { 
		major = 1, 
		minor = 0, 
		revision = 0, 
		build = "202605301000",
	},

}
