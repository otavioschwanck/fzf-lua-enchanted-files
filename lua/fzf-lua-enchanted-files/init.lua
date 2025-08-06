local M = {}

local history = {}

local function get_config()
  local defaults = {
    history_dir = vim.fn.stdpath("data") .. "/fzf-lua-enchanted-files",
    max_history_per_cwd = 50,
    auto_history = false,
  }

  return vim.tbl_deep_extend("force", defaults, vim.g.fzf_lua_enchanted_files or {})
end

local function normalize_path_to_filename(path)
  -- Convert absolute path to a safe filename
  -- Replace path separators and special characters with underscores
  local normalized = path
      :gsub("^/", "root_")   -- Handle root prefix
      :gsub("/", "_")        -- Replace slashes with underscores
      :gsub("[^%w_%-]", "_") -- Replace any non-alphanumeric, non-underscore, non-hyphen with underscore
      :gsub("_+", "_")       -- Collapse multiple underscores into one
      :gsub("_$", "")        -- Remove trailing underscore

  return normalized .. ".json"
end

local function get_history_file_path(cwd_key)
  local config = get_config()
  local filename = normalize_path_to_filename(cwd_key)
  return config.history_dir .. "/" .. filename
end

local function get_cwd_key(override_cwd)
  local cwd = override_cwd or vim.fn.getcwd()
  -- Always convert to absolute path for consistency
  return vim.fn.fnamemodify(cwd, ":p"):gsub("/$", "") -- Remove trailing slash
end

local function save_history_for_cwd(cwd_key)
  local config = get_config()

  -- Ensure history directory exists
  if vim.fn.isdirectory(config.history_dir) == 0 then
    vim.fn.mkdir(config.history_dir, "p")
  end

  local file_path = get_history_file_path(cwd_key)
  local file = io.open(file_path, "w")
  if file then
    -- Save only the entries for this specific cwd
    local cwd_entries = history[cwd_key] or {}
    file:write(vim.json.encode(cwd_entries))
    file:close()
  end
end

local function save_history()
  -- Save all cwds to their respective files
  for cwd_key, _ in pairs(history) do
    save_history_for_cwd(cwd_key)
  end
end

local function load_history_for_cwd(cwd_key)
  local file_path = get_history_file_path(cwd_key)
  if vim.fn.filereadable(file_path) == 1 then
    local file = io.open(file_path, "r")
    if file then
      local content = file:read("*a")
      file:close()
      if content and content ~= "" then
        local ok, entries = pcall(vim.json.decode, content)
        if ok and entries then
          history[cwd_key] = entries
          return true
        end
      end
    end
  end
  return false
end


local function load_history(cwd_key)
  -- If specific cwd requested, load only that one
  if cwd_key then
    if not history[cwd_key] then
      load_history_for_cwd(cwd_key)
    end
  end
end

local function add_to_history(file_path, override_cwd)
  local cwd = get_cwd_key(override_cwd)

  -- Load history for this cwd if not already loaded
  load_history(cwd)

  if not history[cwd] then
    history[cwd] = {}
  end

  -- Skip debug entries and entries that start with '[DEBUG]'
  if file_path:match("^%[DEBUG%]") then
    return
  end

  -- Clean the input path of any Unicode characters (icons) and prefixes
  local clean_path = file_path
  -- Remove Unicode characters at the beginning (file icons) - broader range
  clean_path = clean_path:gsub("^[^\32-\126]*", "")  -- Remove any non-printable ASCII at start
  clean_path = clean_path:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace

  -- Convert to relative path for consistent storage
  local rel_path = vim.fn.fnamemodify(clean_path, ":.")


  -- Remove existing entries for the same file
  local new_history = {}
  for _, entry in ipairs(history[cwd]) do
    -- Clean the existing entry path for comparison
    local existing_clean_path = entry.path
    -- Remove Unicode characters at the beginning (file icons) - broader range
    existing_clean_path = existing_clean_path:gsub("^[^\32-\126]*", "")  -- Remove any non-printable ASCII at start
    existing_clean_path = existing_clean_path:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
    -- Convert to relative path for consistent comparison
    existing_clean_path = vim.fn.fnamemodify(existing_clean_path, ":.")

    if existing_clean_path ~= rel_path then
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

  local config = get_config()
  if #history[cwd] > config.max_history_per_cwd then
    table.remove(history[cwd])
  end

  save_history_for_cwd(cwd)
end

local function get_recent_files(override_cwd)
  local cwd = get_cwd_key(override_cwd)

  -- Load history for this cwd if not already loaded
  load_history(cwd)

  if not history[cwd] then
    return {}
  end

  -- Get current buffer's filename relative to the target cwd
  local current_file = nil
  local current_buffer_abs = vim.fn.expand("%:p")
  if current_buffer_abs and current_buffer_abs ~= "" then
    if override_cwd then
      -- Make current buffer path relative to the custom cwd
      local abs_override_cwd = vim.fn.fnamemodify(override_cwd, ":p"):gsub("/$", "")
      if current_buffer_abs:sub(1, #abs_override_cwd + 1) == abs_override_cwd .. "/" then
        current_file = current_buffer_abs:sub(#abs_override_cwd + 2)
      end
    else
      -- Use current buffer relative to current working directory
      current_file = vim.fn.expand("%:.")
    end
  end

  local recent = {}
  for _, entry in ipairs(history[cwd]) do
    -- Clean the stored path of any Unicode characters
    local clean_path = entry.path
    -- Remove all non-printable ASCII at the start
    clean_path = clean_path:gsub("^[^\32-\126]*", "")  -- Remove any non-printable ASCII at start
    clean_path = clean_path:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace

    -- Skip if this is the current buffer file
    if current_file and clean_path == current_file then
      goto continue
    end

    -- Check if the cleaned file exists relative to the target cwd
    local full_path
    if override_cwd then
      -- When using custom cwd, make path relative to that directory
      full_path = cwd .. "/" .. clean_path
    else
      -- When using current directory, path is already relative to current dir
      full_path = clean_path
    end

    if vim.fn.filereadable(full_path) == 1 then
      table.insert(recent, clean_path)
    end

    ::continue::
  end

  return recent
end

function M.files(opts)
  opts = opts or {}

  -- Check dependency
  local has_fzf_lua, fzf_lua = pcall(require, "fzf-lua")
  if not has_fzf_lua then
    vim.notify("fzf-lua is required but not installed", vim.log.levels.ERROR)
    return
  end


  -- Use the cwd option if provided
  local target_cwd = opts.cwd
  local recent_files = get_recent_files(target_cwd)

  -- If we have recent files, create a combined list without duplicates
  if #recent_files > 0 then
    -- Get the command that fzf-lua would actually use
    local original_cmd = opts.cmd or fzf_lua.defaults.files.cmd

    -- If still no command, detect the best file finder (like fzf-lua does)
    if not original_cmd then
      -- Try to detect the same way fzf-lua would
      if vim.fn.executable("fd") == 1 then
        original_cmd = "fd --type f --color=never --strip-cwd-prefix"
      elseif vim.fn.executable("rg") == 1 then
        original_cmd = "rg --files --color=never"
      else
        original_cmd =
        "find . -type f -not -path '*/\\.git/*' -printf '%P\\n' 2>/dev/null || find . -type f -not -path '*/\\.git/*'"
      end
    end

    -- Create a temporary exclude file for the recent files
    local exclude_file = vim.fn.tempname()
    local exclude_handle = io.open(exclude_file, "w")
    if exclude_handle then
      for _, recent_file in ipairs(recent_files) do
        exclude_handle:write(recent_file .. "\n")
      end
      exclude_handle:close()
    end

    -- Create a script that shows recent files first, then all others EXCEPT the recent ones
    local temp_script = vim.fn.tempname() .. ".sh"
    local script_content = string.format([[#!/usr/bin/env bash
# Show recent files first
%s
# Show all other files, excluding the recent ones
%s | sed 's|^\./||' | grep -v -F -f %s
]],
      table.concat(vim.tbl_map(function(f) return "echo " .. vim.fn.shellescape(f) end, recent_files), "\n"),
      original_cmd,
      vim.fn.shellescape(exclude_file))

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
        vim.fn.delete(exclude_file)
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
          add_to_history(selected[1], target_cwd)
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

  -- Load all existing history files
  local config = get_config()
  if vim.fn.isdirectory(config.history_dir) == 1 then
    local files = vim.fn.glob(config.history_dir .. "/*.json", 0, 1)
    for _, file_path in ipairs(files) do
      local filename = vim.fn.fnamemodify(file_path, ":t:r") -- Get filename without .json
      -- Reconstruct the original cwd path from the filename
      local cwd_key = filename:gsub("^root_", "/"):gsub("_", "/")
      load_history_for_cwd(cwd_key)
    end
  end

  print("=== CLEANING HISTORY ===")
  local total_removed = 0

  for cwd, entries in pairs(history) do
    if cwd ~= "_migrated" then
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
      save_history_for_cwd(cwd)
    end
  end

  print("=== CLEANING COMPLETE ===")
  print("Total duplicates removed: " .. total_removed)
end

function M.clear_history()
  local config = get_config()

  -- Remove all history files
  if vim.fn.isdirectory(config.history_dir) == 1 then
    local files = vim.fn.glob(config.history_dir .. "/*.json", 0, 1)
    for _, file_path in ipairs(files) do
      vim.fn.delete(file_path)
    end
  end

  history = {}
  print("History cleared!")
end

function M.debug_history()
  local cwd = get_cwd_key()

  -- Load history for current CWD
  load_history(cwd)

  print("=== FZF-LUA ENCHANTED FILES DEBUG ===")
  print("Current CWD: " .. cwd)
  local config = get_config()
  print("History directory: " .. config.history_dir)
  print("History directory exists: " .. (vim.fn.isdirectory(config.history_dir) == 1 and "yes" or "no"))

  local current_file = get_history_file_path(cwd)
  print("Current CWD history file: " .. current_file)
  print("Current CWD history file exists: " .. (vim.fn.filereadable(current_file) == 1 and "yes" or "no"))

  if vim.fn.filereadable(current_file) == 1 then
    local file = io.open(current_file, "r")
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

  -- Show all history files
  print("\nAll history files:")
  if vim.fn.isdirectory(config.history_dir) == 1 then
    local files = vim.fn.glob(config.history_dir .. "/*.json", 0, 1)
    for _, file_path in ipairs(files) do
      print("  " .. file_path)
    end
  end
end

function M.setup(user_config)
  if user_config then
    vim.g.fzf_lua_enchanted_files = vim.tbl_deep_extend(
      "force",
      vim.g.fzf_lua_enchanted_files or {},
      user_config
    )
  end

  local config = get_config()
  -- Create history directory instead of single file directory
  if vim.fn.isdirectory(config.history_dir) == 0 then
    vim.fn.mkdir(config.history_dir, "p")
  end

  -- Setup auto-history if enabled
  if config.auto_history then
    vim.api.nvim_create_autocmd("BufReadPost", {
      callback = function()
        local file_path = vim.fn.expand("%:p")
        local current_cwd = vim.fn.getcwd()

        -- Check if file exists and is within current working directory
        if vim.fn.filereadable(file_path) == 1 then
          local file_dir = vim.fn.fnamemodify(file_path, ":h")
          if file_dir:find("^" .. vim.pesc(current_cwd)) then
            local relative_path = vim.fn.fnamemodify(file_path, ":.")
            add_to_history(relative_path)
          end
        end
      end,
      desc = "Auto-add files to fzf-lua-enchanted-files history"
    })
  end
end

function M.get_config()
  return get_config()
end

return M
