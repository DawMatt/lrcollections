# Collection Mechanic - Lightroom Classic Plugin

A powerful Adobe Lightroom Classic plugin for creating multiple collections in bulk. Perfect for organizing large photo shoots, events, or any scenario where you need to create many collections at once.

## Features

- **Batch Collection Creation**: Create dozens of collections in seconds
- **Dry Run Mode**: Preview how collection names will be transformed before committing
- **Automatic Character Sanitization**: Invalid characters are automatically replaced with underscores
- **Hierarchical Collection Set Support**: Works with nested collection sets
- **Smart Duplicate Handling**: Gracefully handles collections that already exist
- **Detailed Results**: See exactly what was created and any issues that occurred

## Installation

1. Copy the `lrcollectionmechanic.lrdevplugin` folder to your Lightroom plugins directory:
   - **macOS**: `~/Library/Application Support/Adobe/Lightroom/Plugins/`
   - **Windows**: `C:\Users\[YourUsername]\AppData\Roaming\Adobe\Lightroom\Plugins\`

2. Restart Lightroom Classic

3. The plugin will appear in the Library menu

## Usage

### Basic Workflow

1. **Open the Plugin**
   - Go to Library menu → Collection Mechanic → "Create Collections in Batch"

2. **Select Root Collection Set**
   - Choose which collection set will contain your new collections
   - Can be any top-level or nested collection set

3. **Enter Collection Names**
   - Type collection names in the text field, one per line
   - Can use any characters; invalid ones will be sanitized

4. **Preview with Dry Run** (Recommended)
   - Click "Dry Run" to see how names will be transformed
   - Review the preview table
   - Characters are shown as replaced with underscores

5. **Execute**
   - Click "Execute" to create the collections
   - Results dialog shows what was created
   - Collections appear immediately in Lightroom

## Character Sanitization

The following characters are automatically replaced with underscores:
- `" * / \ : | ? < >`

**Examples:**
- `My Photos & Edits` → `My_Photos___Edits`
- `Event 2024: Best shots` → `Event_2024__Best_shots`
- `Before/After Comparison` → `Before_After_Comparison`

Leading and trailing whitespace is trimmed, and consecutive underscores are collapsed to a single underscore.

## Requirements

- Adobe Lightroom Classic 15.3 or later
- macOS 10.13+ or Windows 10+
- Plugin SDK version 3.0+

## Troubleshooting

### "No Collection Sets Found"
You need to create at least one collection set before using Collection Mechanic. Create a collection set in Lightroom first.

### Collection Not Created
If a collection name results in empty string after sanitization (all reserved characters), it will fail. Try using different characters in the name.

### Permission Denied
Make sure Lightroom has write access to your catalog and no other operations are in progress.

## Tips & Tricks

1. **Organize by Date**: Use names like `2024-06-15 Morning Session` and `2024-06-15 Evening Session`

2. **Template Pattern**: Create related collections with a consistent naming pattern: `Event_Setup`, `Event_Shooting`, `Event_Editing`, `Event_Final`

3. **Test First**: Always use "Dry Run" first to verify your collection names will look correct

4. **Batch Operations**: You can run the plugin multiple times if you have different collection structures to set up

## Technical Details

- **Plugin ID**: `com.thephotogeek.lrcollectionmechanic`
- **Version**: 1.0
- **Language**: Lua
- **Build**: 202605301000

### File Structure
```
lrcollectionmechanic.lrdevplugin/
├── Info.lua                    # Plugin metadata
├── CollectionMechanic.lua      # Main logic
├── UI_MainDialog.lua           # Dialog UI
└── Util_StringUtils.lua        # String utilities
└── Util_CatalogUtils.lua       # Catalog operations
```

## Support & Feedback

For issues, questions, or suggestions, please refer to the specification document included with this plugin.

## License

This plugin is provided as-is. Use at your own discretion.

## Version History

### v1.0 (2024-06-30)
- Initial release
- Batch collection creation with sanitization
- Dry run preview mode
- Hierarchical collection set support
