require "Info"
local LrLogger = import 'LrLogger'
local logger = LrLogger(Info.PLUGINNAME)

StringUtils = {}

local RESERVED_CHARS = {
    ['"'] = true, ['*'] = true, ['/'] = true, ['\\'] = true,
    [':'] = true, ['|'] = true, ['?'] = true, ['<'] = true, ['>'] = true,
}

local MAX_NAME_LENGTH = 255

-- Returns {sanitizedName, status, errorMessage} where status is "OK", "MODIFIED", or "ERROR".
-- errorMessage is populated only when status == "ERROR".
function StringUtils.sanitizeCollectionName(name)
    if not name or type(name) ~= "string" then
        return { sanitizedName = "", status = "ERROR", errorMessage = "Invalid input" }
    end

    local trimmed = name:match("^%s*(.-)%s*$")
    if not trimmed or trimmed == "" then
        return { sanitizedName = "", status = "ERROR", errorMessage = "Name is empty" }
    end

    if #trimmed > MAX_NAME_LENGTH then
        return { sanitizedName = "", status = "ERROR",
                 errorMessage = "Name exceeds " .. MAX_NAME_LENGTH .. " characters" }
    end

    local replaced = ""
    for i = 1, #trimmed do
        local char = trimmed:sub(i, i)
        if RESERVED_CHARS[char] then
            replaced = replaced .. "_"
        else
            replaced = replaced .. char
        end
    end

    local collapsed = replaced:gsub("_+", "_")

    if collapsed == "" then
        return { sanitizedName = "", status = "ERROR",
                 errorMessage = "Name is empty after sanitization" }
    elseif collapsed == trimmed then
        return { sanitizedName = collapsed, status = "OK" }
    else
        return { sanitizedName = collapsed, status = "MODIFIED" }
    end
end

-- Returns array of CollectionNameEntry: {originalName, sanitizedName, status}
function StringUtils.parseCollectionNames(inputText)
    local entries = {}
    if not inputText or inputText == "" then return entries end

    local normalized = inputText:gsub("\r\n", "\n"):gsub("\r", "\n")
    for line in normalized:gmatch("[^\n]+") do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed and trimmed ~= "" then
            local result = StringUtils.sanitizeCollectionName(trimmed)
            table.insert(entries, {
                originalName  = trimmed,
                sanitizedName = result.sanitizedName,
                status        = result.status,
            })
        end
    end
    return entries
end

return StringUtils
