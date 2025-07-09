-- Connect to DaVinci Resolve
local resolve = Resolve()  -- Not require("Resolve")
local projectManager = resolve:GetProjectManager()
local project = projectManager:GetCurrentProject()

if not project then
    print("No project loaded. Please load a project and try again.")
    return
end

-- Get the media pool
local mediaPool = project:GetMediaPool()

-- Define bin names to compare
local binNameOriginal = "OCN"
local binNameExported = "TRANSCODES"

-- Custom table merge function (FIXED - was missing)
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
    local rootFolder = mediaPool:GetRootFolder()
    local subFolders = rootFolder:GetSubFolders()
    
    for _, folder in ipairs(subFolders) do
        if folder:GetName() == binName then
            return folder
        end
    end
    return nil
end

-- Function to collect all media items in a bin (FIXED API calls)
function collectMediaItems(bin)
    local items = {}
    local clips = bin:GetClips()  -- Correct API method
    
    -- Add clips from this bin
    for _, clip in ipairs(clips) do
        table.insert(items, clip)
    end
    
    -- Check subfolders recursively
    local subFolders = bin:GetSubFolders()
    if subFolders then
        for _, subFolder in ipairs(subFolders) do
            local subItems = collectMediaItems(subFolder)
            items = tableMerge(items, subItems)
        end
    end
    
    return items
end

-- Get the two bins (FIXED)
local originalBin = findBinByName(binNameOriginal)
local exportedBin = findBinByName(binNameExported)

if not originalBin or not exportedBin then
    print("One or both bins not found. Check bin names.")
    print("Looking for: '" .. binNameOriginal .. "' and '" .. binNameExported .. "'")
    return
end

-- Collect media items from both bins
local originalMedia = collectMediaItems(originalBin)
local exportedMedia = collectMediaItems(exportedBin)

print("Found " .. #originalMedia .. " clips in original bin")
print("Found " .. #exportedMedia .. " clips in exported bin")

-- FIXED: Function to get base filename without extension and _001 suffix
function getBaseName(filename)
    -- First remove the file extension
    local baseName = filename:match("(.+)%.[^%.]+$") or filename
    
    -- Then remove _001 suffix if it exists (common in camera files)
    baseName = baseName:gsub("_001$", "")
    
    return baseName
end

-- Create lookup table for exported clips by base name
local exportedLookup = {}
for _, clip in ipairs(exportedMedia) do
    local baseName = getBaseName(clip:GetName())
    exportedLookup[baseName] = clip
end

-- Compare media items by matching base filenames
local matchCount = 0
local missingInExport = {}
local mismatches = {}

for _, originalClip in ipairs(originalMedia) do
    local originalName = originalClip:GetName()
    local originalBaseName = getBaseName(originalName)
    local exportedClip = exportedLookup[originalBaseName]
    
    if not exportedClip then
        print("Missing in TRANSCODES: " .. originalName)
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
            print("Duration mismatch:")
            print("  Original: " .. originalName .. " (" .. (origDuration or "Unknown") .. ")")
            print("  Exported: " .. exportedClip:GetName() .. " (" .. (exportDuration or "Unknown") .. ")")
        else
            matchCount = matchCount + 1
            print("✓ Match: " .. originalBaseName)
        end
    end
end

-- Check for extra files in export bin
local extraInExport = {}
for _, exportedClip in ipairs(exportedMedia) do
    local exportedName = exportedClip:GetName()
    local exportedBaseName = getBaseName(exportedName)
    
    -- Check if this exported clip has a corresponding original
    local foundOriginal = false
    for _, originalClip in ipairs(originalMedia) do
        if getBaseName(originalClip:GetName()) == exportedBaseName then
            foundOriginal = true
            break
        end
    end
    
    if not foundOriginal then
        table.insert(extraInExport, exportedName)
        print("Extra in TRANSCODES (no original): " .. exportedName)
    end
end

-- Final summary
print("\n=== VERIFICATION SUMMARY ===")
print("Perfect matches: " .. matchCount)
print("Missing in TRANSCODES: " .. #missingInExport)
print("Extra in TRANSCODES: " .. #extraInExport)
print("Duration mismatches: " .. #mismatches)

if #missingInExport == 0 and #extraInExport == 0 and #mismatches == 0 then
    print("\n🎉 SUCCESS: All " .. matchCount .. " clips verified successfully!")
else
    print("\n⚠️  ISSUES FOUND - Review the details above")
end
