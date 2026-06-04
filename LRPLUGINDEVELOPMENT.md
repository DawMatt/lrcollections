# Lightroom Classic Plugin Development Standards and Conventions

Defines the standards and conventions we apply when developing Lightroom (LR) Classic Plugins.

## Lightroom Classic's Lua Features

### Imports

#### Namespaces vs Classes

The Lightroom Classic SDK API Reference includes for both namespaces and classes. Only items that are namespaces, or both namespaces and classes, can be imported.

**Valid example:**
```lua
local LrApplication = import 'LrApplication' -- Correct: LrApplication is a namespace
```

**Invalid Example:**
```lua
local LrCatalog = import 'LrCatalog' -- Incorrect: LrCatalog is a class only
```

Classes require an object to be retrieved before they can be used.

| Class | Object Retrieved By |
| --- | --- | 
| LrCatalog | LrApplication.activeCatalog(), or from the catalog property of many of the contained objects |
| LrCollection | Retrieve the objects for all the collections by calling catalog:getChildCollections(). To retrieve collections contained in collection sets, use collectionSet:getChildCollections() |
| LrCollectionSet | Retrieve the objects for the top-level collection sets by calling catalog:getChildCollectionSets(). To get immediate child sets, use this object's getChildCollectionsSets() method. |
| LrPlugin | Variable _PLUGIN |

### Require

Require works mostly the same as Lua except it does not allow scripts to be stored in a sub-directory. 

By convention we use a prefix (e.g. Util__) as a workaround for the inability to use a sub-directory, to visually group scripts by name. When naming the namespace within the script we ignore this prefix.

**Incorrect:**
```lua
require 'Util.SomeUtil'  -- ❌ Actual script name: Util/SomeUtil.lua . Invalid as sub-directories are not supported
SomeUtil.method() -- Calling a method defined within the script
```

**Correct:**
```lua
require 'Util__SomeUtil'  -- Actual script name: Util__SomeUtil.lua
SomeUtil.method() -- Calling a method defined within the script
```

#### Error: "Could not load toolkit script"

Plugin script files can fail to load for a number of reasons.

1. **The require statement and script name do not match.**

**Before (Wrong):**
```lua
require 'wrongfilename'  -- ❌ Actual script name: rightfilename.lua
```

**After (Correct):**
```lua
require 'rightfilename'  -- Actual script name: rightfilename.lua
```

2. **The script has been created since Lightroom was last restarted.**

Reloading a plugin does not detect new or renamed scripts. Restart Lightroom to detect these changes.

## Lightroom Classic Plugin Layout

### Info.lua

By convention we include static information to be shared throughout the plugin in the Info.lua file.

e.g.
```lua
Info = {}

Info.PLUGINNAME = "<Plugin-Name>"
Info.LOGGERTARGET = "logfile" -- Options: "print" or "logfile"
```

Other modules and scripts can then load this file and access the values without hardcoding them in multiple locations. e.g.

```lua
require "Info"

local logger = import 'LrLogger'( Info.PLUGINNAME or "Debug" )
```

#### Menu items

Menu items are added via the Info.lua file. 

By convention we add our non-photo level functionality (e.g. Library or application level functionality) to both of the following menu locations:

- LrLibraryMenuItems
- LrExportMenuItems

In the Info.lua file we define the menu items via a local variable. e.g.
```lua
local menuItems = {
		{
			title = LOC "$$$/CollectionMechanic/MenuTitle=Create Collections in Batch",
			file = "CollectionMechanic.lua",
		},
	}
```

We then reference this within the Info.lua returned table. e.g.

```lua
return {
    -- Other entries above here
	LrLibraryMenuItems = menuItems,
	LrExportMenuItems = menuItems,
    -- Other entries below here
}
```

#### Menu item modules

Menu item module code should be kept very brief. They should only create the appropriate environment and context to invoke the function.

```lua
require "CollectionMechanic"

local LrFunctionContext = import 'LrFunctionContext'

LrFunctionContext.postAsyncTaskWithContext("<Menu Item Name>", function(context)
		CollectionMechanic.showCollectionMechanicDialog(context)
	end)
```

### PluginInit.lua

PluginInit is used to perform preparation tasks that should only be executed once per plugin execution.

At a minimum, we use this to enable logging. e.g.

```lua
require "Info"

local LrLogger = import 'LrLogger'
local logger = LrLogger(Info.PLUGINNAME)

logger:enable(Info.LOGGERTARGET)
logger:info("Plugin initialised: " .. Info.PLUGINNAME)
```

We then reference this within the Info.lua returned table. e.g.

```lua
return {
    -- Other entries above here
		LrInitPlugin = 'PluginInit.lua',
    -- Other entries below here
}
```

## Lightroom Classic Plugin Conventions

### General

#### Imports

- Lightroom SDK namespaces should be imported at the module level, toward the top of the file, unless they are context sensitive and should be imported within the function or function context using the import.

#### Logging

- Lightroom logging should be enabled in PluginInit or at the module level. e.g.

```lua
local logger = import 'LrLogger'( Info.PLUGINNAME or "Debug" )
logger:enable( Info.LOGGERTARGET or "logfile" ) -- Enable logging to console
```

- If Lightroom logging was enabled in PluginInit it should then be accessed at the module level by importing with the same name. Repeating the `logger:enable` is not necessary. e.g.

```lua
local logger = import 'LrLogger'( Info.PLUGINNAME or "Debug" )
```

- Logging is via an object method e.g. `logger:info`. Available logging methods: fatal, error, warn, info, debug, or trace.

```lua
logger:info("<message text goes here>")
```
