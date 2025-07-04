#!/usr/bin/env lua

-- Test script to validate the fzf-lua-enchanted-files plugin
-- This will help us debug the picker behavior

local function test_plugin()
  print("=== FZF-LUA ENCHANTED FILES TEST ===")
  
  -- Load the plugin
  local plugin = require("fzf-lua-enchanted-files")
  
  -- Test 1: Check if we can load history
  print("\n1. Testing history loading...")
  plugin.debug_history()
  
  -- Test 2: Simulate adding files to history
  print("\n2. Testing add_to_history function...")
  local test_files = {
    "app/models/charge.rb",
    "docker/entrypoint.sh",
    "lib/settings.rb"
  }
  
  for _, file in ipairs(test_files) do
    print("Adding: " .. file)
    -- We can't directly call add_to_history as it's local, but we can simulate file selection
  end
  
  -- Test 3: Test get_recent_files (we need to make this public for testing)
  print("\n3. Testing file listing...")
  
  -- Test 4: Check what the script generates
  print("\n4. Testing script generation...")
  local recent_files = {"app/models/charge.rb", "docker/entrypoint.sh"}
  
  if #recent_files > 0 then
    local original_cmd = "find . -type f -not -path '*/.*'"
    local script_content = string.format([[#!/bin/bash
# Show recent files first
%s
# Show all other files
%s | sed 's|^\./||'
]], 
    table.concat(vim.tbl_map(function(f) return "echo " .. vim.fn.shellescape(f) end, recent_files), "\n"),
    original_cmd)
    
    print("Generated script:")
    print(script_content)
    
    -- Test the script
    local temp_script = "/tmp/test_fzf_script.sh"
    local temp_file = io.open(temp_script, "w")
    if temp_file then
      temp_file:write(script_content)
      temp_file:close()
      os.execute("chmod +x " .. temp_script)
      
      print("\nScript output:")
      os.execute(temp_script .. " | head -10")
      
      os.remove(temp_script)
    end
  end
  
  print("\n=== TEST COMPLETE ===")
end

-- Run the test
test_plugin()