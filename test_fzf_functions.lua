-- Check what functions are available in fzf-lua
local fzf_lua = require("fzf-lua")

print("Available fzf-lua functions:")
for k, v in pairs(fzf_lua) do
  if type(v) == "function" then
    print("  " .. k .. " (function)")
  end
end

print("\nLooking for core fzf function...")
print("fzf:", type(fzf_lua.fzf))
print("core:", type(fzf_lua.core))

if fzf_lua.core then
  print("core functions:")
  for k, v in pairs(fzf_lua.core) do
    if type(v) == "function" then
      print("  core." .. k .. " (function)")
    end
  end
end