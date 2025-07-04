-- Test how fzf-lua actually processes the contents option
print("=== TESTING FZF-LUA CONTENTS PROCESSING ===")

-- Let's see what happens when we directly call fzf-lua with contents
local fzf_lua = require("fzf-lua")

-- Test with a minimal example
print("Testing minimal contents option...")

local test_opts = {
  prompt = "Test> ",
  contents = {
    "★ recent-file-1.txt",
    "★ recent-file-2.txt", 
    "normal-file-1.txt",
    "normal-file-2.txt"
  },
  fzf_opts = {
    ["--no-multi"] = true
  },
  actions = {
    default = function(selected)
      print("Selected:", selected[1])
    end
  }
}

print("Contents we're providing:")
for i, item in ipairs(test_opts.contents) do
  print("  " .. i .. ": " .. item)
end

-- Let's also check if there's an equivalent function for direct contents
print("\nLooking at fzf-lua.fzf function...")
print("fzf function:", type(fzf_lua.fzf))

if fzf_lua.fzf then
  print("Using fzf_lua.fzf instead of files...")
  fzf_lua.fzf(test_opts)
else
  print("fzf function not available, using files...")
  fzf_lua.files(test_opts)
end