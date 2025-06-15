# DaVinci-Resolve-Export-Verification-Script
A Lua script for DaVinci Resolve that verifies exported/transcoded footage matches the original camera files by comparing clips between two bins.
## What it does

- **Compares clips by filename** (ignoring file extensions) between original camera footage and exported transcodes
- **Handles different file formats** - matches `.mxf`, `.R3D`, `.mov`, etc. based on base filename
- **Verifies duration matching** to ensure complete exports
- **Provides detailed reporting** of matches, missing files, and mismatches
- **Doesn't require clips to be in the same order** in both bins

## Use Cases

- **Post-production QC**: Verify all camera originals have been properly transcoded
- **Delivery verification**: Confirm exported files match source footage
- **Archive management**: Check that backup transcodes are complete
- **Workflow validation**: Ensure no clips were missed during batch processing

## Installation

1. **Download the script** (`resolve_export_verification.lua`)

2. **Copy to DaVinci Resolve scripts folder**:
   - **macOS**: `~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/`
   - **Windows**: `%APPDATA%\Blackmagic Design\DaVinci Resolve\Support\Fusion\Scripts\`
   - **Linux**: `~/.local/share/DaVinciResolve/Fusion/Scripts/`

3. **Restart DaVinci Resolve** (if it was already running)

## Setup

1. **Organize your bins**:
   - Create a bin for your **original camera files** (e.g., "OCN", "Camera Originals")
   - Create a bin for your **exported/transcoded files** (e.g., "TRANSCODES", "Proxies")

2. **Configure the script**:
   ```lua
   local binNameOriginal = "OCN"           -- Change to your original footage bin name
   local binNameExported = "TRANSCODES"    -- Change to your exported footage bin name
   ```

## Usage

### Method 1: Scripts Menu
1. In DaVinci Resolve, go to **Workspace → Scripts**
2. Select your verification script from the list
3. Click **Execute**

### Method 2: Console
1. Go to **Workspace → Console**
2. Load and run the script:
   ```lua
   dofile("/path/to/your/script.lua")
   ```

## Example Output

```
Found 95 clips in original bin
Found 95 clips in exported bin
✓ Match: A001C006_250613_RNQZ
✓ Match: A001C008_250613_RNQZ
Missing in TRANSCODES: A001C010_250613_RNQZ.mxf
Duration mismatch:
  Original: A001C015_250613_RNQZ.mxf (00:02:30:15)
  Exported: A001C015_250613_RNQZ.mov (00:02:30:10)

=== VERIFICATION SUMMARY ===
Perfect matches: 93
Missing in TRANSCODES: 1
Extra in TRANSCODES: 0
Duration mismatches: 1

⚠️  ISSUES FOUND - Review the details above
```

## File Matching Logic

The script matches files by **base filename**, ignoring extensions:
- `A001C006_250613_RNQZ.mxf` ↔ `A001C006_250613_RNQZ.mov` ✅
- `CLIP001.R3D` ↔ `CLIP001.mov` ✅
- `Interview_01.mov` ↔ `Interview_01.mp4` ✅

## Requirements

- **DaVinci Resolve** (any recent version with Lua scripting support)
- **Organized media bins** with original and transcoded footage
- **Consistent filename conventions** (same base names for originals and exports)

## Troubleshooting

**"One or both bins not found"**
- Check that your bin names in the script match exactly (case-sensitive)
- Ensure bins are in the root level of your media pool

**"No clips found"**
- Verify clips are actually in the specified bins
- Check that clips are imported into the media pool, not just referenced

**Script won't run**
- Ensure the script file has `.lua` extension
- Check that DaVinci Resolve has access to the scripts folder
- Try running from the Console first to see detailed error messages

## Contributing

Feel free to submit issues or pull requests to improve the script functionality or add new verification features.

## License

This script is provided as-is for educational and production use. Modify as needed for your workflow.
