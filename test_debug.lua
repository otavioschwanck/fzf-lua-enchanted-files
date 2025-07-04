-- Simple test script to debug the plugin
local plugin = require("fzf-lua-enchanted-files")

print("=== TESTING FZF-LUA ENCHANTED FILES ===")

-- Test 1: Check if history loads correctly
print("\n1. Loading history...")
plugin.debug_history()

-- Test 2: Test the files function with debug output
print("\n2. Testing files function...")
local success, result = pcall(function()
  return plugin.files()
end)

if success then
  print("Files function executed successfully")
else
  print("Files function failed with error: " .. tostring(result))
end

print("\n=== TEST COMPLETE ===")