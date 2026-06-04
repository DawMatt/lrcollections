require "Info"

local LrLogger = import 'LrLogger'
local logger = LrLogger(Info.PLUGINNAME)

logger:enable(Info.LOGGERTARGET)
logger:info("Plugin initialised: " .. Info.PLUGINNAME)
