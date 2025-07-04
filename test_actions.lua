-- Test the action handlers
local plugin = require("fzf-lua-enchanted-files")

print("=== TESTING ACTION HANDLERS ===")

-- Mock the fzf-lua files and actions
local original_require = require
_G.require = function(name)
  if name == "fzf-lua" then
    return {
      files = function(opts)
        print("fzf-lua.files called with contents:", opts.contents and #opts.contents or "none")
        
        -- Simulate selecting the first file (which should be a ★ file)
        if opts.actions and opts.actions.default then
          print("Simulating selection of first file...")
          local selected = opts.contents and { opts.contents[1] } or { "test-file.txt" }
          print("Selected:", selected[1])
          opts.actions.default(selected, {})
        end
        
        return { dummy = "result" }
      end
    }
  elseif name == "fzf-lua.actions" then
    return {
      file_edit = function(selected, o)
        print("file_edit called with:", selected[1])
      end
    }
  else
    return original_require(name)
  end
end

-- Test the files function
print("Calling plugin.files()...")
local result = plugin.files()

-- Test debug after the action
print("\nTesting debug after action...")
plugin.debug_history()

-- Restore original require
_G.require = original_require