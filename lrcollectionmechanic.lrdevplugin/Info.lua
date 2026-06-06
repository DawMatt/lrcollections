--[[
	Collection Mechanic - Adobe Lightroom Classic Plugin
	Version 1.0
	
	A plugin for batch creating collections under a specified collection set.
	Live sanitization preview shows proposed names as you type. Click Create
	Collections to batch-create them, or Cancel to exit without changes.
--]]

-- Static details about the plugin, shared across modules
Info = {}
Info.PLUGINNAME = "TPG-Collection-Mechanic"
Info.LOGGERTARGET = "logfile" -- Options: "print" or "logfile"

local menuItems = {
		{
			title = LOC "$$$/CollectionMechanic/MenuTitle=Create Collections in Batch",
			file = "CollectionMechanic.lua",
		},
	}

return {
	
	LrSdkVersion = 3.0,
	LrSdkMinimumVersion = 3.0,

	LrToolkitIdentifier = 'com.thephotogeek.lrcollectionmechanic',

	LrPluginName = LOC "$$$/CollectionMechanic/PluginName=1 TPG Collection Mechanic",
	
	-- Add the command to the Library menu and File > Plug-in Extras menu
	LrLibraryMenuItems = menuItems,

	LrInitPlugin = 'PluginInit.lua',

	LrExportMenuItems = menuItems,

	VERSION = {
		major = 1, 
		minor = 0, 
		revision = 0, 
		build = "202605301000",
	},

}
