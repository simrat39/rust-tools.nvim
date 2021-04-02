# rust-tools.nvim
Extra rust tools for writing applications in neovim using the native lsp.
This plugin adds extra functionality over rust analyzer. The features mirror VsCode.

# Inspiration

This plugin draws inspiration from [`akinsho/flutter-tools.nvim`](https://github.com/akinsho/flutter-tools.nvim)

## Prerequisites

- `neovim 0.5+` (nightly)
- `nvim-lspconfig`
- `rust-analyzer`

## Installation

using `vim-plug`

```vim
Plug "neovim/nvim-lspconfig"
Plug "simrat39/rust-tools.nvim"
```
Please configure [`nvim-lspconfig for rust`](https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md#rust_analyzer) before using this plugin.

# Functionality

#### Inlay Hints
![inlay hints](./images/inlay_hints.png)

#### Expand Macros Recursively 
![expand macros](./images/expand_macros_recursively.gif)

#### Open Cargo.toml
![open cargo](./images/open_cargo_toml.gif)

#### Parent Module
![parent module](./images/parent_module.gif)