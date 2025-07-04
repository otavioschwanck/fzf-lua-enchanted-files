-- Test with the actual fzf-lua to see what options it respects
print("=== TESTING WITH REAL FZF-LUA ===")

-- Test what fzf-lua actually supports
local fzf_lua = require("fzf-lua")

print("fzf_lua.config:", vim.inspect(fzf_lua.config))

-- Test with a simple contents option
print("\nTesting with simple contents...")
local test_opts = {
  contents = {
    "★ test-recent-file.txt",
    "normal-file.txt",
    "another-file.txt"
  }
}

print("Options we're passing:", vim.inspect(test_opts))

-- Let's also check what provider files actually expects
print("\nChecking files provider...")
local files_provider = require("fzf-lua.providers.files")
print("files provider functions:", vim.inspect(vim.tbl_keys(files_provider)))