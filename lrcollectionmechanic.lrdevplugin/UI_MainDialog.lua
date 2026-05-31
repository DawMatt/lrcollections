--[[
	UI_MainDialog.lua
	
	UI layout and binding definitions for the main Collection Mechanic dialog.
--]]

local LrView = import 'LrView'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'

UIManager = {}

--[[
	Create the main dialog contents.
	
	@param props (LrBinding observable table) The property table
	@param collectionSetOptions (array) List of collection set options
	@param callbacks (table) Callback functions {onDryRun, onExecute, onClose}
	@return LrView widget tree
--]]
function UIManager.createMainDialog(props, collectionSetOptions, callbacks)
	local f = LrView.osFactory()
	
	-- Convert collection set options to menu items for the popup
	local menuItems = {}
	for _, option in ipairs(collectionSetOptions) do
		table.insert(menuItems, {
			title = option.displayName,
			value = option.collectionSet
		})
	end
	
	local dialog = f:column {
		bind_to_object = props,
		spacing = f:control_spacing(),
		
		-- Title/Header
		f:heading {
			title = "Collection Mechanic"
		},
		
		-- Collection Set Selection Section
		f:group_box {
			title = "Collection Set",
			f:column {
				spacing = f:control_spacing(),
				
				f:row {
					f:static_text {
						title = "Root Collection Set:",
						width = LrView.share("label_width")
					},
					f:popup_menu {
						bind_to_object = props,
						value = LrView.bind("selectedCollectionSet"),
						items = menuItems,
						width_in_chars = 30
					}
				}
			}
		},
		
		-- Collection Names Input Section
		f:group_box {
			title = "Collection Names",
			f:column {
				spacing = f:control_spacing(),
				
				f:static_text {
					title = "Enter collection names, one per line:",
					wrap = true
				},
				
				f:edit_field {
					bind_to_object = props,
					value = LrView.bind("collectionNamesInput"),
					height_in_lines = 8,
					width_in_chars = 50,
					font = "<monospace>"
				}
			}
		},
		
		-- Buttons Section
		f:row {
			spacing = f:control_spacing(),
			
			f:push_button {
				title = "Dry Run",
				action = callbacks.onDryRun,
				width = LrView.share("button_width")
			},
			
			f:push_button {
				title = "Execute",
				action = callbacks.onExecute,
				width = LrView.share("button_width")
			},
			
			f:push_button {
				title = "Close",
				action = callbacks.onClose,
				width = LrView.share("button_width")
			}
		}
	}
	
	return dialog
end

--[[
	Display a results dialog showing dry run or execution results.
	
	@param title (string) Dialog title
	@param results (array) Array of result objects
	@param summary (string) Summary message
--]]
function UIManager.showResultsDialog(title, results, summary)
	local f = LrView.osFactory()
	
	-- Build result table rows
	local resultText = summary .. "\n\n"
	resultText = resultText .. "┌─────────────────────────────┬─────────────────────────────┬──────────┐\n"
	resultText = resultText .. "│ Original Name               │ Sanitized Name              │ Status   │\n"
	resultText = resultText .. "├─────────────────────────────┼─────────────────────────────┼──────────┤\n"
	
	for _, result in ipairs(results) do
		local origName = result.originalName or result.collectionName or ""
		local sanitizedName = result.sanitizedName or ""
		local status = result.status or ""
		
		-- Pad names to fixed width for alignment
		origName = string.format("%-27s", origName:sub(1, 27))
		sanitizedName = string.format("%-27s", sanitizedName:sub(1, 27))
		status = string.format("%-8s", status)
		
		resultText = resultText .. string.format("│ %s │ %s │ %s │\n", origName, sanitizedName, status)
	end
	
	resultText = resultText .. "└─────────────────────────────┴─────────────────────────────┴──────────┘\n"
	
	local contents = f:column {
		f:static_text {
			title = title,
			text_color = LrView.color("label")
		},
		
		f:edit_field {
			value = resultText,
			height_in_lines = 20,
			width_in_chars = 70,
			font = "<monospace>",
			enabled = false
		}
	}
	
	LrDialogs.presentModalDialog {
		title = title,
		contents = contents
	}
end

--[[
	Show an error dialog.
	
	@param title (string) Dialog title
	@param message (string) Error message
--]]
function UIManager.showErrorDialog(title, message)
	LrDialogs.showError(title, message)
end

--[[
	Show an info dialog.
	
	@param title (string) Dialog title
	@param message (string) Message text
--]]
function UIManager.showInfoDialog(title, message)
	LrDialogs.message(title, message, "info")
end

return UIManager
