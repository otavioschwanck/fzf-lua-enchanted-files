# fzf-lua-enchanted-files

A Neovim plugin that enhances `fzf-lua.files()` with intelligent file history tracking. Recently selected files appear at the top of your file picker, making it faster to navigate to frequently used files.

## Features

- **Smart History**: Tracks file selections per working directory (CWD)
- **Visual Indicators**: Recent files are marked with ★ and appear first
- **Persistent Storage**: History survives between Neovim sessions
- **Configurable**: Customize history limits and storage location
- **Zero Configuration**: Works out of the box with sensible defaults

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "otavio/fzf-lua-enchanted-files",
  dependencies = { "ibhagwan/fzf-lua" },
  config = function()
    require("fzf-lua-enchanted-files").setup()
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "otavio/fzf-lua-enchanted-files",
  requires = { "ibhagwan/fzf-lua" },
  config = function()
    require("fzf-lua-enchanted-files").setup()
  end
}
```

## Usage

Replace your `fzf-lua.files()` calls with the enhanced version:

```lua
-- Instead of:
require("fzf-lua").files()

-- Use:
require("fzf-lua-enchanted-files").files()
```

Or use the provided command:

```vim
:FzfLuaFiles
```

## Configuration

```lua
require("fzf-lua-enchanted-files").setup({
  -- Maximum number of files to remember per working directory
  max_history_per_cwd = 50,
  
  -- Custom history file location (optional)
  history_file = vim.fn.stdpath("data") .. "/my-custom-history.json",
})
```

## How It Works

1. **Selection Tracking**: Every time you select a file, it's added to the history for the current working directory
2. **Smart Prioritization**: Recent files appear at the top with a ★ prefix
3. **CWD-Based Storage**: Each directory maintains its own file history
4. **Automatic Cleanup**: History is limited per directory to prevent bloat

## Example

When you run the file picker in a project directory:

```
★ src/components/Header.tsx
★ src/utils/helpers.js
★ package.json
  src/components/Footer.tsx
  src/pages/index.tsx
  README.md
  ...
```

Files with ★ are recently selected and appear first, making navigation faster.

## API

### `files(opts)`

Enhanced version of `fzf-lua.files()` with history tracking.

**Parameters:**
- `opts` (table, optional): Same options as `fzf-lua.files()`

**Example:**
```lua
require("fzf-lua-enchanted-files").files({
  prompt = "Files❯ ",
  cwd = "~/projects/myapp"
})
```

### `setup(config)`

Configure the plugin.

**Parameters:**
- `config` (table, optional): Configuration options

## Requirements

- Neovim 0.8+
- [fzf-lua](https://github.com/ibhagwan/fzf-lua)

## Storage

History is stored in JSON format at:
- Default: `~/.local/share/nvim/fzf-lua-enchanted-files-history.json`
- Custom: Configurable via `history_file` option

The storage structure is:
```json
{
  "/path/to/project1": [
    {"path": "/path/to/project1/file1.js", "timestamp": 1234567890},
    {"path": "/path/to/project1/file2.js", "timestamp": 1234567891}
  ],
  "/path/to/project2": [
    {"path": "/path/to/project2/file1.py", "timestamp": 1234567892}
  ]
}
```

## License

MIT