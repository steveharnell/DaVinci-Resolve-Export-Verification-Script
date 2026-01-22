# DaVinci Resolve Export Verification Script

A GUI-based Lua script for DaVinci Resolve that automates the import, organization, and verification of exported/transcoded footage against original camera files.

## Script Included

### **resolve_export_verification_GUI.lua** - Media Comparison Tool with GUI
A comprehensive tool with a graphical interface for comparing clips between OCN (Original Camera Negative) and TRANSCODES bins to verify all exports match their camera originals.

## What It Does

**GUI Features:**
- 🖥️ **Intuitive interface** with folder browser and real-time results display
- 📁 **Auto-import** - Automatically imports media from specified folders
- 💾 **Persistent settings** - Remembers folder paths between sessions
- 🔨 **Automatic bin creation** - Creates OCN and TRANSCODES bins as needed
- 📊 **Export logs** - Saves detailed comparison reports to Desktop
- 🎯 **Clear results display** - Real-time feedback with color-coded console

**Verification Capabilities:**
- 🔍 **Matches clips by filename** (ignoring file extensions and `_001` suffixes)
- 📊 **Handles different formats** - `.mov`, `.mp4`, `.mxf`, `.r3d`, `.braw`, `.avi`, `.mkv`, `.dng`
- ⏱️ **Verifies duration matching** to ensure complete exports
- 📋 **Detailed reporting** of matches, missing files, and mismatches
- 🔀 **Order independent** - clips don't need to be sorted the same way
- 🗂️ **Recursive folder scanning** - Finds media in nested subdirectories

## Installation

1. **Download the script** (`resolve_export_verification_GUI.lua`)

2. **Copy to DaVinci Resolve scripts folder**:
   - **macOS**: `/Users/[USERNAME]/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Utility`
   - **Windows**: `%APPDATA%\Blackmagic Design\DaVinci Resolve\Support\Fusion\Scripts\Utility`
   - **Linux**: `~/.local/share/DaVinciResolve/Fusion/Scripts/Utility`

   *(Replace `[USERNAME]` with your actual username on macOS)*

3. **Restart DaVinci Resolve** (if already running)

## How to Access

Once installed, launch the script via:

**Workspace → Scripts → Utility → resolve_export_verification_GUI**

## Complete Workflow

### First-Time Setup:
1. **Launch the script** from the Workspace menu
2. Click **"Browse..."** next to OCN Folder and select your original media folder
3. Click **"Browse..."** next to Transcodes Folder and select your transcoded media folder
4. Click **"Save Paths"** to remember these locations

### Regular Workflow:

#### Step 1: Auto Import Media
1. Click **"Auto Import"** to automatically import all supported media files from both folders
2. Script creates OCN and TRANSCODES bins if they don't exist
3. Files are organized into their respective bins

#### Step 2: Run Comparison
1. Click **"Run Comparison"** to verify exports against originals
2. Review results in the display window
3. Check for:
   - ✅ **Perfect matches** - Files with matching durations
   - ❌ **Missing in TRANSCODES** - Originals without exports
   - ⚠️ **Extra in TRANSCODES** - Exports without matching originals
   - ⚠️ **Duration mismatches** - Files with different lengths

#### Step 3: Export Results (Optional)
1. Click **"Export Log"** to save a timestamped report to your Desktop
2. Log file includes all verification details for archival

## GUI Overview

**Interface Components:**
- **Bin Name Fields** - Customize bin names (default: "OCN" and "TRANSCODES")
- **Folder Path Fields** - Specify source folders for auto-import
- **Browse Buttons** - macOS folder picker dialogs
- **Save Paths** - Persist folder locations between sessions
- **Auto Import** - Scan and import media from specified folders
- **Create Bins** - Manually create OCN and TRANSCODES bins
- **Run Comparison** - Execute verification analysis
- **Export Log** - Save results to text file
- **Clear Results** - Reset the display window
- **Results Display** - Real-time feedback with monospace formatting

## Example Output

**Auto Import:**
```
Starting auto-import...

Creating OCN bin...
Creating TRANSCODES bin...

Scanning OCN folder: /Volumes/Media/Originals
Found 95 media files in OCN folder
✓ Imported to OCN bin

Scanning TRANSCODES folder: /Volumes/Media/Transcodes
Found 95 media files in TRANSCODES folder
✓ Imported to TRANSCODES bin

=== AUTO-IMPORT COMPLETE ===
Total OCN files: 95
Total TRANSCODES files: 95
```

**Verification Results:**
```
Found 95 clips in original bin
Found 95 clips in exported bin

✓ Match: A001C006_250613_RNQZ
✓ Match: A001C008_250613_RNQZ
MISSING in TRANSCODES: A001C010_250613_RNQZ.mxf
✓ Match: A001C012_250613_RNQZ

=== VERIFICATION SUMMARY ===
Perfect matches: 94
Missing in TRANSCODES: 1
Extra in TRANSCODES: 0
Duration mismatches: 0

ISSUES FOUND - Review the details above
```

## File Matching Examples

The verification script intelligently matches files by base name (ignoring extensions and `_001` suffixes):
- `A001C006_250613_RNQZ.mxf` ↔ `A001C006_250613_RNQZ.mov` ✅
- `CLIP001.R3D` ↔ `CLIP001.mov` ✅  
- `Interview_Take1_001.mov` ↔ `Interview_Take1.mp4` ✅
- `Scene_05.braw` ↔ `Scene_05.mp4` ✅

## Supported File Formats

The script automatically detects and imports these media formats:
- `.mov` - QuickTime
- `.mp4` - MPEG-4
- `.mxf` - Material Exchange Format
- `.r3d` - RED Digital Cinema
- `.braw` - Blackmagic RAW
- `.avi` - Audio Video Interleave
- `.mkv` - Matroska Video
- `.dng` - Digital Negative (image sequences)

## Use Cases

- **DIT Workflows**: Verify all camera originals were properly transcoded on set
- **Post-production QC**: Confirm all media survived the transcode process
- **Delivery verification**: Ensure exported files match source footage exactly
- **Archive management**: Check backup transcodes are complete before drive returns
- **Batch processing validation**: Confirm no clips were missed during automated workflows
- **Multi-camera projects**: Verify all camera angles were transcoded

## Configuration File

The script creates a configuration file to remember your folder paths:
- **Location**: `~/.resolve_media_compare_config.txt`
- **Contents**: OCN folder path and Transcodes folder path
- **Auto-loads** on script launch for convenience

## Troubleshooting

**"ERROR: No project loaded"**
- Open a DaVinci Resolve project before running the script

**"ERROR: Please enter folder paths and click 'Save Paths' first"**
- Use the Browse buttons to select your folders
- Click Save Paths before running Auto Import

**"✗ Import to OCN bin failed (files may already exist)"**
- Files are already in the media pool
- This is normal if running import multiple times on the same media

**No clips appear in bins after import**
- Check that the folder paths are correct
- Verify the folders contain supported media formats
- Try manually importing one file to test media pool access

**Duration mismatches reported**
- Verify your transcode settings match source frame rates
- Check for clips that were trimmed during export
- Some formats report duration differently (frames vs. timecode)

## Requirements

- **DaVinci Resolve** (Studio or Free) with Lua scripting support
- **macOS** (uses AppleScript for folder browser dialogs; Windows/Linux support possible with modifications)
- **Consistent filename conventions** between originals and exports
- **Project open** in DaVinci Resolve before running script

## Tips for Best Results

1. **Organize before import** - Keep OCN and transcode files in separate folders
2. **Consistent naming** - Use the same base filenames for originals and exports
3. **Export logs regularly** - Save verification reports for your records
4. **Check duration mismatches** - These often indicate incomplete transcodes
5. **Review missing files** - May indicate failed exports or incorrect folder selection

## Contributing

Submit issues or pull requests to improve functionality or add new verification features.

## License

This script is provided as-is for educational and production use. Modify as needed for your workflow.

---

**Created for DITs and post-production professionals who need reliable verification of transcoded media.**
