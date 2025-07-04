-- Test the temp file approach
print("=== TESTING TEMP FILE APPROACH ===")

local plugin = require("fzf-lua-enchanted-files")

-- Mock the fzf-lua to see what command we're generating
local original_require = require
_G.require = function(name)
  if name == "fzf-lua" then
    return {
      files = function(opts)
        print("=== OPTS PASSED TO fzf-lua.files ===")
        print("opts.cmd:", opts.cmd)
        print("opts.contents:", opts.contents)
        
        if opts.cmd then
          print("Testing command output:")
          local output = vim.fn.systemlist(opts.cmd)
          print("Command returned " .. #output .. " lines:")
          for i = 1, math.min(10, #output) do
            print("  " .. i .. ": " .. output[i])
          end
        end
        
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

-- Restore original require
_G.require = original_require