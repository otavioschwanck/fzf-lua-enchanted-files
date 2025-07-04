-- Debug what actions fzf-lua files actually uses
local fzf_lua = require("fzf-lua")

print("=== FZF-LUA FILES ACTIONS DEBUG ===")
print("fzf_lua.defaults.files.actions:")
if fzf_lua.defaults and fzf_lua.defaults.files and fzf_lua.defaults.files.actions then
  for key, value in pairs(fzf_lua.defaults.files.actions) do
    print("  " .. key .. ": " .. type(value))
  end
else
  print("  No default actions found")
end

print("\nChecking available action functions:")
local actions = require("fzf-lua.actions")
print("fzf-lua.actions.file_edit:", type(actions.file_edit))
print("fzf-lua.actions.file_edit_or_qf:", type(actions.file_edit_or_qf))