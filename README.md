# rust-tools.nvim
Extra rust tools for writing applications in neovim using the native lsp.
This plugin adds extra functionality over rust analyzer.

# _**Recent breaking changes**_
We no longer use telescope.nvim for Runnables/Debuggables. Instead we
now use vim.ui.select. Check out 
[telescope-ui-select.nvim](https://github.com/nvim-telescope/telescope-ui-select.nvim)
or [popui.nvim](https://github.com/hood/popui.nvim) for pretty interfaces.

## Prerequisites

- `neovim 0.6`
- `nvim-lspconfig`
- `rust-analyzer`
- `dot` from `graphviz` (only for crate graph)

## Installation

using `vim-plug`

```vim
Plug 'neovim/nvim-lspconfig'
Plug 'simrat39/rust-tools.nvim'

" Debugging
Plug 'nvim-lua/plenary.nvim'
Plug 'mfussenegger/nvim-dap'
```
<b>Look at the configuration information below to get started.</b>

# Configuration + Functionality

This plugin automatically sets up nvim-lspconfig for rust_analyzer for you, so there is no need to do that manually

## Setup
Put this in your init.lua or any lua file that is sourced.<br>

For most people, the defaults are fine, but for advanced configuration, see [Configuration](#configuration)
```lua
require('rust-tools').setup({})
```

## Commands
```vim
RustSetInlayHints
RustDisableInlayHints
RustToggleInlayHints
RustRunnables
RustExpandMacro
RustOpenCargo 
RustParentModule
RustJoinLines
RustHoverActions
RustHoverRange 
RustMoveItemDown
RustMoveItemUp
RustStartStandaloneServerForBuffer 
RustDebuggables
RustViewCrateGraph
RustReloadWorkspace
RustSSR
```

## Standalone File Support
rust-tools supports rust analyzer for standalone files (not in a cargo project).
The language server is automatically started when you start a rust file which is
not in a cargo file (nvim abc.rs). If you want to attach some other buffer to
the standalone client (after opening nvim and switching to a new rust file),
then use the RustStartStandaloneServerForBuffer command.

## Debugging

Depends on:
1. [nvim-dap](https://github.com/mfussenegger/nvim-dap)
2. [lldb-vscode](https://lldb.llvm.org/) (Comes with an installation of lldb)
3. [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
 
rust-tools supports debugging with the help of rust-analyzer. Note that the plugin does not setup nvim-dap for you, but it has its own internal configuration, so if you want a seperate debugging config then you can do it the normal way.

Currently, rust-tools support debugging in two different ways:

### RustDebuggables
Similar to ```RustRunnables```, this command provides a list of targets that can be debugged, from specific tests to the entire project. Just run the command and chose your target, and the debugging will begin.

### Hover actions
Put your cursor on the main function, enter the hover actions menu and select the debug option to debug the entire application.

Put your cursor on any test module or function, enter the hover actions menu and select the debug option to debug the certain test. 

Future support for code lenses and telescope/runnables is also planned.

### A better debugging experience...
For basic debugging, lldb-vscode is good enough. But if you want something
better, you might wanna read this section.

You might have noticed that lldb-vscode does not show types like strings and
enums properly, but vscode does. How could this be 🤔 🤔

This is because vscode uses a wrapper *over* lldb which provides all the
goodies. Setting it up for nvim is a bit wack, but thankfully rust-tools
provides some utility functions to make the process easier.

Steps:
1. Download the [CodeLLDB](https://marketplace.visualstudio.com/items?itemName=vadimcn.vscode-lldb) vscode extension.
2. Find out where its installed. On linux, it's usually in
   ```/home/___/.vscode/extensions/...```
3. Update your configuration:
```lua
-- Update this path
local extension_path = '/home/simrat39/.vscode/extensions/vadimcn.vscode-lldb-1.6.7/'
local codelldb_path = extension_path .. 'adapter/codelldb'
local liblldb_path = extension_path .. 'lldb/lib/liblldb.so'

local opts = {
    -- ... other configs
    dap = {
        adapter = require('rust-tools.dap').get_codelldb_adapter(
            codelldb_path, liblldb_path)
    }
}

-- Normal setup
require('rust-tools').setup(opts)
```

## Configuration
The options shown below are the defaults. You only need to pass the keys to the setup function that you want to be changed, because the defaults are applied for keys that are not provided. 

```lua
local opts = {
    tools = { -- rust-tools options
        -- Automatically set inlay hints (type hints)
        autoSetHints = true,

        -- Whether to show hover actions inside the hover window
        -- This overrides the default hover handler 
        hover_with_actions = true,

		-- how to execute terminal commands
		-- options right now: termopen / quickfix
		executor = require("rust-tools/executors").termopen,

        runnables = {
            -- whether to use telescope for selection menu or not
            use_telescope = true

            -- rest of the opts are forwarded to telescope
        },

        debuggables = {
            -- whether to use telescope for selection menu or not
            use_telescope = true

            -- rest of the opts are forwarded to telescope
        },

        -- These apply to the default RustSetInlayHints command
        inlay_hints = {

            -- Only show inlay hints for the current line
            only_current_line = false,

            -- Event which triggers a refersh of the inlay hints.
            -- You can make this "CursorMoved" or "CursorMoved,CursorMovedI" but
            -- not that this may cause  higher CPU usage.
            -- This option is only respected when only_current_line and
            -- autoSetHints both are true.
            only_current_line_autocmd = "CursorHold",

            -- wheter to show parameter hints with the inlay hints or not
            show_parameter_hints = true,

            -- prefix for parameter hints
            parameter_hints_prefix = "<- ",

            -- prefix for all the other hints (type, chaining)
            other_hints_prefix = "=> ",

            -- whether to align to the length of the longest line in the file
            max_len_align = false,

            -- padding from the left if max_len_align is true
            max_len_align_padding = 1,

            -- whether to align to the extreme right or not
            right_align = false,

            -- padding from the right if right_align is true
            right_align_padding = 7,

            -- The color of the hints
            highlight = "Comment",
        },

        hover_actions = {
            -- the border that is used for the hover window
            -- see vim.api.nvim_open_win()
            border = {
                {"╭", "FloatBorder"}, {"─", "FloatBorder"},
                {"╮", "FloatBorder"}, {"│", "FloatBorder"},
                {"╯", "FloatBorder"}, {"─", "FloatBorder"},
                {"╰", "FloatBorder"}, {"│", "FloatBorder"}
            },

            -- whether the hover action window gets automatically focused
            auto_focus = false
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
        }
    },

    -- all the opts to send to nvim-lspconfig
    -- these override the defaults set by rust-tools.nvim
    -- see https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#rust_analyzer
    server = {}, -- rust-analyer options

    -- debugging stuff
    dap = {
        adapter = {
            type = 'executable',
            command = 'lldb-vscode',
            name = "rt_lldb"
        }
    }
}

require('rust-tools').setup(opts)
```

## Demos

### Debugging
![debugging](https://github.com/simrat39/rust-tools-demos/raw/master/rust-tools-debug.gif)
Read what I wrote above smh

### Inlay Hints
![inlay hints](https://github.com/simrat39/rust-tools-demos/raw/master/inlay_hints.png)
```lua
-- Command:
-- RustSetInlayHints
-- RustDisableInlayHints 
-- RustToggleInlayHints 

-- set inlay hints
require('rust-tools.inlay_hints').set_inlay_hints()
-- disable inlay hints
require('rust-tools.inlay_hints').disable_inlay_hints()
-- toggle inlay hints
require('rust-tools.inlay_hints').toggle_inlay_hints()
```

### Runnables
![runnables](https://github.com/simrat39/rust-tools-demos/raw/master/runnables.gif)
```lua
-- Command:
-- RustRunnables
require('rust-tools.runnables').runnables()
```
### Expand Macros Recursively 
![expand macros](https://github.com/simrat39/rust-tools-demos/raw/master/expand_macros_recursively.gif)
```lua
-- Command:
-- RustExpandMacro  
require'rust-tools.expand_macro'.expand_macro()
```

### Move Item Up/Down
![move items](https://github.com/simrat39/rust-tools-demos/raw/master/move_item.gif)
```lua
-- Command:
-- RustMoveItemUp    
-- RustMoveItemDown    
local up = true -- true = move up, false = move down
require'rust-tools.move_item'.move_item(up)
```

### Hover Actions
![hover actions](https://github.com/simrat39/rust-tools-demos/raw/master/hover_actions.gif)
Note: To activate hover actions, run the command twice (or your hover keymap if you have ```hover_with_actions``` set to true AND are using ```vim.lsp.buf.hover()```). This will move you into the window, then press enter on the selection you want. Alternatively, you can set ```auto_focus``` to true in your config and you will automatically enter the hover actions window.
```lua
-- Command:
-- RustHoverActions 
require'rust-tools.hover_actions'.hover_actions()
```

### Hover Range
Note: Requires rust-analyzer version after 2021-08-02. Shows the type in visual mode when hovering.
```lua
-- Command:
-- RustHoverRange 
require'rust-tools.hover_range'.hover_range()
```

### Open Cargo.toml
![open cargo](https://github.com/simrat39/rust-tools-demos/raw/master/open_cargo_toml.gif)
```lua
-- Command:
-- RustOpenCargo
require'rust-tools.open_cargo_toml'.open_cargo_toml()
```

### Parent Module
![parent module](https://github.com/simrat39/rust-tools-demos/raw/master/parent_module.gif)
```lua
-- Command:
-- RustParentModule 
require'rust-tools.parent_module'.parent_module()
```

### Join Lines
![join lines](https://github.com/simrat39/rust-tools-demos/raw/master/join_lines.gif)
```lua
-- Command:
-- RustJoinLines  
require'rust-tools.join_lines'.join_lines()
```

### Structural Search Replace 
```lua
-- Command:
-- RustSSR [query]
require'rust-tools.ssr'.ssr(query)
```

### View crate graph
```lua
-- Command:
-- RustViewCrateGraph [backend [output]]
require'rust-tools.crate_graph'.view_crate_graph(backend, output)
```

## Related Projects
- [`Saecki/crates.nvim`](https://github.com/Saecki/crates.nvim)

## Inspiration
This plugin draws inspiration from [`akinsho/flutter-tools.nvim`](https://github.com/akinsho/flutter-tools.nvim)
