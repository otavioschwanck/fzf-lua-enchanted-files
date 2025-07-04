# fzf-lua-enchanted-files

A high-performance Neovim plugin that enhances `fzf-lua.files()` with intelligent file history tracking and smart prioritization. Recently selected files appear at the top of your file picker with zero duplicates, making navigation lightning-fast even in massive codebases.

## ✨ Features

- **🎯 Smart History**: Tracks file selections per working directory (CWD)
- **🚀 Maximum Performance**: Shell-level filtering scales perfectly with project size
- **📁 Per-Directory History**: Each directory maintains independent file history
- **🔧 Custom Directory Support**: Works with any directory via `cwd` option
- **💾 Persistent Storage**: History survives between Neovim sessions
- **⚙️ Zero Configuration**: Works out of the box with sensible defaults

## 🚀 Performance

This plugin is designed for **maximum performance**:
- **Shell-level duplicate removal** using `grep -v -F -f` 
- **No Lua iteration** through large file lists
- **Scales perfectly** with project size (tested on 50k+ file projects)
- **Instant response** even on massive codebases

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "otavioschwanck/fzf-lua-enchanted-files",
  dependencies = { "ibhagwan/fzf-lua" },
  config = function()
    require("fzf-lua-enchanted-files").setup()
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "otavioschwanck/fzf-lua-enchanted-files",
  requires = { "ibhagwan/fzf-lua" },
  config = function()
    require("fzf-lua-enchanted-files").setup()
  end
}
```

## 🎮 Usage

### Basic Usage

Replace your `fzf-lua.files()` calls with the enhanced version:

```lua
-- Instead of:
require("fzf-lua").files()

-- Use:
require("fzf-lua-enchanted-files").files()
```

Or use the provided commands:

```vim
:FzfLuaFiles          " Enhanced file picker
:FzfLuaFilesDebug     " Debug history state
:FzfLuaFilesClear     " Clear all history
```

### Custom Directory Support

Work with any directory by passing the `cwd` option:

```lua
-- Search files in app/controllers with its own history
require("fzf-lua-enchanted-files").files({cwd = "app/controllers"})

-- Search files in lib directory
require("fzf-lua-enchanted-files").files({cwd = "lib"})

-- Combine with other fzf-lua options
require("fzf-lua-enchanted-files").files({
  cwd = "spec",
  prompt = "Test Files❯ "
})
```

## ⚙️ Configuration

```lua
require("fzf-lua-enchanted-files").setup({
  -- Maximum number of files to remember per working directory
  max_history_per_cwd = 50,
  
  -- Custom history file location (optional)
  history_file = vim.fn.stdpath("data") .. "/my-custom-history.json",
})
```

## 🧠 How It Works

1. **Selection Tracking**: Every file selection is tracked per directory
2. **Smart Prioritization**: Recent files appear at the top of the list
3. **Duplicate Prevention**: Shell-level filtering ensures no duplicates
4. **CWD-Based Storage**: Each directory maintains independent history
5. **Performance Optimization**: Heavy lifting done by optimized shell commands

## 📋 Example Output

When you run the file picker in a project directory:

```
app/models/user.rb               ← Recent files
app/controllers/users_controller.rb
spec/models/user_spec.rb
app/views/users/index.html.erb   ← All other files (excluding recent ones)
app/assets/javascripts/users.js
config/routes.rb
README.md
...
```

Recent files appear once at the top, followed by all other files with recent ones automatically excluded.

## 📚 API Reference

### `files(opts)`

Enhanced version of `fzf-lua.files()` with history tracking and smart prioritization.

**Parameters:**
- `opts` (table, optional): Same options as `fzf-lua.files()` plus:
  - `cwd` (string, optional): Target directory for file search and history

**Examples:**
```lua
-- Basic usage
require("fzf-lua-enchanted-files").files()

-- With custom directory
require("fzf-lua-enchanted-files").files({cwd = "app/models"})

-- With fzf-lua options
require("fzf-lua-enchanted-files").files({
  prompt = "Files❯ ",
  cwd = "~/projects/myapp"
})
```

### `setup(config)`

Configure the plugin with custom options.

**Parameters:**
- `config` (table, optional): Configuration options

### Utility Functions

```lua
-- Debug current history state
require("fzf-lua-enchanted-files").debug_history()

-- Clean duplicate entries from history
require("fzf-lua-enchanted-files").clean_history()

-- Clear all history
require("fzf-lua-enchanted-files").clear_history()
```

## 🔧 Commands

| Command | Description |
|---------|-------------|
| `:FzfLuaFiles` | Open enhanced file picker |
| `:FzfLuaFilesDebug` | Debug history state and file paths |
| `:FzfLuaFilesClean` | Clean duplicate entries from history |
| `:FzfLuaFilesClear` | Clear all history data |

## 📋 Requirements

- Neovim 0.9+
- [fzf-lua](https://github.com/ibhagwan/fzf-lua)
- Standard shell tools: `find`, `grep`, `sed`

## 💾 Storage

History is stored in JSON format at:
- **Default**: `~/.local/share/nvim/fzf-lua-enchanted-files-history.json`
- **Custom**: Configurable via `history_file` option

The storage structure organizes history by absolute directory paths:

```json
{
  "/home/user/project1": [
    {"path": "src/components/Header.tsx", "timestamp": 1234567890},
    {"path": "src/utils/helpers.js", "timestamp": 1234567891}
  ],
  "/home/user/project1/app/controllers": [
    {"path": "users_controller.rb", "timestamp": 1234567892},
    {"path": "posts_controller.rb", "timestamp": 1234567893}
  ]
}
```

## 🔄 Migration

The plugin automatically migrates old history formats:
- Converts relative directory paths to absolute paths
- Merges duplicate directory entries
- Maintains file timestamps and order
- Migration happens transparently on first load

## 🎯 Performance Tips

- **Large Projects**: The plugin uses shell-level filtering for maximum performance
- **Memory Usage**: History is limited per directory (default: 50 files)
- **Storage**: JSON format provides fast loading and minimal disk usage
- **Cleanup**: Use `:FzfLuaFilesClean` periodically to remove stale entries

## 🐛 Troubleshooting

### Debug History State
```vim
:FzfLuaFilesDebug
```

### Clean Corrupted History
```vim
:FzfLuaFilesClear
```

### Check File Paths
The debug command shows detailed information about stored paths and their readability.

## 📄 License

MIT

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
