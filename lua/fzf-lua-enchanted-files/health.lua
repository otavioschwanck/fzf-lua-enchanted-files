local M = {}

function M.check()
  vim.health.start("fzf-lua-enchanted-files")
  
  local config = require("fzf-lua-enchanted-files").get_config()
  
  -- Check fzf-lua dependency
  local has_fzf_lua, fzf_lua = pcall(require, "fzf-lua")
  if has_fzf_lua then
    vim.health.ok("fzf-lua is installed")
  else
    vim.health.error("fzf-lua is not installed", {
      "Install fzf-lua: https://github.com/ibhagwan/fzf-lua"
    })
  end
  
  -- Check history file location
  local history_file = config.history_file
  local history_dir = vim.fn.fnamemodify(history_file, ":h")
  
  if vim.fn.isdirectory(history_dir) == 1 then
    vim.health.ok("History directory exists: " .. history_dir)
  else
    vim.health.warn("History directory does not exist: " .. history_dir, {
      "Directory will be created automatically on first use"
    })
  end
  
  -- Check history file permissions
  if vim.fn.filereadable(history_file) == 1 then
    vim.health.ok("History file is readable: " .. history_file)
    
    if vim.fn.filewritable(history_file) == 1 then
      vim.health.ok("History file is writable")
    else
      vim.health.error("History file is not writable", {
        "Check file permissions: " .. history_file
      })
    end
  else
    vim.health.info("History file does not exist yet: " .. history_file)
  end
  
  -- Check configuration values
  local max_history = config.max_history_per_cwd
  if type(max_history) == "number" and max_history > 0 then
    vim.health.ok("max_history_per_cwd is valid: " .. max_history)
  else
    vim.health.error("max_history_per_cwd must be a positive number", {
      "Current value: " .. vim.inspect(max_history)
    })
  end
  
  -- Check shell dependencies
  local shell_deps = {"find", "grep", "sed"}
  for _, cmd in ipairs(shell_deps) do
    if vim.fn.executable(cmd) == 1 then
      vim.health.ok(cmd .. " is available")
    else
      vim.health.error(cmd .. " is not available", {
        "Install " .. cmd .. " for optimal performance"
      })
    end
  end
  
  -- Check optional file finders
  local optional_finders = {
    {cmd = "fd", desc = "Fast alternative to find"},
    {cmd = "rg", desc = "Fast grep alternative (ripgrep)"}
  }
  
  for _, finder in ipairs(optional_finders) do
    if vim.fn.executable(finder.cmd) == 1 then
      vim.health.ok(finder.cmd .. " is available (" .. finder.desc .. ")")
    else
      vim.health.info(finder.cmd .. " is not available", {
        "Optional: " .. finder.desc
      })
    end
  end
  
  -- Check current configuration
  vim.health.info("Current configuration:")
  vim.health.info("  history_file: " .. config.history_file)
  vim.health.info("  max_history_per_cwd: " .. config.max_history_per_cwd)
  
  -- Check if using vim.g configuration
  if vim.g.fzf_lua_enchanted_files then
    vim.health.ok("Using vim.g.fzf_lua_enchanted_files for configuration")
  else
    vim.health.info("Using default configuration (no vim.g.fzf_lua_enchanted_files set)")
  end
end

return M