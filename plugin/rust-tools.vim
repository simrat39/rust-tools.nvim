autocmd BufWritePost */Cargo.toml lua require('rust-tools/workspace_refresh')._reload_workspace_from_cargo_toml()
au VimEnter *.rs lua require('rust-tools').start_standalone_if_required()
