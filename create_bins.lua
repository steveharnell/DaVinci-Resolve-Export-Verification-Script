-- DaVinci Resolve Bin Creation Script
-- Creates OCN and TRANSCODES bins for export verification workflow

-- Connect to DaVinci Resolve
local resolve = Resolve()
local projectManager = resolve:GetProjectManager()
local project = projectManager:GetCurrentProject()

if not project then
    print("❌ Error: No project loaded. Please load a project and try again.")
    return
end

-- Get the media pool
local mediaPool = project:GetMediaPool()
local rootFolder = mediaPool:GetRootFolder()

-- Define bin names to create
local binNames = {"OCN", "TRANSCODES"}

-- Function to check if a bin already exists
function binExists(binName)
    local subFolders = rootFolder:GetSubFolders()
    if subFolders then
        for _, folder in ipairs(subFolders) do
            if folder:GetName() == binName then
                return true
            end
        end
    end
    return false
end

-- Function to create a bin if it doesn't exist
function createBinIfNeeded(binName)
    if binExists(binName) then
        print("ℹ️  Bin '" .. binName .. "' already exists - skipping")
        return false
    else
        local newBin = mediaPool:AddSubFolder(rootFolder, binName)
        if newBin then
            print("✅ Created bin: '" .. binName .. "'")
            return true
        else
            print("❌ Failed to create bin: '" .. binName .. "'")
            return false
        end
    end
end

-- Main execution
print("=== DaVinci Resolve Bin Setup ===")
print("Setting up bins for export verification workflow...")
print("")

local createdCount = 0
local existingCount = 0

-- Create each bin
for _, binName in ipairs(binNames) do
    if createBinIfNeeded(binName) then
        createdCount = createdCount + 1
    else
        if binExists(binName) then
            existingCount = existingCount + 1
        end
    end
end

-- Summary
print("")
print("=== SETUP COMPLETE ===")
print("Bins created: " .. createdCount)
print("Bins already existed: " .. existingCount)
print("")

if createdCount > 0 then
    print("🎉 Setup successful! You can now:")
    print("   1. Add your original camera files to the 'OCN' bin")
    print("   2. Add your exported/transcoded files to the 'TRANSCODES' bin")
    print("   3. Run the export verification script")
else
    print("ℹ️  All bins already exist. Your project is ready for verification.")
end

print("")
print("Next steps:")
print("   • Import your camera originals into the 'OCN' bin")
print("   • Import your exported footage into the 'TRANSCODES' bin")
print("   • Run the export verification script to compare them")
