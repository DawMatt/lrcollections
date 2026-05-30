--[[
	StringUtils.lua
	
	Utility functions for string manipulation and collection name sanitization.
--]]

local StringUtils = {}

-- Characters that must be replaced with underscores
local RESERVED_CHARS = {
	['"'] = true,
	['*'] = true,
	['/'] = true,
	['\\'] = true,
	[':'] = true,
	['|'] = true,
	['?'] = true,
	['<'] = true,
	['>'] = true,
}

--[[
	Sanitize a collection name by replacing reserved characters with underscores.
	
	Algorithm:
	1. Trim leading and trailing whitespace
	2. Replace each reserved character with underscore
	3. Collapse consecutive underscores to single underscore
	4. Return result (may be empty if name was all reserved chars)
	
	@param name (string) The collection name to sanitize
	@return {
		sanitizedName = string,
		wasModified = boolean,
		isEmpty = boolean
	}
--]]
function StringUtils.sanitizeCollectionName(name)
	if not name or type(name) ~= "string" then
		return {
			sanitizedName = "",
			wasModified = true,
			isEmpty = true
		}
	end
	
	-- Trim leading/trailing whitespace
	local trimmed = name:match("^%s*(.-)%s*$")
	if not trimmed or trimmed == "" then
		return {
			sanitizedName = "",
			wasModified = true,
			isEmpty = true
		}
	end
	
	-- Replace reserved characters with underscores
	local replaced = ""
	local modified = false
	
	for i = 1, #trimmed do
		local char = trimmed:sub(i, i)
		if RESERVED_CHARS[char] then
			replaced = replaced .. "_"
			modified = true
		else
			replaced = replaced .. char
		end
	end
	
	-- Collapse consecutive underscores
	local collapsed = replaced:gsub("_+", "_")
	
	-- Check if collapsing changed the string (indicates consecutive underscores)
	if collapsed ~= replaced then
		modified = true
	end
	
	-- Remove leading/trailing underscores (they shouldn't be there but just in case)
	collapsed = collapsed:match("^_?(.-?)_?$")
	
	-- Check if result is empty
	local isEmpty = collapsed == "" or not collapsed
	
	return {
		sanitizedName = collapsed or "",
		wasModified = modified,
		isEmpty = isEmpty
	}
end

--[[
	Check if a name is valid for a collection.
	
	@param name (string) The collection name to validate
	@return boolean True if name is valid
--]]
function StringUtils.isValidCollectionName(name)
	if not name or type(name) ~= "string" then
		return false
	end
	
	local trimmed = name:match("^%s*(.-)%s*$")
	return trimmed and trimmed ~= ""
end

--[[
	Parse a multi-line string into individual collection names.
	
	@param inputText (string) Multi-line text with one collection name per line
	@return array of strings (non-empty lines after trimming)
--]]
function StringUtils.parseCollectionNames(inputText)
	local names = {}
	
	if not inputText or inputText == "" then
		return names
	end
	
	-- Split by newline and process each line
	for line in inputText:gmatch("[^\r\n]+") do
		local trimmed = line:match("^%s*(.-)%s*$")
		if trimmed and trimmed ~= "" then
			table.insert(names, trimmed)
		end
	end
	
	return names
end

--[[
	Get status for a sanitization result.
	
	@param sanitizedResult (table) Result from sanitizeCollectionName
	@return string One of: "OK", "MODIFIED", "ERROR"
--]]
function StringUtils.getStatusFromResult(sanitizedResult)
	if sanitizedResult.isEmpty then
		return "ERROR"
	elseif sanitizedResult.wasModified then
		return "MODIFIED"
	else
		return "OK"
	end
end

return StringUtils
