-- Test the cleaning function
local function test_clean(input)
  local clean_path = input
  clean_path = clean_path:gsub("★ ", "") -- Remove ★ anywhere
  clean_path = clean_path:gsub("[^\32-\126]", "") -- Remove any non-ASCII characters anywhere
  clean_path = clean_path:gsub(string.char(238, 152, 160), "") -- <ee><98><a0>
  clean_path = clean_path:gsub(string.char(239, 131, 182), "") -- <ef><83><b6>
  clean_path = clean_path:gsub(string.char(226, 128, 130), "") -- <e2><80><82>
  clean_path = clean_path:match("^%s*(.-)%s*$")
  return clean_path
end

local tests = {
  "/home/otavio/Projetos/fzf-lua-enchanted-files/󰂺README.md",
  "/home/otavio/Projetos/fzf-lua-enchanted-files/★ README.md",
  "/home/otavio/Projetos/fzf-lua-enchanted-files/README.md"
}

print("Testing path cleaning:")
for i, test in ipairs(tests) do
  local cleaned = test_clean(test)
  print("Input:  '" .. test .. "'")
  print("Output: '" .. cleaned .. "'")
  print("Abs:    '" .. vim.fn.fnamemodify(cleaned, ":p") .. "'")
  print("")
end