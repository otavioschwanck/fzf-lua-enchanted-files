local M = {}

local history = {}
local config = {
  history_file = vim.fn.stdpath("data") .. "/fzf-lua-enchanted-files-history.json",
  max_history_per_cwd = 50,
}

local function get_cwd_key()
  return vim.fn.getcwd()
end

local function load_history()
  local file = io.open(config.history_file, "r")
  if file then
    local content = file:read("*a")
    file:close()
    if content and content ~= "" then
      local ok, data = pcall(vim.json.decode, content)
      if ok and data then
        history = data
      end
    end
  end
end

local function save_history()
  local file = io.open(config.history_file, "w")
  if file then
    file:write(vim.json.encode(history))
    file:close()
  end
end

local function add_to_history(file_path)
  local cwd = get_cwd_key()
  if not history[cwd] then
    history[cwd] = {}
  end
  
  -- Skip debug entries and entries that start with '[DEBUG]'
  if file_path:match("^%[DEBUG%]") then
    return
  end
  
  -- Clean the input path of any Unicode characters (icons) and prefixes
  local clean_path = file_path
  -- Remove Unicode characters at the beginning (file icons)
  clean_path = clean_path:gsub("^[\238-\239][\128-\191]*", "") -- Remove UTF-8 sequences
  clean_path = clean_path:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
  
  -- Convert to relative path for consistent storage
  local rel_path = vim.fn.fnamemodify(clean_path, ":.")
  
  
  -- Remove existing entries for the same file
  local new_history = {}
  for _, entry in ipairs(history[cwd]) do
    if entry.path ~= rel_path then
      table.insert(new_history, entry)
    end
  end
  
  -- Set the cleaned history
  history[cwd] = new_history
  
  -- Add the new entry at the top
  table.insert(history[cwd], 1, {
    path = rel_path,
    timestamp = os.time()
  })
  
  if #history[cwd] > config.max_history_per_cwd then
    table.remove(history[cwd])
  end
  
  save_history()
end

local function get_recent_files()
  local cwd = get_cwd_key()
  if not history[cwd] then
    return {}
  end
  
  local recent = {}
  for _, entry in ipairs(history[cwd]) do
    -- Clean the stored path of any Unicode characters
    local clean_path = entry.path
    print("Original path: '" .. clean_path .. "' (length: " .. #clean_path .. ")")
    
    -- Debug: show character analysis
    for i = 1, math.min(10, #clean_path) do
      local char = clean_path:sub(i, i)
      local byte = string.byte(char)
      print("  char " .. i .. ": '" .. char .. "' (byte: " .. byte .. ")")
    end
    
    -- More aggressive cleaning - remove all non-printable ASCII at the start
    clean_path = clean_path:gsub("^[^\32-\126]*", "") -- Remove any non-printable ASCII at start
    print("After non-printable removal: '" .. clean_path .. "'")
    clean_path = clean_path:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
    print("After trim: '" .. clean_path .. "'")
    
    -- Check if the cleaned file exists
    local readable = vim.fn.filereadable(clean_path)
    print("File readable: " .. readable)
    if readable == 1 then
      print("Adding to recent: '" .. clean_path .. "'")
      table.insert(recent, clean_path)
    else
      print("File not readable, skipping")
    end
  end
  
  print("Total recent files: " .. #recent)
  return recent
end

function M.files(opts)
  opts = opts or {}
  
  load_history()
  
  local recent_files = get_recent_files()
  local fzf_lua = require("fzf-lua")
  
  
  -- If we have recent files, create a simple combined list
  if #recent_files > 0 then
    
    -- Get the original command
    local original_cmd = opts.cmd or fzf_lua.defaults.files.cmd or "find . -type f -not -path '*/.*'"
    
    -- Create a simple script that shows recent files first, then all others
    local temp_script = vim.fn.tempname() .. ".sh"
    local script_content = string.format([[#!/bin/bash
# Show recent files first
%s
# Show all other files
%s | sed 's|^\./||'
]], 
    table.concat(vim.tbl_map(function(f) return "echo " .. vim.fn.shellescape(f) end, recent_files), "\n"),
    original_cmd)
    
    local temp_file = io.open(temp_script, "w")
    if temp_file then
      temp_file:write(script_content)
      temp_file:close()
      vim.fn.system("chmod +x " .. temp_script)
      
      -- Use the script
      opts.cmd = temp_script
      
      -- Clean up after a delay
      vim.defer_fn(function()
        vim.fn.delete(temp_script)
      end, 5000)
    end
  end
  
  -- Wrap actions to track history
  if not opts.actions then
    opts.actions = {}
  end
  
  -- Simple action wrapper - no prefix handling
  local function wrap_file_action(action)
    return function(selected, o)
      if selected and #selected > 0 then
        -- Just use the selected files as-is
        if selected[1] then
          add_to_history(selected[1])
        end
        
        if action then
          return action(selected, o)
        else
          -- Default behavior: edit the file
          require("fzf-lua.actions").file_edit(selected, o)
        end
      end
    end
  end
  
  -- Always wrap the default action
  local original_default = opts.actions.default
  opts.actions.default = wrap_file_action(original_default)
  
  -- Also ensure we wrap enter if it's set
  if opts.actions.enter then
    opts.actions.enter = wrap_file_action(opts.actions.enter)
  end
  
  return fzf_lua.files(opts)
end

function M.clean_history()
  load_history()
  
  print("=== CLEANING HISTORY ===")
  local total_removed = 0
  
  for cwd, entries in pairs(history) do
    print("Processing CWD: " .. cwd)
    local cleaned_entries = {}
    local seen_files = {}
    
    -- Process entries in reverse order (newest first) to keep the most recent timestamp
    for i = #entries, 1, -1 do
      local entry = entries[i]
      
      -- Clean the path
      local clean_path = entry.path
      local abs_path = vim.fn.fnamemodify(clean_path, ":p")
      
      -- Only keep if we haven't seen this file yet (keeping newest)
      if not seen_files[abs_path] then
        seen_files[abs_path] = true
        table.insert(cleaned_entries, 1, {
          path = abs_path,
          timestamp = entry.timestamp
        })
        print("  Kept: " .. abs_path)
      else
        total_removed = total_removed + 1
        print("  Removed duplicate: " .. entry.path)
      end
    end
    
    history[cwd] = cleaned_entries
  end
  
  save_history()
  print("=== CLEANING COMPLETE ===")
  print("Total duplicates removed: " .. total_removed)
end

function M.clear_history()
  history = {}
  save_history()
  print("History cleared!")
end

function M.debug_history()
  load_history()
  local cwd = get_cwd_key()
  
  print("=== FZF-LUA ENCHANTED FILES DEBUG ===")
  print("Current CWD: " .. cwd)
  print("History file: " .. config.history_file)
  print("History file exists: " .. (vim.fn.filereadable(config.history_file) == 1 and "yes" or "no"))
  
  if vim.fn.filereadable(config.history_file) == 1 then
    local file = io.open(config.history_file, "r")
    if file then
      local content = file:read("*a")
      file:close()
      print("Raw history content: " .. content)
    end
  end
  
  print("Loaded history for current CWD:")
  if history[cwd] then
    for i, entry in ipairs(history[cwd]) do
      print("  " .. i .. ": " .. entry.path .. " (timestamp: " .. entry.timestamp .. ")")
    end
  else
    print("  No history found for current CWD")
  end
  
  local recent = get_recent_files()
  print("Recent files count: " .. #recent)
  for i, file in ipairs(recent) do
    print("  " .. i .. ": " .. file)
  end
  
  print("\nDetailed file check:")
  if history[cwd] then
    for i, entry in ipairs(history[cwd]) do
      local clean_path = entry.path:gsub("%s+", "")
      local readable = vim.fn.filereadable(clean_path)
      print("  Entry " .. i .. ":")
      print("    Original: '" .. entry.path .. "' (length: " .. #entry.path .. ")")
      print("    Cleaned:  '" .. clean_path .. "' (length: " .. #clean_path .. ")")
      print("    Readable: " .. readable)
      
      -- Debug the actual characters
      print("    Character analysis:")
      for i = 1, #entry.path do
        local char = entry.path:sub(i, i)
        local byte = string.byte(char)
        print("      " .. i .. ": '" .. char .. "' (byte: " .. byte .. ")")
        if i > 80 then -- limit output
          print("      ... (truncated)")
          break
        end
      end
      
      -- Try manual space removal
      local manual_clean = entry.path:gsub(" ", "")
      print("    Manual clean: '" .. manual_clean .. "'")
      print("    Manual readable: " .. vim.fn.filereadable(manual_clean))
    end
  end
end

function M.setup(user_config)
  config = vim.tbl_extend("force", config, user_config or {})
  
  local data_dir = vim.fn.fnamemodify(config.history_file, ":h")
  if vim.fn.isdirectory(data_dir) == 0 then
    vim.fn.mkdir(data_dir, "p")
  end
end

return M