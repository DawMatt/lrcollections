require "Info"

local LrLogger = import 'LrLogger'
local logger = LrLogger(Info.PLUGINNAME)

logger:enable(Info.LOGGERTARGET)
logger:info("\n========================================\nPlugin initialised: " .. Info.PLUGINNAME)
