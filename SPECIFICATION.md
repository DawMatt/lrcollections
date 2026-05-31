# Adobe Lightroom Classic Plugin Specification
## Collection Mechanic Plugin

**Version:** 1.0  
**SDK Version:** Lightroom Classic 15.3  
**Language:** Lua  
**Last Updated:** May 30, 2026

---

## 1. Overview

The Collection Mechanic is a Lightroom Classic plugin that enables users to create multiple collections under a specified collection set in bulk. The plugin provides:
- Interactive UI for selecting a root collection set
- Batch input for collection names
- Dry-run mode to preview name transformations
- Execution mode to create collections in the catalog

---

## 2. Functional Requirements

### 2.1 User Interface

#### Main Dialog
The plugin presents a modal dialog with the following components:

1. **Collection Set Selector**
   - Label: "Root Collection Set"
   - Type: Popup/dropdown menu
   - Content: List of all collection sets in the Lightroom catalog
   - Behavior: 
     - Dynamically populated at plugin launch
     - Displays collection set names in hierarchical format (e.g., "Parent » Child")
     - Requires selection before execution
     - Default: Empty (user must select)

2. **Collection Names Input**
   - Label: "Collection Names (one per line)"
   - Type: Multi-line text field
   - Placeholder: "Enter collection names, one per line"
   - Behavior:
     - Accepts free-form text input
     - Each line represents one collection to create
     - Trimmed of leading/trailing whitespace per line
     - Empty lines are ignored
     - No character validation in input (full transformation happens in dry-run)

3. **Dry Run Button**
   - Label: "Dry Run"
   - Type: Push button
   - Behavior:
     - Validates input (at least 1 collection name provided)
     - Processes each collection name to sanitize characters
     - Displays preview in a results dialog showing:
       - Original name
       - Sanitized name (character transformations applied)
       - Status (OK, WARNING, or ERROR)
     - Does NOT create collections
     - Does NOT modify the catalog

4. **Execute Button**
   - Label: "Execute"
   - Type: Push button
   - Behavior:
     - Validates input (collection set selected, at least 1 collection name provided)
     - Performs same sanitization as dry run
     - Creates collections in the selected collection set
     - Displays progress/completion dialog with:
       - Number of collections created
       - Any collections that failed to create (with reasons)
       - Success/warning/error summary

5. **Close Button**
   - Label: "Close" or "Cancel"
   - Type: Push button
   - Behavior: Closes the dialog without changes

#### Dry Run Results Dialog
- Modal presentation of results table
- Columns: Original Name | Sanitized Name | Status
- Scrollable if many results
- Close button to dismiss

#### Execution Results Dialog
- Modal presentation of results
- Summary line: "Successfully created X collection(s)"
- Details table if needed (failures, warnings)
- Close button to dismiss
- Shows errors if any collections failed to create

---

### 2.2 Character Sanitization Rules

**Rule:** Replace unacceptable characters with underscores (`_`)

**Unacceptable Characters:**
All characters are acceptable EXCEPT those reserved by the file system or Lightroom's internal naming:
- Quotation marks: `"` 
- Asterisks: `*`
- Forward slashes: `/`
- Backslashes: `\`
- Colons: `:` (especially on macOS - reserved for file system)
- Pipe: `|`
- Question marks: `?`
- Less than/Greater than: `<`, `>`
- Leading/trailing spaces: trimmed (not replaced)
- Multiple consecutive underscores: collapsed to single underscore (post-sanitization optimization)

**Algorithm:**
```
1. Trim leading and trailing whitespace from collection name
2. Replace each unacceptable character with a single underscore
3. Collapse consecutive underscores to a single underscore
4. If resulting name is empty, return error status
5. Return sanitized name
```

**Examples:**
- `"My Collection"` → `_My_Collection_`
- `Photo/Shoot 2024` → `Photo_Shoot_2024`
- `Wedding: June 15th` → `Wedding__June_15th`
- `Best<Photo>` → `Best_Photo_`
- `Collection  Name` → `Collection__Name` (then collapsed to `Collection_Name`)

---

### 2.3 Dry Run Behavior

**Input Validation:**
- At least one collection name line must be non-empty after stripping whitespace
- Error dialog if no valid names provided

**Processing:**
- Parse input by splitting on newline characters
- For each line:
  - Strip leading/trailing whitespace
  - Skip if empty
  - Apply sanitization rules
  - Determine status:
    - `OK`: Name is valid and ready for creation (no characters replaced)
    - `MODIFIED`: Name had characters replaced but is valid
    - `ERROR`: Name resulted in empty string or other issue

**Display:**
- Tabular results showing: Original Name | Sanitized Name | Status
- Color coding (optional):
  - OK: Green or neutral
  - MODIFIED: Yellow or orange
  - ERROR: Red
- Confirmation: "These names are ready to be created"

---

### 2.4 Execution Behavior

**Preconditions:**
1. Collection set must be selected
2. At least one valid collection name must be provided
3. Lightroom catalog must be accessible (no other operations in progress)

**Processing:**
1. Sanitize all collection names (same as dry run)
2. Within Lightroom's write access context (`LrCatalog.withWriteAccessDo`):
   - Iterate through sanitized collection names
   - Call `LrCatalog.createCollection(sanitizedName, selectedCollectionSet)`
   - Track creation status (success or failure reason)
3. If a collection with the same name already exists:
   - Use `canReturnPrior=true` parameter to avoid duplicate error
   - Treat as success (collection already exists)

**Result Handling:**
- Count successful creations
- Log any failures with reasons
- Display results dialog:
  - Success summary: "X collection(s) created successfully"
  - If failures, list them with error reasons

---

## 3. Technical Architecture

### 3.1 Plugin Structure

```
lrcollectionmechanic.lrdevplugin/
├── Info.lua                              # Plugin metadata
├── CollectionMechanic.lua            # Main plugin logic
├── UI_MainDialog.lua                    # Dialog UI definition
├── Util_StringUtils.lua                 # String sanitization
└── Util_CatalogUtils.lua                # Collection operations
```

### 3.2 File Responsibilities

#### Info.lua
- Plugin metadata (name, version, SDK version)
- Menu item registration (add to Library menu)
- Entry point file

#### CollectionMechanic.lua
- Main orchestrator
- Dialog initialization and management
- Dry run and execute workflows
- Event handling

#### UI_MainDialog.lua
- LrView layout definitions
- LrBinding property bindings
- Button callbacks
- Result dialog presentations

#### Util_StringUtils.lua
- `sanitizeCollectionName(name)` - Apply sanitization rules
- `isValidCollectionName(name)` - Validate final name
- Character replacement logic

#### Util_CatalogUtils.lua
- `getCollectionSets()` - Retrieve all collection sets
- `createCollections(collectionSet, names)` - Batch create collections
- Catalog access control handling

### 3.3 Key Lightroom SDK Dependencies

**Namespaces Used:**
- `LrFunctionContext` - Context for function execution
- `LrBinding` - Data binding between UI and properties
- `LrView` - UI view factory
- `LrDialogs` - Dialog presentation
- `LrCatalog` - Catalog access and write operations
- `LrCollectionSet` - Collection set operations
- `LrCollection` - Collection operations
- `LrLogger` - Debug logging (optional but recommended)

**API Methods Used:**

| Method | Purpose |
|--------|---------|
| `LrCatalog.getChildCollectionSets()` | List all top-level collection sets |
| `LrCollectionSet.getChildCollectionSets()` | List nested collection sets |
| `LrCatalog.withWriteAccessDo(actionName, func)` | Acquire write access for catalog modifications |
| `LrCatalog.createCollection(name, parent, canReturnPrior)` | Create a collection |
| `LrDialogs.presentModalDialog(options)` | Display modal dialogs |
| `LrLogger.info(msg)` | Log debug information |

---

## 4. Data Structures

### 4.1 Property Table (LrBinding Observable)

```lua
props = {
    selectedCollectionSet = nil,      -- LrCollectionSet object
    collectionNamesInput = "",         -- Multi-line string
    dryRunResults = {},                -- Array of result objects
    executionResults = {}              -- Array of result objects
}
```

### 4.2 Result Object

```lua
result = {
    originalName = "...",              -- Input name as provided
    sanitizedName = "...",             -- Name after sanitization
    status = "OK|MODIFIED|ERROR",      -- Result status
    errorMessage = nil,                -- Error details if status is ERROR
    created = false                    -- Only for execution results
}
```

### 4.3 Collection Set Representation

```lua
collectionSetOption = {
    displayName = "Parent » Child",    -- Hierarchical display
    collectionSet = <LrCollectionSet>  -- Actual object reference
}
```

---

## 5. Error Handling

### 5.1 Input Validation Errors

| Error | User Message |
|-------|--------------|
| No collection set selected | "Please select a collection set before proceeding." |
| No collection names provided | "Please enter at least one collection name." |
| All names are invalid | "All collection names resulted in invalid entries. Please review and try again." |

### 5.2 Creation Errors

| Error | User Message | Handling |
|-------|--------------|----------|
| Duplicate collection exists | "Collection '[name]' already exists in this set." | Treat as success if `canReturnPrior=true` |
| Write access denied | "Unable to write to catalog. Please try again." | Display error; suggest closing dialogs |
| Collection set deleted | "The selected collection set no longer exists." | Reset selection; ask user to reselect |
| Catalog locked | "Catalog is currently in use. Please try again later." | Queue operation or defer to user retry |

### 5.3 Logging

- Log all operations to Lightroom's plugin console
- Include: operation type, collection set name, input names, results
- Use `LrLogger.info()` for informational messages
- Use `LrLogger.warn()` for warnings
- Maintain log level controlled by plugin preferences

---

## 6. User Workflows

### 6.1 Happy Path: Create Collections

1. User opens plugin from Library menu
2. Dialog appears with collection set dropdown (empty)
3. User selects collection set from dropdown
4. User enters collection names in multi-line text field:
   ```
   Event Photos
   Product Shots
   Portraits 2024
   ```
5. User clicks "Dry Run" button
6. Plugin shows preview:
   ```
   Event Photos         │ Event_Photos         │ OK
   Product Shots        │ Product_Shots        │ OK
   Portraits 2024       │ Portraits_2024       │ OK
   ```
7. User clicks "Execute" button
8. Plugin displays: "Successfully created 3 collection(s)"
9. User clicks "Close" button
10. Plugin closes; collections appear in Lightroom catalog under selected set

### 6.2 Character Sanitization Workflow

1. User enters collection names with special characters:
   ```
   "Product & Promo"
   Winter/Spring 2024
   Best: Photos | Edited
   ```
2. User clicks "Dry Run"
3. Plugin shows preview:
   ```
   "Product & Promo"      │ _Product___Promo_  │ MODIFIED
   Winter/Spring 2024     │ Winter_Spring_2024 │ MODIFIED
   Best: Photos | Edited  │ Best__Photos__Edit │ MODIFIED
   ```
4. User reviews sanitized names
5. User can:
   - Click "Execute" to proceed with sanitized names, OR
   - Close dialog and edit collection names in input field to use different names
   - Re-run "Dry Run" to preview changes

### 6.3 Error Workflow

1. User tries to execute without selecting a collection set
2. Plugin displays error: "Please select a collection set before proceeding."
3. Dialog remains open
4. User selects collection set and retries

---

## 7. Implementation Notes

### 7.1 Design Patterns

- **MVC Pattern**: Separate UI (UI_MainDialog.lua), business logic (CatalogUtils.lua), and data (props)
- **Observer Pattern**: Use LrBinding for reactive UI updates
- **Adapter Pattern**: Wrap LrCatalog operations for easy testing

### 7.4 Common Error Handling

**Error: "Could not find namespace: LrCatalog"**
- **Cause**: LrCatalog imported at module level before context established
- **Solution**: Move `import 'LrCatalog'` inside the function that uses it
- **Prevention**: Follow import best practices in section 7.2

**Error: "Unknown error during collection creation"**
- **Cause**: Catalog locked, no write access, or collection set deleted
- **Solution**: Use proper error handling with pcall(), check if collection set exists
- **Prevention**: Validate all inputs before attempting operations

**Error: "Catalog file access not available"**
- **Cause**: Lightroom is busy with another operation
- **Solution**: Retry operation, inform user to wait
- **Prevention**: Check `LrCatalog.canFileAccess()` before operations

### 7.5 Performance ConsiderationsPractices

**Critical**: Lightroom SDK namespaces must be imported in the correct context:

1. **Module-Level Imports (Safe)**:
   - `LrView` and `LrBinding` can be imported at module level
   - Used for UI construction which happens within proper context
   - Example: `local LrView = import 'LrView'`

2. **Function-Level Imports (Required for Catalog Access)**:
   - `LrCatalog`, `LrLogger`, `LrDialogs` should be imported inside functions
   - Especially critical inside `LrFunctionContext.callWithContext()` blocks
   - Example:
     ```lua
     local function doSomething()
         local LrCatalog = import 'LrCatalog'
         -- Use LrCatalog here
     end
     ```

3. **Why This Matters**:
   - Some SDK namespaces require an active function context
   - Importing at module level can cause "Could not find namespace" errors
   - Moving imports inside functions ensures proper context setup

**Recommended Pattern**:
```lua
-- At module level (OK for UI factories):
local LrView = import 'LrView'
local LrBinding = import 'LrBinding'

-- Ins6 Compatibility

- SDK Version: 3.0+ (for `createCollection` support)
- Lightroom Classic: Version 15.3+ (tested SDK version)
- Platforms: Windows and macOS

### 7.7 Security & Best Practices

- No file system access required
- No external network calls
- All operations within Lightroom's sandbox
- Use Lightroom's undo system (automatic via `withWriteAccessDo`)
- Validate all user input before processing
- Log operations for debugging
- Always use proper context for catalog operations
- Import SDK namespaces at correct scope level

### 7.8 Error Recovery Patterns

**Safe Catalog Operations**:
```lua
-- Inside function context:
local function safeCreateCollection(name, parent)
    local LrCatalog = import 'LrCatalog'
    local ok, result = pcall(function()
        return LrCatalog.createCollection(name, parent, true)
    end)
    return ok, result
end
```

**Checking Resource Availability**:
```lua
-- Before catalog operations:
if not LrCatalog.canFileAccess() then
    -- Catalog is busy
    return false
end
```

**Verifying Objects Still Exist**:
```lua
-- Collection sets can be deleted, verify before use:
if not collectionSet:getName() then
    -- Collection set was deleted
    return false
end
```g operations
- Lazy-load collection sets on first access
- Cache collection set list until dialog closes

### 7.3 Compatibility

- SDK Version: 3.0+ (for `createCollection` support)
- Lightroom Classic: Version 15.3+ (tested SDK version)
- Platforms: Windows and macOS

### 7.4 Security & Best Practices

- No file system access required
- No external network calls
- All operations within Lightroom's sandbox
- Use Lightroom's undo system (automatic via `withWriteAccessDo`)
- Validate all user input before processing
- Log operations for debugging

---

## 8. Testing Checklist

### Functional Tests
- [ ] Collection set dropdown populates correctly
- [ ] Dry run shows accurate character transformations
- [ ] Dry run does NOT create collections
- [ ] Execute creates collections with sanitized names
- [ ] Collections appear in correct collection set
- [ ] Duplicate names are handled (if set to `canReturnPrior=true`)
- [ ] Empty input lines are ignored
- [ ] Multiple executions create all requested collections

### Edge Cases
- [ ] Collection set with nested hierarchy displays correctly
- [ ] Very long collection names (>255 chars) are handled
- [ ] Unicode characters in input are sanitized appropriately
- [ ] Empty collection name input shows error
- [ ] Only whitespace collection name is treated as empty
- [ ] Rapid button clicks don't cause race conditions
- [ ] Dialog remains responsive during operations

### UI/UX Tests
- [ ] Dialog layout is clean and centered
- [ ] Buttons are properly sized and labeled
- [ ] Placeholder text is helpful
- [ ] Results dialogs are scrollable for long lists
- [ ] Error messages are clear and actionable
- [ ] No UI elements are cut off on smaller screens

---

## 9. Future Enhancements

Potential features for v2.0:
- Rename existing collections with same sanitization rules
- Hierarchical collection set creation (nested structure)
- Template-based naming (e.g., "Collection {number}" → Collection 1, Collection 2, ...)
- Import collection list from file
- Undo/redo UI for last operation
- Preferences panel (character replacement options)
- Bulk move photos to new collections
- Export collection structure to file

---

## 10. Appendix: Character Reference

### Reserved Characters by Platform

**macOS:**
- Colon (`:`) - reserved for file system paths

**Windows:**
- `< > : " / \ | ? *` - reserved characters

**Lightroom:**
- No published restrictions, but best practice is to avoid:
  - Quotes (`"`, `'`)
  - Slashes (`/`, `\`)
  - Pipes (`|`)
  - Special shell characters

**Sanitization Applied:**
- All reserved characters above replaced with `_`
- Multiple consecutive underscores collapsed to single `_`
- Trimmed leading/trailing whitespace

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | May 30, 2026 | Initial specification |

