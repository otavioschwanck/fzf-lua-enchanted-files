if vim.g.loaded_fzf_lua_enchanted_files then
  return
end
vim.g.loaded_fzf_lua_enchanted_files = 1

vim.api.nvim_create_user_command("FzfLuaFiles", function(opts)
  require("fzf-lua-enchanted-files").files()
end, {
  desc = "Enhanced fzf-lua files with history"
})

vim.api.nvim_create_user_command("FzfLuaFilesDebug", function(opts)
  require("fzf-lua-enchanted-files").debug_history()
end, {
  desc = "Debug fzf-lua enchanted files history"
})

vim.api.nvim_create_user_command("FzfLuaFilesClean", function(opts)
  require("fzf-lua-enchanted-files").clean_history()
end, {
  desc = "Clean duplicate entries from fzf-lua enchanted files history"
})

vim.api.nvim_create_user_command("FzfLuaFilesClear", function(opts)
  require("fzf-lua-enchanted-files").clear_history()
end, {
  desc = "Clear all fzf-lua enchanted files history"
})

vim.api.nvim_create_user_command("FzfLuaFilesTest", function(opts)
  dofile("/home/otavio/Projetos/fzf-lua-enchanted-files/test_picker_nvim.lua")
end, {
  desc = "Run fzf-lua enchanted files test"
})