-- DaVinci Resolve Media Comparison Tool with GUI
-- Compare clips between OCN and TRANSCODES bins

local resolve = Resolve()
local projectManager = resolve:GetProjectManager()
local project = projectManager:GetCurrentProject()

-- Initialize UI Manager
local ui = app.UIManager
local disp = bmd.UIDispatcher(ui)

-- Global variables
local binNameOriginal = "OCN"
local binNameExported = "TRANSCODES"
local resultsText = ""
local configFilePath = os.getenv("HOME") .. "/.resolve_media_compare_config.txt"

-- Custom table merge function
function tableMerge(t1, t2)
    local result = {}
    for _, v in ipairs(t1) do
        table.insert(result, v)
    end
    for _, v in ipairs(t2) do
        table.insert(result, v)
    end
    return result
end

-- Function to find bin by name
function findBinByName(binName)
    local mediaPool = project:GetMediaPool()
    local rootFolder = mediaPool:GetRootFolder()
    local subFolders = rootFolder:GetSubFolders()

    for _, folder in ipairs(subFolders) do
        if folder:GetName() == binName then
            return folder
        end
    end
    return nil
end

-- Function to collect all media items in a bin
function collectMediaItems(bin)
    local items = {}
    local clips = bin:GetClips()

    for _, clip in ipairs(clips) do
        table.insert(items, clip)
    end

    local subFolders = bin:GetSubFolders()
    if subFolders then
        for _, subFolder in ipairs(subFolders) do
            local subItems = collectMediaItems(subFolder)
            items = tableMerge(items, subItems)
        end
    end

    return items
end

-- Function to get base filename without extension and _001 suffix
function getBaseName(filename)
    local baseName = filename:match("(.+)%.[^%.]+$") or filename
    baseName = baseName:gsub("_001$", "")
    return baseName
end

-- Function to browse for folder using AppleScript
function browseForFolder(title)
    local cmd = 'osascript -e \'set folderPath to choose folder with prompt "' .. title .. '"\' -e \'return POSIX path of folderPath\' 2>/dev/null'
    local handle = io.popen(cmd)
    if handle then
        local result = handle:read("*a")
        handle:close()
        -- Remove trailing newline and slash
        result = result:gsub("\n$", ""):gsub("/$", "")
        if result and result ~= "" then
            -- Force window to front after dialog closes
            os.execute('osascript -e \'tell application "DaVinci Resolve" to activate\' 2>/dev/null &')
            return result
        end
    end
    -- Force window to front even if cancelled
    os.execute('osascript -e \'tell application "DaVinci Resolve" to activate\' 2>/dev/null &')
    return nil
end

-- Function to browse for OCN folder
function browseOCNFolder()
    local selectedPath = browseForFolder("Select OCN Folder")
    if selectedPath then
        win:GetItems().OCNPathField.Text = selectedPath
        print("OCN path selected: " .. selectedPath)
    end
end

-- Function to browse for Transcodes folder
function browseTranscodesFolder()
    local selectedPath = browseForFolder("Select Transcodes Folder")
    if selectedPath then
        win:GetItems().TranscodesPathField.Text = selectedPath
        print("Transcodes path selected: " .. selectedPath)
    end
end

-- Function to save folder paths to config file
function savePaths()
    local ocnPath = win:GetItems().OCNPathField.Text
    local transcodesPath = win:GetItems().TranscodesPathField.Text

    local file = io.open(configFilePath, "w")
    if file then
        file:write(ocnPath .. "\n")
        file:write(transcodesPath .. "\n")
        file:close()

        local msg = win:GetItems().ResultsDisplay.PlainText
        msg = msg .. "\n✓ Folder paths saved!\n"
        win:GetItems().ResultsDisplay:SetText(msg)
        print("Paths saved to: " .. configFilePath)
    else
        local msg = win:GetItems().ResultsDisplay.PlainText
        msg = msg .. "\n✗ Failed to save paths\n"
        win:GetItems().ResultsDisplay:SetText(msg)
    end
end

-- Function to load folder paths from config file
function loadPaths()
    local file = io.open(configFilePath, "r")
    if file then
        local ocnPath = file:read("*line")
        local transcodesPath = file:read("*line")
        file:close()

        if ocnPath then
            win:GetItems().OCNPathField.Text = ocnPath
        end
        if transcodesPath then
            win:GetItems().TranscodesPathField.Text = transcodesPath
        end

        print("Paths loaded from: " .. configFilePath)
        return true
    end
    return false
end

-- Function to scan directory and get all media files
function scanDirectory(dirPath)
    local files = {}

    -- Use ls command to get files
    local handle = io.popen('find "' .. dirPath .. '" -type f \\( -iname "*.mov" -o -iname "*.mp4" -o -iname "*.mxf" -o -iname "*.r3d" -o -iname "*.braw" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.dng" \\)')
    if handle then
        for file in handle:lines() do
            table.insert(files, file)
        end
        handle:close()
    end

    return files
end

-- Function to auto-import media files
function autoImport()
    if not project then
        win:GetItems().ResultsDisplay:SetText("ERROR: No project loaded.\n")
        return
    end

    local ocnPath = win:GetItems().OCNPathField.Text
    local transcodesPath = win:GetItems().TranscodesPathField.Text

    if ocnPath == "" or transcodesPath == "" then
        win:GetItems().ResultsDisplay:SetText("ERROR: Please enter folder paths and click 'Save Paths' first.\n")
        return
    end

    resultsText = "Starting auto-import...\n\n"
    win:GetItems().ResultsDisplay:SetText(resultsText)

    local mediaPool = project:GetMediaPool()

    -- Get or create bins
    local ocnBin = findBinByName(binNameOriginal)
    local transcodesBin = findBinByName(binNameExported)

    if not ocnBin then
        resultsText = resultsText .. "Creating OCN bin...\n"
        ocnBin = mediaPool:AddSubFolder(mediaPool:GetRootFolder(), binNameOriginal)
    end

    if not transcodesBin then
        resultsText = resultsText .. "Creating TRANSCODES bin...\n"
        transcodesBin = mediaPool:AddSubFolder(mediaPool:GetRootFolder(), binNameExported)
    end

    win:GetItems().ResultsDisplay:SetText(resultsText)

    -- Scan and import OCN files
    resultsText = resultsText .. "\nScanning OCN folder: " .. ocnPath .. "\n"
    win:GetItems().ResultsDisplay:SetText(resultsText)

    local ocnFiles = scanDirectory(ocnPath)
    resultsText = resultsText .. "Found " .. #ocnFiles .. " media files in OCN folder\n"

    if #ocnFiles > 0 then
        mediaPool:SetCurrentFolder(ocnBin)
        local imported = mediaPool:ImportMedia(ocnFiles)
        if imported then
            resultsText = resultsText .. "✓ Imported to OCN bin\n"
        else
            resultsText = resultsText .. "✗ Import to OCN bin failed (files may already exist)\n"
        end
    end

    win:GetItems().ResultsDisplay:SetText(resultsText)

    -- Scan and import TRANSCODES files
    resultsText = resultsText .. "\nScanning TRANSCODES folder: " .. transcodesPath .. "\n"
    win:GetItems().ResultsDisplay:SetText(resultsText)

    local transcodesFiles = scanDirectory(transcodesPath)
    resultsText = resultsText .. "Found " .. #transcodesFiles .. " media files in TRANSCODES folder\n"

    if #transcodesFiles > 0 then
        mediaPool:SetCurrentFolder(transcodesBin)
        local imported = mediaPool:ImportMedia(transcodesFiles)
        if imported then
            resultsText = resultsText .. "✓ Imported to TRANSCODES bin\n"
        else
            resultsText = resultsText .. "✗ Import to TRANSCODES bin failed (files may already exist)\n"
        end
    end

    resultsText = resultsText .. "\n=== AUTO-IMPORT COMPLETE ===\n"
    resultsText = resultsText .. "Total OCN files: " .. #ocnFiles .. "\n"
    resultsText = resultsText .. "Total TRANSCODES files: " .. #transcodesFiles .. "\n"

    win:GetItems().ResultsDisplay:SetText(resultsText)
end

-- Function to export log to file
function exportLog()
    -- Debug: Show that function is being called
    print("Export Log button clicked!")

    local currentResults = win:GetItems().ResultsDisplay.PlainText
    print("Current results length: " .. #currentResults)

    if currentResults == "" or currentResults == "Click 'Run Comparison' to start..." then
        local tempText = "No results to export. Run a comparison first.\n"
        win:GetItems().ResultsDisplay:SetText(tempText)
        print("No results to export")
        return
    end

    -- Get timestamp for filename
    local timestamp = os.date("%Y-%m-%d_%H-%M-%S")
    local projectName = "Unknown"

    if project then
        projectName = project:GetName() or "Unknown"
    end

    print("Project name: " .. projectName)

    -- Save to Desktop automatically
    local homeDir = os.getenv("HOME")
    print("Home dir: " .. (homeDir or "nil"))

    local desktopPath = homeDir .. "/Desktop/"
    local filename = "MediaComparison_" .. projectName .. "_" .. timestamp .. ".txt"
    local fullPath = desktopPath .. filename

    print("Attempting to write to: " .. fullPath)

    -- Write log file
    local file, err = io.open(fullPath, "w")
    if file then
        print("File opened successfully")
        -- Write header
        file:write("===========================================\n")
        file:write("DaVinci Resolve - Media Comparison Log\n")
        file:write("===========================================\n")
        file:write("Project: " .. projectName .. "\n")
        file:write("Date: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
        file:write("Original Bin: " .. win:GetItems().OriginalBinName:GetText() .. "\n")
        file:write("Exported Bin: " .. win:GetItems().ExportedBinName:GetText() .. "\n")
        file:write("===========================================\n\n")

        -- Write results
        file:write(currentResults)

        file:close()
        print("File written and closed successfully")

        local successMsg = currentResults .. "\n\n--- LOG EXPORTED ---\nSaved to: " .. fullPath .. "\n"
        win:GetItems().ResultsDisplay:SetText(successMsg)
    else
        print("ERROR opening file: " .. (err or "unknown error"))
        local errorMsg = currentResults .. "\n\nERROR: Could not write to file: " .. fullPath .. "\n"
        if err then
            errorMsg = errorMsg .. "Error: " .. err .. "\n"
        end
        win:GetItems().ResultsDisplay:SetText(errorMsg)
    end
end

-- Function to create bins
function createBins()
    resultsText = ""

    if not project then
        resultsText = "ERROR: No project loaded. Please load a project and try again.\n"
        win:GetItems().ResultsDisplay:SetText(resultsText)
        return
    end

    local mediaPool = project:GetMediaPool()
    local rootFolder = mediaPool:GetRootFolder()

    -- Get bin names from text fields
    local origBinName = win:GetItems().OriginalBinName:GetText()
    local exportBinName = win:GetItems().ExportedBinName:GetText()

    resultsText = "Creating bins...\n\n"

    -- Check if bins already exist
    local origBinExists = findBinByName(origBinName)
    local exportBinExists = findBinByName(exportBinName)

    -- Create Original Bin if it doesn't exist
    if origBinExists then
        resultsText = resultsText .. "✓ Bin '" .. origBinName .. "' already exists\n"
    else
        local newBin = mediaPool:AddSubFolder(rootFolder, origBinName)
        if newBin then
            resultsText = resultsText .. "✓ Created bin: '" .. origBinName .. "'\n"
        else
            resultsText = resultsText .. "✗ Failed to create bin: '" .. origBinName .. "'\n"
        end
    end

    -- Create Exported Bin if it doesn't exist
    if exportBinExists then
        resultsText = resultsText .. "✓ Bin '" .. exportBinName .. "' already exists\n"
    else
        local newBin = mediaPool:AddSubFolder(rootFolder, exportBinName)
        if newBin then
            resultsText = resultsText .. "✓ Created bin: '" .. exportBinName .. "'\n"
        else
            resultsText = resultsText .. "✗ Failed to create bin: '" .. exportBinName .. "'\n"
        end
    end

    resultsText = resultsText .. "\nBin creation complete!\n"
    win:GetItems().ResultsDisplay:SetText(resultsText)
end

-- Main comparison function
function runComparison()
    resultsText = ""

    if not project then
        resultsText = "ERROR: No project loaded. Please load a project and try again.\n"
        win:GetItems().ResultsDisplay:SetText(resultsText)
        return
    end

    local mediaPool = project:GetMediaPool()

    -- Update bin names from text fields
    binNameOriginal = win:GetItems().OriginalBinName:GetText()
    binNameExported = win:GetItems().ExportedBinName:GetText()

    resultsText = "Starting comparison...\n"
    resultsText = resultsText .. "Original Bin: " .. binNameOriginal .. "\n"
    resultsText = resultsText .. "Exported Bin: " .. binNameExported .. "\n\n"
    win:GetItems().ResultsDisplay:SetText(resultsText)

    -- Get the two bins
    local originalBin = findBinByName(binNameOriginal)
    local exportedBin = findBinByName(binNameExported)

    if not originalBin or not exportedBin then
        resultsText = resultsText .. "ERROR: One or both bins not found. Check bin names.\n"
        resultsText = resultsText .. "Looking for: '" .. binNameOriginal .. "' and '" .. binNameExported .. "'\n"
        win:GetItems().ResultsDisplay:SetText(resultsText)
        return
    end

    -- Collect media items from both bins
    local originalMedia = collectMediaItems(originalBin)
    local exportedMedia = collectMediaItems(exportedBin)

    resultsText = resultsText .. "Found " .. #originalMedia .. " clips in original bin\n"
    resultsText = resultsText .. "Found " .. #exportedMedia .. " clips in exported bin\n\n"
    win:GetItems().ResultsDisplay:SetText(resultsText)

    -- Create lookup table for exported clips
    local exportedLookup = {}
    for _, clip in ipairs(exportedMedia) do
        local baseName = getBaseName(clip:GetName())
        exportedLookup[baseName] = clip
    end

    -- Compare media items
    local matchCount = 0
    local missingInExport = {}
    local mismatches = {}

    for _, originalClip in ipairs(originalMedia) do
        local originalName = originalClip:GetName()
        local originalBaseName = getBaseName(originalName)
        local exportedClip = exportedLookup[originalBaseName]

        if not exportedClip then
            resultsText = resultsText .. "MISSING in TRANSCODES: " .. originalName .. "\n"
            table.insert(missingInExport, originalName)
        else
            -- Compare metadata
            local origDuration = originalClip:GetClipProperty("Duration")
            local exportDuration = exportedClip:GetClipProperty("Duration")

            if origDuration ~= exportDuration then
                local mismatch = {
                    original = originalName,
                    exported = exportedClip:GetName(),
                    issue = "Duration mismatch",
                    origValue = origDuration or "Unknown",
                    exportValue = exportDuration or "Unknown"
                }
                table.insert(mismatches, mismatch)
                resultsText = resultsText .. "DURATION MISMATCH:\n"
                resultsText = resultsText .. "  Original: " .. originalName .. " (" .. (origDuration or "Unknown") .. ")\n"
                resultsText = resultsText .. "  Exported: " .. exportedClip:GetName() .. " (" .. (exportDuration or "Unknown") .. ")\n"
            else
                matchCount = matchCount + 1
                resultsText = resultsText .. "✓ Match: " .. originalBaseName .. "\n"
            end
        end
        win:GetItems().ResultsDisplay:SetText(resultsText)
    end

    -- Check for extra files in export bin
    local extraInExport = {}
    for _, exportedClip in ipairs(exportedMedia) do
        local exportedName = exportedClip:GetName()
        local exportedBaseName = getBaseName(exportedName)

        local foundOriginal = false
        for _, originalClip in ipairs(originalMedia) do
            if getBaseName(originalClip:GetName()) == exportedBaseName then
                foundOriginal = true
                break
            end
        end

        if not foundOriginal then
            table.insert(extraInExport, exportedName)
            resultsText = resultsText .. "EXTRA in TRANSCODES (no original): " .. exportedName .. "\n"
        end
    end

    -- Final summary
    resultsText = resultsText .. "\n=== VERIFICATION SUMMARY ===\n"
    resultsText = resultsText .. "Perfect matches: " .. matchCount .. "\n"
    resultsText = resultsText .. "Missing in TRANSCODES: " .. #missingInExport .. "\n"
    resultsText = resultsText .. "Extra in TRANSCODES: " .. #extraInExport .. "\n"
    resultsText = resultsText .. "Duration mismatches: " .. #mismatches .. "\n\n"

    if #missingInExport == 0 and #extraInExport == 0 and #mismatches == 0 then
        resultsText = resultsText .. "SUCCESS: All " .. matchCount .. " clips verified successfully!\n"
    else
        resultsText = resultsText .. "ISSUES FOUND - Review the details above\n"
    end

    win:GetItems().ResultsDisplay:SetText(resultsText)
end

-- Create the GUI window
win = disp:AddWindow({
    ID = "CompareWindow",
    WindowTitle = "Media Comparison Tool by 32Thirteen Productions, LLC",
    Geometry = {100, 100, 800, 600},

    ui:VGroup{
        ID = "root",
        Spacing = 5,

        -- Bin names section
        ui:HGroup{
            Weight = 0,
            Spacing = 10,
            ui:Label{Text = "Original Bin:", Weight = 0, MinimumSize = {80, 0}},
            ui:LineEdit{
                ID = "OriginalBinName",
                Text = "OCN",
                PlaceholderText = "Enter original bin name",
            },
            ui:Label{Text = "Exported Bin:", Weight = 0, MinimumSize = {85, 0}},
            ui:LineEdit{
                ID = "ExportedBinName",
                Text = "TRANSCODES",
                PlaceholderText = "Enter exported bin name",
            },
        },

        -- Folder paths section
        ui:HGroup{
            Weight = 0,
            Spacing = 10,
            ui:Label{Text = "OCN Folder:", Weight = 0, MinimumSize = {80, 0}},
            ui:LineEdit{
                ID = "OCNPathField",
                Text = "",
                PlaceholderText = "/path/to/OCN/folder",
            },
            ui:Button{
                ID = "BrowseOCNButton",
                Text = "Browse...",
                MinimumSize = {80, 0},
            },
        },

        ui:HGroup{
            Weight = 0,
            Spacing = 10,
            ui:Label{Text = "Transcodes Folder:", Weight = 0, MinimumSize = {80, 0}},
            ui:LineEdit{
                ID = "TranscodesPathField",
                Text = "",
                PlaceholderText = "/path/to/TRANSCODES/folder",
            },
            ui:Button{
                ID = "BrowseTranscodesButton",
                Text = "Browse...",
                MinimumSize = {80, 0},
            },
        },

        -- Import buttons
        ui:HGroup{
            Weight = 0,
            Spacing = 10,
            ui:Button{
                ID = "SavePathsButton",
                Text = "Save Paths",
            },
            ui:Button{
                ID = "AutoImportButton",
                Text = "Auto Import",
            },
        },

        -- Action buttons
        ui:HGroup{
            Weight = 0,
            Spacing = 10,
            ui:Button{
                ID = "CreateBinsButton",
                Text = "Create Bins",
            },
            ui:Button{
                ID = "CompareButton",
                Text = "Run Comparison",
            },
            ui:Button{
                ID = "ExportLogButton",
                Text = "Export Log",
            },
            ui:Button{
                ID = "ClearButton",
                Text = "Clear Results",
            },
        },

        ui:TextEdit{
            ID = "ResultsDisplay",
            Text = "Click 'Run Comparison' to start...",
            ReadOnly = true,
            StyleSheet = [[
                font-family: monospace;
                background-color: #1e1e1e;
                color: #d4d4d4;
                padding: 8px;
            ]],
        },

        -- Close button
        ui:HGroup{
            Weight = 0,
            ui:HGap(0, 1),
            ui:Button{
                ID = "CloseButton",
                Text = "Close",
            },
        },
    },
})

-- Get window items
itm = win:GetItems()

-- Button click handlers
function win.On.BrowseOCNButton.Clicked(ev)
    browseOCNFolder()
end

function win.On.BrowseTranscodesButton.Clicked(ev)
    browseTranscodesFolder()
end

function win.On.SavePathsButton.Clicked(ev)
    savePaths()
end

function win.On.AutoImportButton.Clicked(ev)
    autoImport()
end

function win.On.CreateBinsButton.Clicked(ev)
    createBins()
end

function win.On.CompareButton.Clicked(ev)
    runComparison()
end

function win.On.ExportLogButton.Clicked(ev)
    exportLog()
end

function win.On.ClearButton.Clicked(ev)
    itm.ResultsDisplay:SetText("")
end

function win.On.CloseButton.Clicked(ev)
    disp:ExitLoop()
end

-- Load saved paths on startup
loadPaths()

-- Show the window
win:Show()
disp:RunLoop()
win:Hide()
