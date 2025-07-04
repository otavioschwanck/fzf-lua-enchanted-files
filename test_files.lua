-- Test the files function output
local plugin = require("fzf-lua-enchanted-files")

print("Testing files function output...")

-- Manually test the file listing logic
local history = {}
local config = {
  history_file = vim.fn.stdpath("data") .. "/fzf-lua-enchanted-files-history.json",
}

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

local function get_recent_files()
  local cwd = vim.fn.getcwd()
  if not history[cwd] then
    return {}
  end
  
  local recent = {}
  for _, entry in ipairs(history[cwd]) do
    -- Remove specific Unicode whitespace sequences we found
    local clean_path = entry.path
    clean_path = clean_path:gsub(string.char(238, 152, 160), "") -- <ee><98><a0>
    clean_path = clean_path:gsub(string.char(239, 131, 182), "") -- <ef><83><b6>
    clean_path = clean_path:gsub(string.char(226, 128, 130), "") -- <e2><80><82>
    clean_path = clean_path:match("^%s*(.-)%s*$")
    if vim.fn.filereadable(clean_path) == 1 then
      table.insert(recent, clean_path)
    end
  end
  
  return recent
end

load_history()
local recent_files = get_recent_files()

print("Recent files found: " .. #recent_files)
for i, file in ipairs(recent_files) do
  local rel_path = vim.fn.fnamemodify(file, ":.")
  print("  " .. i .. ": ★ " .. rel_path)
end

-- Test the file command
local cmd = "find . -type f -not -path '*/.*'"
print("\nRunning command: " .. cmd)
local cmd_output = vim.fn.systemlist(cmd)
print("Command returned " .. #cmd_output .. " files")

-- Show first few files
for i = 1, math.min(5, #cmd_output) do
  print("  " .. i .. ": " .. cmd_output[i])
end