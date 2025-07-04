-- Test script to run inside Neovim to validate the picker behavior
-- Run this with: :luafile test_picker_nvim.lua

local function test_picker_behavior()
  print("=== TESTING FZF-LUA ENCHANTED FILES PICKER ===")
  
  -- Load the plugin
  local plugin = require("fzf-lua-enchanted-files")
  
  -- Test 1: Check current history
  print("\n1. Current history state:")
  plugin.debug_history()
  
  -- Test 2: Simulate what happens when we build the file list
  print("\n2. Testing file list generation...")
  
  -- Mock the recent files function to see what it returns
  local history_file = vim.fn.stdpath("data") .. "/fzf-lua-enchanted-files-history.json"
  print("History file: " .. history_file)
  
  if vim.fn.filereadable(history_file) == 1 then
    local file = io.open(history_file, "r")
    if file then
      local content = file:read("*a")
      file:close()
      print("History file content:")
      print(content)
      
      -- Parse and show what files we have
      local ok, data = pcall(vim.json.decode, content)
      if ok and data then
        local cwd = vim.fn.getcwd()
        print("Current CWD: " .. cwd)
        
        if data[cwd] then
          print("Files in history for current CWD:")
          for i, entry in ipairs(data[cwd]) do
            print("  " .. i .. ": '" .. entry.path .. "' (readable: " .. vim.fn.filereadable(entry.path) .. ")")
          end
        else
          print("No history for current CWD")
        end
      end
    end
  else
    print("History file does not exist")
  end
  
  -- Test 3: Test the script generation manually
  print("\n3. Testing script generation...")
  
  -- Simulate recent files (with potential leading spaces to test)
  local test_recent_files = {" app/models/charge.rb", " docker/entrypoint.sh"}
  
  print("Test recent files:")
  for i, f in ipairs(test_recent_files) do
    print("  " .. i .. ": '" .. f .. "'")
  end
  
  -- Generate and test the script
  local original_cmd = "find . -type f -not -path '*/.*'"
  local script_content = string.format([[#!/bin/bash
# Show recent files first
%s
# Show all other files
%s | sed 's|^\\./||'
]], 
  table.concat(vim.tbl_map(function(f) return "echo " .. vim.fn.shellescape(f) end, test_recent_files), "\n"),
  original_cmd)
  
  print("Generated script content:")
  print(script_content)
  
  -- Test 4: Actually run the picker with debug (this will show us what fzf receives)
  print("\n4. Running picker with debug...")
  
  -- Add some debug options to see what fzf receives
  local opts = {
    debug = true,
    fzf_opts = {
      ["--print-query"] = true,
      ["--print0"] = true,
    }
  }
  
  print("About to call plugin.files() - this should open the picker...")
  print("After selecting a file, check the output to see what gets passed to the action")
  
  -- This will actually open the picker
  plugin.files(opts)
end

-- Run the test
test_picker_behavior()