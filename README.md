# DaVinci Resolve Export Verification Scripts

Two Lua scripts for DaVinci Resolve that automate the setup and verification of exported/transcoded footage against original camera files.

## Scripts Included

### 1. **create_bins.lua** - Bin Creation
Creates the required "OCN" and "TRANSCODES" bins in your media pool for organizing footage.

### 2. **resolve_export_verification.lua** - Export Verification  
Compares clips between the two bins to verify all exports match their camera originals.

## What They Do

**Setup Script:**
- ✅ Creates "OCN" and "TRANSCODES" bins automatically
- ✅ Checks for existing bins to avoid duplicates
- ✅ Provides clear setup instructions

**Verification Script:**
- 🔍 **Matches clips by filename** (ignoring file extensions)
- 📊 **Handles different formats** - `.mxf`, `.R3D`, `.mov`, etc.
- ⏱️ **Verifies duration matching** to ensure complete exports
- 📋 **Detailed reporting** of matches, missing files, and mismatches
- 🔀 **Order independent** - clips don't need to be sorted the same way

## Installation

1. **Download both scripts** (`create_bins.lua` and `resolve_export_verification.lua`)

2. **Copy to DaVinci Resolve scripts folder**:
   - **macOS**: `~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/`
   - **Windows**: `%APPDATA%\Blackmagic Design\DaVinci Resolve\Support\Fusion\Scripts\`
   - **Linux**: `~/.local/share/DaVinciResolve/Fusion/Scripts/`

3. **Restart DaVinci Resolve** (if already running)

## Complete Workflow

### Step 1: Setup Your Bins
1. Run **create_bins.lua** via **Workspace → Scripts**
2. Script creates "OCN" and "TRANSCODES" bins in your media pool

### Step 2: Import Your Footage
- **Drag original camera files** into the **"OCN"** bin
- **Drag exported/transcoded files** into the **"TRANSCODES"** bin

### Step 3: Verify Your Exports
1. Run **resolve_export_verification.lua** via **Workspace → Scripts**
2. Review the verification report in the console

## Example Output

**Setup Script:**
```
=== DaVinci Resolve Bin Setup ===
✅ Created bin: 'OCN'
✅ Created bin: 'TRANSCODES'

🎉 Setup successful! You can now:
   1. Add your original camera files to the 'OCN' bin
   2. Add your exported/transcoded files to the 'TRANSCODES' bin
   3. Run the export verification script
```

**Verification Script:**
```
Found 95 clips in original bin
Found 95 clips in exported bin
✓ Match: A001C006_250613_RNQZ
✓ Match: A001C008_250613_RNQZ
Missing in TRANSCODES: A001C010_250613_RNQZ.mxf

=== VERIFICATION SUMMARY ===
Perfect matches: 94
Missing in TRANSCODES: 1
Extra in TRANSCODES: 0
Duration mismatches: 0

⚠️  ISSUES FOUND - Review the details above
```

## File Matching Examples

The verification script intelligently matches files by base name:
- `A001C006_250613_RNQZ.mxf` ↔ `A001C006_250613_RNQZ.mov` ✅
- `CLIP001.R3D` ↔ `CLIP001.mov` ✅  
- `Interview_Take1.mov` ↔ `Interview_Take1.mp4` ✅

## Use Cases

- **Post-production QC**: Verify all camera originals were properly transcoded
- **Delivery verification**: Confirm exported files match source footage  
- **Archive management**: Check backup transcodes are complete
- **Batch processing validation**: Ensure no clips were missed during automated workflows

## Running the Scripts

### Method 1: Scripts Menu
1. **Workspace → Scripts**
2. Select script and click **Execute**

### Method 2: Console  
1. **Workspace → Console**
2. Type: `dofile("/path/to/script.lua")`

## Troubleshooting

**"No project loaded"**
- Open a DaVinci Resolve project before running scripts

**"One or both bins not found"** 
- Run the setup script first to create the required bins
- Check that bin names match exactly (case-sensitive)

**"No clips found"**
- Ensure clips are imported into the media pool bins
- Verify clips are in the correct bins (OCN vs TRANSCODES)

## Requirements

- **DaVinci Resolve** with Lua scripting support
- **Consistent filename conventions** between originals and exports
- **Media organized in bins** (not just browser references)

## File Structure
```
your-scripts-folder/
├── create_bins.lua                 # Creates OCN and TRANSCODES bins
└── resolve_export_verification.lua # Verifies exports match originals
```

## Contributing

Submit issues or pull requests to improve functionality or add new verification features.

## License

These scripts are provided as-is for educational and production use. Modify as needed for your workflow.
