-- Test the exact logic that should show files at the top
local plugin = require("fzf-lua-enchanted-files")

print("=== FINAL TEST ===")

-- Mock the fzf-lua files function to see what we're passing to it
local original_require = require
_G.require = function(name)
  if name == "fzf-lua" then
    return {
      files = function(opts)
        print("\n=== OPTS PASSED TO fzf-lua.files ===")
        print("opts.contents exists:", opts.contents ~= nil)
        if opts.contents then
          print("Number of files in contents:", #opts.contents)
          print("First 10 files:")
          for i = 1, math.min(10, #opts.contents) do
            print("  " .. i .. ": " .. opts.contents[i])
          end
        end
        print("opts.cmd:", opts.cmd)
        print("===================================")
        return { dummy = "result" }
      end
    }
  else
    return original_require(name)
  end
end

-- Test the files function
print("Calling plugin.files()...")
local result = plugin.files()
print("Result:", vim.inspect(result))

-- Restore original require
_G.require = original_require