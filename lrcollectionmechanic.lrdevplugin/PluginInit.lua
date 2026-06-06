require "Info"

local LrApplication = import 'LrApplication'
local LrLogger = import 'LrLogger'

local logger = LrLogger(Info.PLUGINNAME)

local catalog = LrApplication.activeCatalog()
local catalogPath = (catalog and catalog:getPath()) or "<unknown>"

logger:enable(Info.LOGGERTARGET)
logger:info("\n========================================\nPlugin initialised: "
	.. Info.PLUGINNAME .. "\nCatalog: " .. catalogPath)