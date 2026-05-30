# Collection Mechanic - Developer Documentation

## Architecture Overview

The Collection Mechanic plugin follows a modular, layered architecture:

```
┌─────────────────────────────────────────────────────────┐
│  CollectionMechanic.lua (Orchestrator & Entry Point)   │
│  - Dialog lifecycle                                     │
│  - Dry run workflow                                     │
│  - Execution workflow                                   │
└────────────┬──────────────────────────────┬─────────────┘
             │                              │
    ┌────────▼────────┐         ┌──────────▼──────────┐
    │  UI/MainDialog  │         │  Utilities/         │
    │  - Layout       │         │  StringUtils        │
    │  - Bindings     │         │  CatalogUtils       │
    │  - Results      │         └──────────────────────┘
    └─────────────────┘
             │
    ┌────────▼────────────────────────────┐
    │  Lightroom SDK (LrView, LrBinding,  │
    │   LrCatalog, LrDialogs, etc.)       │
    └─────────────────────────────────────┘
```

## Module Descriptions

### CollectionMechanic.lua

**Responsibility**: Main orchestrator and entry point

**Key Functions**:
- `showCollectionMechanicDialog()` - Main entry point, initializes context and dialog
- `performDryRun(props, options)` - Handles dry run workflow
- `performExecution(props, options)` - Handles execution workflow

**Flow**:
1. Gets collection set options from catalog
2. Creates observable properties table
3. Builds UI with callbacks
4. Shows modal dialog
5. Handles user interactions (dry run, execute, close)

### StringUtils.lua

**Responsibility**: String sanitization and parsing

**Key Functions**:
- `sanitizeCollectionName(name)` - Core sanitization algorithm
  - Trims whitespace
  - Replaces reserved characters with underscores
  - Collapses consecutive underscores
  - Returns result object with status

- `parseCollectionNames(inputText)` - Parse multi-line input
- `isValidCollectionName(name)` - Validate a name
- `getStatusFromResult(result)` - Convert result to status string

**Reserved Characters**:
```lua
RESERVED_CHARS = {
    ['"'] = true,  -- Quotes
    ['*'] = true,  -- Asterisk
    ['/'] = true,  -- Forward slash
    ['\\'] = true, -- Backslash
    [':'] = true,  -- Colon (especially macOS)
    ['|'] = true,  -- Pipe
    ['?'] = true,  -- Question mark
    ['<'] = true,  -- Less than
    ['>'] = true,  -- Greater than
}
```

### CatalogUtils.lua

**Responsibility**: Lightroom catalog operations

**Key Functions**:
- `getAllCollectionSets()` - Recursively builds hierarchical list of all collection sets
- `_addCollectionSetOption(set, prefix, options)` - Internal recursive helper
- `createCollections(set, names)` - Batch create collections in write context
- `collectionSetExists(set)` - Verify collection set hasn't been deleted

**Key API Usage**:
- `LrCatalog.getChildCollectionSets()` - Top-level sets
- `LrCatalog.withWriteAccessDo()` - Write access context
- `LrCatalog.createCollection(name, parent, canReturnPrior)` - Create individual collection

### MainDialog.lua (UI)

**Responsibility**: Dialog UI layout and presentation

**Key Functions**:
- `createMainDialog(props, options, callbacks)` - Build main dialog
- `showResultsDialog(title, results, summary)` - Display results table
- `showErrorDialog(title, message)` - Show error
- `showInfoDialog(title, message)` - Show info

**UI Components**:
- Popup menu for collection set selection (bound to props)
- Multi-line edit field for names input (bound to props)
- Buttons: Dry Run, Execute, Close
- Results display: ASCII table format

## Data Flow

### Dry Run Flow

```
User Input
    ↓
parseCollectionNames()
    ↓
For each name:
  sanitizeCollectionName()
  getStatusFromResult()
    ↓
Build results array
    ↓
showResultsDialog()
```

### Execution Flow

```
User Input + Selected Set
    ↓
validateInput()
    ↓
parseCollectionNames()
    ↓
For each name:
  sanitizeCollectionName()
    ↓
createCollections(set, sanitizedNames)
    ↓
In withWriteAccessDo context:
  For each name:
    LrCatalog.createCollection()
    Track result
    ↓
Build results array
    ↓
showResultsDialog()
```

## Key Design Patterns

### 1. Observer Pattern (LrBinding)

Properties in `props` are automatically synchronized with UI controls:

```lua
local props = LrBinding.makePropertyTable(context)
props.selectedCollectionSet = nil

-- In UI:
f:popup_menu {
    value = LrView.bind("selectedCollectionSet")
}
-- When user selects: props.selectedCollectionSet automatically updated
```

### 2. Write Access Gate (withWriteAccessDo)

All catalog modifications happen within this context:

```lua
LrCatalog.withWriteAccessDo("Action Name", function()
    -- Modifications here are atomic and undoable
    LrCatalog.createCollection(name, parent)
end)
```

### 3. Error Handling with pcall

Catch Lua errors gracefully:

```lua
local ok, result = pcall(function()
    return LrCatalog.createCollection(name, set, true)
end)

if ok and result then
    -- Success
else
    -- Handle error
end
```

## Testing

### Import Scoping (Critical)

One of the most common errors when extending this plugin is improper namespace imports.

**❌ WRONG - Causes "Could not find namespace" error:**
```lua
-- At module level:
local LrCatalog = import 'LrCatalog'  -- TOO EARLY!

function doWork()
    -- Now LrCatalog might not be available
end
```

**✅ CORRECT - Import inside function:**
```lua
function doWork()
    local LrCatalog = import 'LrCatalog'  -- Safe here
    -- Use LrCatalog
end
```

**✅ ACCEPTABLE - For UI namespaces at module level:**
```lua
-- At module level (safe for UI):
local LrView = import 'LrView'
local LrBinding = import 'LrBinding'

function createDialog()
    local f = LrView.osFactory()  -- OK to use here
end
```

**Import Scoping Guide**:
| Namespace | Module Level | Inside Function | Inside Context | Notes |
|-----------|--------------|-----------------|----------------|-------|
| LrView | ✅ OK | ✅ OK | ✅ OK | UI factory, safe anywhere |
| LrBinding | ✅ OK | ✅ OK | ✅ OK | Data binding, safe anywhere |
| LrCatalog | ❌ RISKY | ✅ REQUIRED | ✅ REQUIRED | Needs proper context |
| LrDialogs | ❌ RISKY | ✅ REQUIRED | ✅ REQUIRED | Modal operations need context |
| LrLogger | ❌ RISKY | ✅ REQUIRED | ✅ REQUIRED | Logging needs context |
| LrFunctionContext | ✅ OK | ✅ OK | N/A | Entry point for context |

### Manual Testing Checklist

1. **Setup**
   - [ ] Create sample collection sets in Lightroom
   - [ ] Verify plugin menu item appears

2. **Basic Functionality**
   - [ ] Open plugin dialog
   - [ ] Collection sets populate correctly
   - [ ] Can select collection set
   - [ ] Can enter text in collection names field

3. **Dry Run**
   - [ ] Dry run shows correct original names
   - [ ] Sanitization works correctly:
     - [ ] Special characters replaced with `_`
     - [ ] Consecutive `_` collapsed to single `_`
     - [ ] Whitespace trimmed
   - [ ] Status correct (OK/MODIFIED/ERROR)
   - [ ] Results displayable

4. **Execution**
   - [ ] Execute creates collections
   - [ ] Collections appear under selected set
   - [ ] Collection names match sanitized preview
   - [ ] Results show correct count

5. **Edge Cases**
   - [ ] Empty input shows error
   - [ ] Whitespace-only lines ignored
   - [ ] Very long names handled
   - [ ] Unicode characters handled
   - [ ] Duplicate collection names handled
   - [ ] Deleted collection set detected

### Unit Testing Structure

For future unit tests, organize by module:

```
tests/
├── StringUtils_test.lua
├── CatalogUtils_test.lua
├── CollectionMechanic_test.lua
└── fixtures/
    └── test_data.lua
```

## Extension Points

### Adding New Features

1. **Character Replacement Options**
   - Add checkbox in dialog for different sanitization rules
   - Create variant of `sanitizeCollectionName()`

2. **Template-Based Naming**
   - Add text field for template (e.g., "Photo-{num}")
   - Create `expandTemplate(template, count)` function

3. **Collection Import from File**
   - Add button to select file
   - Create `importCollectionsFromFile(path)` function

4. **Batch Rename Collections**
   - Similar UI to batch create
   - Use `LrCollection.setName()` in write context

## Debugging

### Enable Logging

Lightroom logs appear in:
- **macOS**: `~/Library/Logs/Adobe/Lightroom/Lightroom Debug.log`
- **Windows**: `%APPDATA%\Adobe\Lightroom\Logs\Lightroom Debug.log`

Log messages:

```lua
local LrLogger = import 'LrLogger'
LrLogger.info("Creating collection: " .. name)
LrLogger.warn("Failed to create: " .. name)
```

### Common Issues

**Issue**: Plugin menu item doesn't appear
- Solution: Verify Info.lua syntax, restart Lightroom

**Issue**: Dialog won't open
- Solution: Check LrFunctionContext.callWithContext usage

**Issue**: Collections not created
- Solution: Verify `withWriteAccessDo` is used, check logs

**Issue**: Sanitization incorrect
- Solution: Verify RESERVED_CHARS table, test with gsub/match

## Performance Considerations

### For Large Batches

Currently, the plugin creates collections sequentially within a single `withWriteAccessDo` call.

**Optimization potential**:
- Batch validation (split parsing and creation)
- Progress indication for 100+ collections
- Async task with yield points

### Memory

- Collection set list is built recursively; deeply nested structures could impact memory
- Consider caching if dialog remains open for long time

## Compatibility Notes

- **SDK 3.0+**: Required for `createCollection()` function
- **Lightroom 15.3+**: Tested version
- **macOS/Windows**: Cross-platform compatible
- **Lua 5.1**: Standard Lightroom Lua

## File Structure Best Practices

Current structure follows Lightroom conventions:

```
plugin.lrdevplugin/
├── Info.lua                # Required metadata
├── MainEntry.lua           # Main menu entry point
├── Utilities/              # Helper modules
│   ├── StringUtils.lua
│   └── CatalogUtils.lua
├── UI/                     # UI-related modules
│   └── MainDialog.lua
├── Localization/           # Language strings
│   └── en.lproj/
│       └── Strings.lua
└── README.md               # User documentation
```

## Contributing

When adding new features:

1. Keep modules focused and single-responsibility
2. Use consistent naming (camelCase for functions)
3. Add documentation comments for public functions
4. Test edge cases (empty input, invalid data, etc.)
5. Use proper error handling (pcall for unsafe operations)
6. Update SPECIFICATION.md if behavior changes

## Version History

- **v1.0** (2024-06-30): Initial release
  - Basic batch creation
  - Dry run preview
  - Character sanitization
  - Hierarchical collection set support
