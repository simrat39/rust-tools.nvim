# rust-tools.nvim
A plugin to improve your rust experience in neovim.

## Quick Links
- [Wiki](https://github.com/simrat39/rust-tools.nvim/wiki)
  - [CodeLLDB Debugging](https://github.com/simrat39/rust-tools.nvim/wiki/Debugging)
  - [Standalone File](https://github.com/simrat39/rust-tools.nvim/wiki/Standalone-File-Support)
- [Installation](#installation)
- [Setup](#setup)
- [Usage](#usage)

## Prerequisites

- `neovim 0.10`
- `rust-analyzer`
- `dot` from `graphviz` (only for crate graph)

## Installation

using `packer.nvim`

```lua
use 'simrat39/rust-tools.nvim'

-- Debugging
use 'nvim-lua/plenary.nvim'
use 'mfussenegger/nvim-dap'
```
<b>Look at the configuration information below to get started.</b>

## Setup
This plugin automatically sets up nvim-lspconfig rust-analyzer for you, so don't do that manually, as it causes conflicts.

Put this in your init.lua or any lua file that is sourced.<br>

For most people, the defaults are fine, but for advanced configuration, see [Configuration](#configuration).

Example config:

```lua
vim.g.ferris = {
  server = {
    on_attach = function(_, bufnr)
      -- Code action groups
      vim.keymap.set("n", "<Leader>a", vim.cmd.RustCodeAction, { buffer = bufnr })
    end,
  },
}
```

## Usage

<details>
  <summary>
	<b>Debugging</b>
  </summary>
  
  ![debugging](https://github.com/simrat39/rust-tools-demos/raw/master/rust-tools-debug.gif)
</details>

<details>
  <summary>
	<b>Runnables</b>
  </summary>
  
  ![runnables](https://github.com/simrat39/rust-tools-demos/raw/master/runnables.gif)
  ```lua
  -- Command:
  -- RustRunnables
  require('rust-tools').runnables.runnables()
```
</details>

<details>
  <summary>
	<b>Expand Macros Recursively</b>
  </summary>
  
  ![expand macros](https://github.com/simrat39/rust-tools-demos/raw/master/expand_macros_recursively.gif)
  ```lua
  -- Command:
  -- RustExpandMacro  
  require'rust-tools'.expand_macro.expand_macro()
  ```
</details>

<details>
  <summary>
	<b>Move Item Up/Down</b>
  </summary>
  
  ![move items](https://github.com/simrat39/rust-tools-demos/raw/master/move_item.gif)
  ```lua
  -- Command:
  -- RustMoveItemUp    
  -- RustMoveItemDown    
  local up = true -- true = move up, false = move down
  require'rust-tools'.move_item.move_item(up)
```
</details>

<details>
  <summary>
	<b>Hover Actions</b>
  </summary>
  
 ![hover actions](https://github.com/simrat39/rust-tools-demos/raw/master/hover_actions.gif)
 Note: To activate hover actions, run the command twice. This will move you into the window, then press enter on the selection you want. Alternatively, you can set ```auto_focus``` to true in your config and you will automatically enter the hover actions window.
 ```lua
 -- Command:
 -- RustHoverActions 
 require'rust-tools'.hover_actions.hover_actions()
 ```
</details>

<details>
  <summary>
	<b>Hover Range</b>
  </summary>
  
  Note: Requires rust-analyzer version after 2021-08-02. Shows the type in visual mode when hovering.
  ```lua
  -- Command:
  -- RustHoverRange 
  require'rust-tools'.hover_range.hover_range()
  ```
</details>

<details>
  <summary>
	<b>Open Cargo.toml</b>
  </summary>
  
  ![open cargo](https://github.com/simrat39/rust-tools-demos/raw/master/open_cargo_toml.gif)
  ```lua
  -- Command:
  -- RustOpenCargo
  require'rust-tools'.open_cargo_toml.open_cargo_toml()
  ```
</details>

<details>
  <summary>
	<b>Parent Module</b>
  </summary>
  
  ![parent module](https://github.com/simrat39/rust-tools-demos/raw/master/parent_module.gif)
  ```lua
  -- Command:
  -- RustParentModule 
  require'rust-tools'.parent_module.parent_module()
  ```
</details>

<details>
  <summary>
	<b>Join Lines</b>
  </summary>
  
  ![join lines](https://github.com/simrat39/rust-tools-demos/raw/master/join_lines.gif)
  ```lua
  -- Command:
  -- RustJoinLines  
  require'rust-tools'.join_lines.join_lines()
  ```
</details>

<details>
  <summary>
	<b>Structural Search Replace</b>
  </summary>
  
  ```lua
  -- Command:
  -- RustSSR [query]
  require'rust-tools'.ssr.ssr(query)
  ```
</details>

<details>
  <summary>
	<b>View Crate Graph</b>
  </summary>
  
  ```vimscript
  :RustViewCrateGraph [backend [output]]
  ```
</details>

<details>
  <summary>
	<b>View Syntax Tree</b>
  </summary>
  
  ```vimscript
  :RustSyntaxTree
  ```
</details>

<details>
  <summary>
	<b>Fly check</b>
  </summary>

  Run `cargo check` or another compatible command (f.x. `clippy`) 
  in a background thread and provide LSP diagnostics based on 
  the output of the command.

  Useful in large projects where running `cargo check` on each save
  can be costly.
  
  ```vimscript
  :RustFlyCheck
  ```
</details>

## Configuration
The options shown below are the defaults. You only need to pass the keys to the setup function that you want to be changed, because the defaults are applied for keys that are not provided. 

```lua
local opts = {
  tools = { -- plugin options

    -- how to execute terminal commands
    -- options right now: termopen / quickfix / toggleterm / vimux
    executor = require("rust-tools.executors").termopen,

    -- callback to execute once rust-analyzer is done initializing the workspace
    -- The callback receives one parameter indicating the `health` of the server: "ok" | "warning" | "error"
    on_initialized = nil,

    -- automatically call RustReloadWorkspace when writing to a Cargo.toml file.
    reload_workspace_from_cargo_toml = true,

    -- options same as lsp hover / vim.lsp.util.open_floating_preview()
    hover_actions = {

      -- the border that is used for the hover window
      -- see vim.api.nvim_open_win()
      border = {
        { "╭", "FloatBorder" },
        { "─", "FloatBorder" },
        { "╮", "FloatBorder" },
        { "│", "FloatBorder" },
        { "╯", "FloatBorder" },
        { "─", "FloatBorder" },
        { "╰", "FloatBorder" },
        { "│", "FloatBorder" },
      },

      -- Maximal width of the hover window. Nil means no max.
      max_width = nil,

      -- Maximal height of the hover window. Nil means no max.
      max_height = nil,

      -- whether the hover action window gets automatically focused
      -- default: false
      auto_focus = false,
    },

    -- settings for showing the crate graph based on graphviz and the dot
    -- command
    crate_graph = {
      -- Backend used for displaying the graph
      -- see: https://graphviz.org/docs/outputs/
      -- default: x11
      backend = "x11",
      -- where to store the output, nil for no output stored (relative
      -- path from pwd)
      -- default: nil
      output = nil,
      -- true for all crates.io and external crates, false only the local
      -- crates
      -- default: true
      full = true,

      -- List of backends found on: https://graphviz.org/docs/outputs/
      -- Is used for input validation and autocompletion
      -- Last updated: 2021-08-26
      enabled_graphviz_backends = {
        "bmp",
        "cgimage",
        "canon",
        "dot",
        "gv",
        "xdot",
        "xdot1.2",
        "xdot1.4",
        "eps",
        "exr",
        "fig",
        "gd",
        "gd2",
        "gif",
        "gtk",
        "ico",
        "cmap",
        "ismap",
        "imap",
        "cmapx",
        "imap_np",
        "cmapx_np",
        "jpg",
        "jpeg",
        "jpe",
        "jp2",
        "json",
        "json0",
        "dot_json",
        "xdot_json",
        "pdf",
        "pic",
        "pct",
        "pict",
        "plain",
        "plain-ext",
        "png",
        "pov",
        "ps",
        "ps2",
        "psd",
        "sgi",
        "svg",
        "svgz",
        "tga",
        "tiff",
        "tif",
        "tk",
        "vml",
        "vmlz",
        "wbmp",
        "webp",
        "xlib",
        "x11",
      },
    },
  },

  -- all the opts to send to rust-analyzer
  server = {
    -- standalone file support
    -- setting it to false may improve startup time
    standalone = true,
  }, -- rust-analyzer options

  -- debugging stuff
  dap = {
    adapter = {
      type = "executable",
      command = "lldb-vscode",
      name = "rt_lldb",
    },
  },
}

require('rust-tools').setup(opts)
```

## Related Projects
- [`Saecki/crates.nvim`](https://github.com/Saecki/crates.nvim)

## Inspiration
This plugin draws inspiration from [`akinsho/flutter-tools.nvim`](https://github.com/akinsho/flutter-tools.nvim)
