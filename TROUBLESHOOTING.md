# Collection Mechanic - Troubleshooting Guide

## Common Errors and Solutions

### Error: "Could not find namespace: LrCatalog"

**Symptoms:**
- Plugin menu item clicked
- Error appears: "The plug-in encountered an error when performing the menu item..."
- Message includes: "Could not find namespace: LrCatalog" (or LrLogger, LrDialogs)

**Root Cause:**
Lightroom SDK namespaces imported at module level instead of inside function context.

**Quick Fix:**
In the affected module, move all `import` statements for `LrCatalog`, `LrLogger`, and `LrDialogs` from the top of the file into the functions that use them.

**Before (Wrong):**
```lua
--[[CatalogUtils.lua]]
local LrCatalog = import 'LrCatalog'  -- ❌ At module level
local LrLogger = import 'LrLogger'

function CatalogUtils.createCollections(set, names)
    -- Uses LrCatalog and LrLogger
end
```

**After (Correct):**
```lua
--[[CatalogUtils.lua]]
function CatalogUtils.createCollections(set, names)
    local LrCatalog = import 'LrCatalog'  -- ✅ Inside function
    local LrLogger = import 'LrLogger'
    
    -- Uses LrCatalog and LrLogger
end
```

**Detailed Solution:**

1. **Identify the problem file**
   - Look at Lightroom's debug log for the exact file name
   - Debug log locations:
     - macOS: `~/Library/Logs/Adobe/Lightroom/Lightroom Debug.log`
     - Windows: `%APPDATA%\Adobe\Lightroom\Logs\Lightroom Debug.log`

2. **Move the imports**
   - Find lines like: `local LrCatalog = import 'LrCatalog'` at the top
   - Cut these lines
   - Paste them inside each function that uses them

3. **Test the fix**
   - Restart Lightroom
   - Try the menu item again

4. **Verification**
   - Safe namespaces at module level: `LrView`, `LrBinding`, `LrFunctionContext`
   - Must be inside functions: `LrCatalog`, `LrLogger`, `LrDialogs`, `LrPrefs`

---

### Error: "Could not find namespace: LrView"

**Symptoms:**
- Similar to LrCatalog error but with LrView

**Root Cause:**
Less common - usually occurs when LrView is imported inside a function that doesn't have the UI context.

**Solution:**
`LrView` should be imported at module level, not inside functions. Check if it's incorrectly placed inside a function.

---

### Error: "Attempt to call a nil value"

**Symptoms:**
- Error after collections are created
- Message mentions a line number in CollectionMechanic.lua or MainDialog.lua

**Root Cause:**
Usually means a callback function returned nil or an object doesn't exist.

**Common Causes:**
1. Collection set was deleted before Execute
2. User cancelled operation
3. A function returned nothing but code tried to use the result

**Solution:**
1. Add defensive checks for nil values:
   ```lua
   if not collectionSet or not collectionSet:getName() then
       -- Collection set doesn't exist
       return error("Collection set is invalid")
   end
   ```

2. Always check return values:
   ```lua
   local result = LrCatalog.createCollection(...)
   if not result then
       -- Handle failure
   end
   ```

---

### Error: "Catalog is currently in use"

**Symptoms:**
- Execute button is clicked
- Operation fails with "Catalog is currently in use" message

**Root Cause:**
Lightroom is busy with another operation (import, export, sync, etc.)

**Solution:**
1. Wait a moment and try again
2. Verify no other operations are in progress
3. Check if other plugins are running
4. Restart Lightroom if issue persists

**Code-Level Solution:**
Check catalog availability before operation:
```lua
if not LrCatalog.canFileAccess() then
    -- Catalog is busy
    showErrorDialog("Please wait", 
        "Lightroom is busy with another operation. Please try again in a moment.")
    return
end
```

---

### Error: "Collection Set Deleted"

**Symptoms:**
- Execute works but shows error for parent collection set
- Message: "The selected collection set no longer exists"

**Root Cause:**
User deleted the collection set while dialog was open, or it was deleted by another instance of Lightroom.

**Solution:**
1. Create a new collection set
2. Reopen the plugin
3. Select the new collection set
4. Try again

---

### Error: "Invalid collection name"

**Symptoms:**
- All collection names show "ERROR" status in dry run
- No collections created

**Root Cause:**
All collection names consist only of reserved characters (like `:::` or `***`)

**Solution:**
Use valid characters in collection names. Valid characters are any except:
- `" * / \ : | ? < >`

**Example fixes:**
- `:::` → `_` → Still might fail (becomes empty)
- `:::`  → `Collection_3` → Valid
- `***` → `My_Shoot` → Valid

---

### Plugin Menu Item Doesn't Appear

**Symptoms:**
- Plugin folder installed
- Lightroom restarted
- Menu item not in Library menu

**Root Cause:**
Usually a syntax error in Info.lua

**Solution:**
1. Check Info.lua for syntax errors
2. Verify the return statement is correct
3. Check file names are exact case-match:
   - `LrToolkitIdentifier` (exact case!)
   - `LrPluginName`
   - `LrLibraryMenuItems`

4. Verify file reference matches:
   ```lua
   file = "CollectionMechanic.lua"  -- Must match actual filename
   ```

5. Restart Lightroom completely (force quit if needed)

---

### Collections Created but Don't Appear in Catalog

**Symptoms:**
- Execute button shows "Successfully created X collection(s)"
- But collections don't show in Collections panel

**Root Cause:**
Usually means:
1. Collections were created under a different parent than expected
2. Collections panel needs refresh
3. Collections created but panel is scrolled out of view

**Solution:**
1. Check correct collection set is selected in dialog
2. Expand collection set in Collections panel
3. Scroll within Collection panel to find new collections
4. Verify in Lightroom's Collections panel sidebar

---

### Localization Strings Not Working

**Symptoms:**
- UI shows `$$$/CollectionMechanic/MenuTitle=...` instead of actual menu text
- Menu item display name is wrong

**Root Cause:**
Localization strings file not found or incorrect path

**Solution:**
Verify file structure:
```
com.thephotogeek.lrcollectionmechanic.lrdevplugin/
└── Localization/
    └── en.lproj/
        └── Strings.lua
```

Check strings file contains proper keys:
```lua
return {
    en = {
        ["$$$/CollectionMechanic/PluginName"] = "Collection Mechanic",
        ["$$$/CollectionMechanic/MenuTitle"] = "Create Collections in Batch",
        ...
    }
}
```

---

## Debugging Techniques

### Enable Logging

Add logging to any function to debug:

```lua
local LrLogger = import 'LrLogger'
LrLogger.info("Variable value: " .. tostring(value))
LrLogger.warn("Potential issue: " .. issue)
```

Check logs at:
- macOS: `~/Library/Logs/Adobe/Lightroom/Lightroom Debug.log`
- Windows: `%APPDATA%\Adobe\Lightroom\Logs\Lightroom Debug.log`

### Use Lightroom's Console

Some Lightroom versions have a built-in console:
1. Restart Lightroom with console: (varies by version)
2. Messages appear as operations happen

### Test with Dry Run First

Always click "Dry Run" before "Execute" to:
1. See what collection names will look like
2. Verify sanitization is correct
3. Catch issues without modifying catalog

---

## Getting Help

### Before Reporting an Issue

1. ✅ Check this Troubleshooting Guide
2. ✅ Review EXAMPLES.md for similar scenarios
3. ✅ Check README.md usage instructions
4. ✅ Review Lightroom Debug.log for details

### Information to Provide

When reporting an issue, include:
1. **Lightroom version** (Help → About Lightroom Classic)
2. **Plugin version** (in Info.lua: VERSION field)
3. **Steps to reproduce** (exactly what you did)
4. **Error message** (copy/paste exact text)
5. **Debug.log excerpt** (relevant lines from log file)
6. **Collection names used** (what you typed in dialog)
7. **OS/Platform** (macOS or Windows)

### Review Files for Common Issues

Check these files first:
1. **README.md** - User documentation and features
2. **EXAMPLES.md** - Real-world scenarios and solutions
3. **DEVELOPMENT.md** - Technical implementation details
4. **SPECIFICATION.md** - Requirements and design

---

## Performance Issues

### Plugin Runs Slowly

**For 100+ collections:**
1. Split into multiple runs
2. Use "Dry Run" first to verify
3. Verify Lightroom isn't busy with other operations
4. Check system resources (disk space, RAM)

**Future optimization:** Async processing with progress indication

### Dialog Hangs During Execute

**Symptoms:**
- Dialog freezes during collection creation
- No progress indication
- Have to force-quit Lightroom

**Current Behavior:**
Large batches (100+) are created synchronously within one `withWriteAccessDo` call, which blocks UI.

**Workaround:**
Create smaller batches (20-50 collections) and run multiple times.

**Future Fix:**
Implement async processing with yield points for responsiveness.

---

## Version-Specific Issues

### Lightroom Classic 15.2 and Earlier

**Issue:** Plugin may not work
**Solution:** Update to Lightroom Classic 15.3+
**Reason:** SDK 3.0 features required

### Lightroom CC (Cloud)

**Issue:** Plugin not available
**Solution:** Use Lightroom Classic instead
**Reason:** Plugin is for Classic only, not cloud version

---

## Platform-Specific Issues

### macOS Issues

**File path issues:**
- Use `~/` for home directory, not absolute paths
- Case-sensitive file system
- Check permissions on ~/Library/Application Support/Adobe/

### Windows Issues

**Path issues:**
- Use backslashes `\` in paths (handled by Lightroom)
- Check Admin privileges for plugin folder
- AppData folder might be hidden - enable hidden files view

---

## Contact & Support

For additional help:
1. Consult documentation files in plugin folder
2. Review DEVELOPMENT.md for implementation details
3. Check Lightroom's debug.log for specific error details
4. Verify plugin file structure is correct

---

## Quick Reference

| Problem | File | Section | Solution |
|---------|------|---------|----------|
| Plugin won't open | Info.lua | Syntax | Check syntax, restart |
| LrCatalog not found | CatalogUtils.lua | Imports | Move imports into functions |
| Collections don't appear | MainDialog.lua | Selection | Verify parent set selected |
| Special chars fail | StringUtils.lua | Sanitization | Use valid characters |
| Catalog locked | CollectionMechanic.lua | Error handling | Retry operation |

