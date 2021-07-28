# rust-tools.nvim
Extra rust tools for writing applications in neovim using the native lsp.
This plugin adds extra functionality over rust analyzer.

## Prerequisites

- `neovim 0.5+`
- `nvim-lspconfig`
- `rust-analyzer`

## Installation

using `vim-plug`

```vim
Plug 'neovim/nvim-lspconfig'
Plug 'simrat39/rust-tools.nvim'

" Optional dependencies
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'

" Debugging (needs plenary from above as well)
Plug "mfussenegger/nvim-dap"
```
<b>Look at the configuration information below to get started.</b>

# Configuration + Functionality

This plugin automatically sets up nvim-lspconfig for rust_analyzer for you, so there is no need to do that manually

## Initial setup

```lua
local opts = {
    tools = { -- rust-tools options
        -- automatically set inlay hints (type hints)
        -- There is an issue due to which the hints are not applied on the first
        -- opened file. For now, write to the file to trigger a reapplication of
        -- the hints or just run :RustSetInlayHints.
        -- default: true
        autoSetHints = true,

        -- whether to show hover actions inside the hover window
        -- this overrides the default hover handler so something like lspsaga.nvim's hover would be overriden by this
        -- default: true
        hover_with_actions = true,

        runnables = {
            -- whether to use telescope for selection menu or not
            -- default: true
            use_telescope = true

            -- rest of the opts are forwarded to telescope
        },

        debuggables = {
            -- whether to use telescope for selection menu or not
            -- default: true
            use_telescope = true

            -- rest of the opts are forwarded to telescope
        },

        -- These apply to the default RustSetInlayHints command
        inlay_hints = {
            -- wheter to show parameter hints with the inlay hints or not
            -- default: true
            show_parameter_hints = true,

            -- prefix for parameter hints
            -- default: "<-"
            parameter_hints_prefix = "<- ",

            -- prefix for all the other hints (type, chaining)
            -- default: "=>"
            other_hints_prefix = "=> ",

            -- whether to align to the length of the longest line in the file
            max_len_align = false,

            -- padding from the left if max_len_align is true
            max_len_align_padding = 1,

            -- whether to align to the extreme right or not
            right_align = false,

            -- padding from the right if right_align is true
            right_align_padding = 7
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
            -- default: false
            auto_focus = false
        }
    },

    -- all the opts to send to nvim-lspconfig
    -- these override the defaults set by rust-tools.nvim
    -- see https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md#rust_analyzer
    server = {} -- rust-analyer options
}

require('rust-tools').setup(opts)
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
RustMoveItemDown
RustMoveItemUp
RustStartStandaloneServerForBuffer 
RustDebuggables
```

## Standalone File Support
rust-tools supports rust analyzer for standalone files (not in a cargo project).
The language server is automatically started when you start a rust file which is
not in a cargo file (nvim abc.rs). If you want to attach some other buffer to
the standalone client (after opening nvim and switching to a new rust file),
then use the ```RustStartStandaloneServerForBuffer``` command.

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

## Demos

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
```lua
-- Command:
-- RustHoverActions 
require'rust-tools.hover_actions'.hover_actions()
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

## Inspiration

This plugin draws inspiration from [`akinsho/flutter-tools.nvim`](https://github.com/akinsho/flutter-tools.nvim)
