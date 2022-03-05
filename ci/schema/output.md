**Possible rust-analyzer settings (rust-analyzer 2022-02-28)**  
```lua
-- example opts  
local opts = {  
  -- other configurations  
  server = {
    settings = {
      ['rust-analyzer'] {
        cargo = {
          autoReload = true
        }
      }
    }
  }
}
```

---
**`rust-analyzer.assist.exprFillDefault`**: `string`,   
**Default**: `todo`  
**Description**: Placeholder for missing expressions in assists.  
**Possible Values**
- **todo**: Fill missing expressions with the `todo` macro
- **default**: Fill missing expressions with reasonable defaults, `new` or `default` constructors.

---
**`rust-analyzer.assist.importGranularity`**: `string`,   
**Default**: `crate`  
**Description**: How imports should be grouped into use statements.  
**Possible Values**
- **preserve**: Do not change the granularity of any imports and preserve the original structure written by the developer.
- **crate**: Merge imports from the same crate into a single use statement. Conversely, imports from different crates are split into separate statements.
- **module**: Merge imports from the same module into a single use statement. Conversely, imports from different modules are split into separate statements.
- **item**: Flatten imports so that each has its own use statement.

---
**`rust-analyzer.assist.importEnforceGranularity`**: `boolean`,   
**Default**: `false`  
**Description**: Whether to enforce the import granularity setting for all files. If set to false rust-analyzer will try to keep import styles consistent per file.  

---
**`rust-analyzer.assist.importPrefix`**: `string`,   
**Default**: `plain`  
**Description**: The path structure for newly inserted paths to use.  
**Possible Values**
- **plain**: Insert import paths relative to the current module, using up to one `super` prefix if the parent module contains the requested item.
- **self**: Insert import paths relative to the current module, using up to one `super` prefix if the parent module contains the requested item. Prefixes `self` in front of the path if it starts with a module.
- **crate**: Force import paths to be absolute by always starting them with `crate` or the extern crate name they come from.

---
**`rust-analyzer.assist.importGroup`**: `boolean`,   
**Default**: `true`  
**Description**: Group inserted imports by the https://rust-analyzer.github.io/manual.html#auto-import[following order]. Groups are separated by newlines.  

---
**`rust-analyzer.assist.allowMergingIntoGlobImports`**: `boolean`,   
**Default**: `true`  
**Description**: Whether to allow import insertion to merge new imports into single path glob imports like `use std::fmt::*;`.  

---
**`rust-analyzer.cache.warmup`**: `boolean`,   
**Default**: `true`  
**Description**: Warm up caches on project load.  

---
**`rust-analyzer.callInfo.full`**: `boolean`,   
**Default**: `true`  
**Description**: Show function name and docs in parameter hints.  

---
**`rust-analyzer.cargo.autoreload`**: `boolean`,   
**Default**: `true`  
**Description**: Automatically refresh project info via `cargo metadata` on
`Cargo.toml` changes.  

---
**`rust-analyzer.cargo.allFeatures`**: `boolean`,   
**Default**: `false`  
**Description**: Activate all available features (`--all-features`).  

---
**`rust-analyzer.cargo.unsetTest`**: `array`,   
**Default**: `[core]`  
**Description**: Unsets `#[cfg(test)]` for the specified crates.  

---
**`rust-analyzer.cargo.features`**: `array`,   
**Default**: `[]`  
**Description**: List of features to activate.  

---
**`rust-analyzer.cargo.runBuildScripts`**: `boolean`,   
**Default**: `true`  
**Description**: Run build scripts (`build.rs`) for more precise code analysis.  

---
**`rust-analyzer.cargo.useRustcWrapperForBuildScripts`**: `boolean`,   
**Default**: `true`  
**Description**: Use `RUSTC_WRAPPER=rust-analyzer` when running build scripts to
avoid compiling unnecessary things.  

---
**`rust-analyzer.cargo.noDefaultFeatures`**: `boolean`,   
**Default**: `false`  
**Description**: Do not activate the `default` feature.  

---
**`rust-analyzer.cargo.target`**: `null`, `string`,   
**Default**: `null`  
**Description**: Compilation target (target triple).  

---
**`rust-analyzer.cargo.noSysroot`**: `boolean`,   
**Default**: `false`  
**Description**: Internal config for debugging, disables loading of sysroot crates.  

---
**`rust-analyzer.checkOnSave.enable`**: `boolean`,   
**Default**: `true`  
**Description**: Run specified `cargo check` command for diagnostics on save.  

---
**`rust-analyzer.checkOnSave.allFeatures`**: `null`, `boolean`,   
**Default**: `null`  
**Description**: Check with all features (`--all-features`).
Defaults to `#rust-analyzer.cargo.allFeatures#`.  

---
**`rust-analyzer.checkOnSave.allTargets`**: `boolean`,   
**Default**: `true`  
**Description**: Check all targets and tests (`--all-targets`).  

---
**`rust-analyzer.checkOnSave.command`**: `string`,   
**Default**: `check`  
**Description**: Cargo command to use for `cargo check`.  

---
**`rust-analyzer.checkOnSave.noDefaultFeatures`**: `null`, `boolean`,   
**Default**: `null`  
**Description**: Do not activate the `default` feature.  

---
**`rust-analyzer.checkOnSave.target`**: `null`, `string`,   
**Default**: `null`  
**Description**: Check for a specific target. Defaults to
`#rust-analyzer.cargo.target#`.  

---
**`rust-analyzer.checkOnSave.extraArgs`**: `array`,   
**Default**: `[]`  
**Description**: Extra arguments for `cargo check`.  

---
**`rust-analyzer.checkOnSave.features`**: `null`, `array`,   
**Default**: `null`  
**Description**: List of features to activate. Defaults to
`#rust-analyzer.cargo.features#`.  

---
**`rust-analyzer.checkOnSave.overrideCommand`**: `null`, `array`,   
**Default**: `null`  
**Description**: Advanced option, fully override the command rust-analyzer uses for
checking. The command should include `--message-format=json` or
similar option.  

---
**`rust-analyzer.completion.addCallArgumentSnippets`**: `boolean`,   
**Default**: `true`  
**Description**: Whether to add argument snippets when completing functions.
Only applies when `#rust-analyzer.completion.addCallParenthesis#` is set.  

---
**`rust-analyzer.completion.addCallParenthesis`**: `boolean`,   
**Default**: `true`  
**Description**: Whether to add parenthesis when completing functions.  

---
**`rust-analyzer.completion.snippets`**: `object`,   
**Default**: `{Arc::new: {postfix: arc, body: Arc::new(${receiver}), requires: std::sync::Arc, description: Put the expression into an `Arc`, scope: expr}, Rc::new: {postfix: rc, body: Rc::new(${receiver}), requires: std::rc::Rc, description: Put the expression into an `Rc`, scope: expr}, Box::pin: {postfix: pinbox, body: Box::pin(${receiver}), requires: std::boxed::Box, description: Put the expression into a pinned `Box`, scope: expr}, Ok: {postfix: ok, body: Ok(${receiver}), description: Wrap the expression in a `Result::Ok`, scope: expr}, Err: {postfix: err, body: Err(${receiver}), description: Wrap the expression in a `Result::Err`, scope: expr}, Some: {postfix: some, body: Some(${receiver}), description: Wrap the expression in an `Option::Some`, scope: expr}}`  
**Description**: Custom completion snippets.  

---
**`rust-analyzer.completion.postfix.enable`**: `boolean`,   
**Default**: `true`  
**Description**: Whether to show postfix snippets like `dbg`, `if`, `not`, etc.  

---
**`rust-analyzer.completion.autoimport.enable`**: `boolean`,   
**Default**: `true`  
**Description**: Toggles the additional completions that automatically add imports when completed.
Note that your client must specify the `additionalTextEdits` LSP client capability to truly have this feature enabled.  

---
**`rust-analyzer.completion.autoself.enable`**: `boolean`,   
**Default**: `true`  
**Description**: Toggles the additional completions that automatically show method calls and field accesses
with `self` prefixed to them when inside a method.  

---
**`rust-analyzer.completion.privateEditable.enable`**: `boolean`,   
**Default**: `false`  
**Description**: Enables completions of private items and fields that are defined in the current workspace even if they are not visible at the current position.  

---
**`rust-analyzer.diagnostics.enable`**: `boolean`,   
**Default**: `true`  
**Description**: Whether to show native rust-analyzer diagnostics.  

---
**`rust-analyzer.diagnostics.enableExperimental`**: `boolean`,   
**Default**: `true`  
**Description**: Whether to show experimental rust-analyzer diagnostics that might
have more false positives than usual.  

---
**`rust-analyzer.diagnostics.disabled`**: `array`,   
**Default**: `[]`  
**Description**: List of rust-analyzer diagnostics to disable.  

---
**`rust-analyzer.diagnostics.remapPrefix`**: `object`,   
**Default**: `{}`  
**Description**: Map of prefixes to be substituted when parsing diagnostic file paths.
This should be the reverse mapping of what is passed to `rustc` as `--remap-path-prefix`.  

---
**`rust-analyzer.diagnostics.warningsAsHint`**: `array`,   
**Default**: `[]`  
**Description**: List of warnings that should be displayed with hint severity.

The warnings will be indicated by faded text or three dots in code
and will not show up in the `Problems Panel`.  

---
**`rust-analyzer.diagnostics.warningsAsInfo`**: `array`,   
**Default**: `[]`  
**Description**: List of warnings that should be displayed with info severity.

The warnings will be indicated by a blue squiggly underline in code
and a blue icon in the `Problems Panel`.  

---
**`rust-analyzer.experimental.procAttrMacros`**: `boolean`,   
**Default**: `true`  
**Description**: Expand attribute macros.  

---
**`rust-analyzer.files.watcher`**: `string`,   
**Default**: `client`  
**Description**: Controls file watching implementation.  

---
**`rust-analyzer.files.excludeDirs`**: `array`,   
**Default**: `[]`  
**Description**: These directories will be ignored by rust-analyzer. They are
relative to the workspace root, and globs are not supported. You may
also need to add the folders to Code's `files.watcherExclude`.  

---
**`rust-analyzer.highlightRelated.references`**: `boolean`,   
**Default**: `true`  
**Description**: Enables highlighting of related references while hovering your mouse above any identifier.  

---
**`rust-analyzer.highlightRelated.exitPoints`**: `boolean`,   
**Default**: `true`  
**Description**: Enables highlighting of all exit points while hovering your mouse above any `return`, `?`, or return type arrow (`->`).  

---
**`rust-analyzer.highlightRelated.breakPoints`**: `boolean`,   
**Default**: `true`  
**Description**: Enables highlighting of related references while hovering your mouse `break`, `loop`, `while`, or `for` keywords.  

---
**`rust-analyzer.highlightRelated.yieldPoints`**: `boolean`,   
**Default**: `true`  
**Description**: Enables highlighting of all break points for a loop or block context while hovering your mouse above any `async` or `await` keywords.  

---
**`rust-analyzer.highlighting.strings`**: `boolean`,   
**Default**: `true`  
**Description**: Use semantic tokens for strings.

In some editors (e.g. vscode) semantic tokens override other highlighting grammars.
By disabling semantic tokens for strings, other grammars can be used to highlight
their contents.  

---
**`rust-analyzer.hover.documentation`**: `boolean`,   
**Default**: `true`  
**Description**: Whether to show documentation on hover.  

---
**`rust-analyzer.hover.linksInHover`**: `boolean`,   
**Default**: `true`  
**Description**: Use markdown syntax for links in hover.  

---
**`rust-analyzer.hoverActions.debug`**: `boolean`,   
**Default**: `true`  
**Description**: Whether to show `Debug` action. Only applies when
`#rust-analyzer.hoverActions.enable#` is set.  

---
**`rust-analyzer.hoverActions.enable`**: `boolean`,   
**Default**: `true`  
**Description**: Whether to show HoverActions in Rust files.  

---
**`rust-analyzer.hoverActions.gotoTypeDef`**: `boolean`,   
**Default**: `true`  
**Description**: Whether to show `Go to Type Definition` action. Only applies when
`#rust-analyzer.hoverActions.enable#` is set.  

---
**`rust-analyzer.hoverActions.implementations`**: `boolean`,   
**Default**: `true`  
**Description**: Whether to show `Implementations` action. Only applies when
`#rust-analyzer.hoverActions.enable#` is set.  

---
**`rust-analyzer.hoverActions.references`**: `boolean`,   
**Default**: `false`  
**Description**: Whether to show `References` action. Only applies when
`#rust-analyzer.hoverActions.enable#` is set.  

---
**`rust-analyzer.hoverActions.run`**: `boolean`,   
**Default**: `true`  
**Description**: Whether to show `Run` action. Only applies when
`#rust-analyzer.hoverActions.enable#` is set.  

---
**`rust-analyzer.inlayHints.chainingHints`**: `boolean`,   
**Default**: `true`  
**Description**: Whether to show inlay type hints for method chains.  

---
**`rust-analyzer.inlayHints.maxLength`**: `null`, `integer`,   
**Default**: `25`  
**Description**: Maximum length for inlay hints. Set to null to have an unlimited length.  

---
**`rust-analyzer.inlayHints.parameterHints`**: `boolean`,   
**Default**: `true`  
**Description**: Whether to show function parameter name inlay hints at the call
site.  

---
**`rust-analyzer.inlayHints.typeHints`**: `boolean`,   
**Default**: `true`  
**Description**: Whether to show inlay type hints for variables.  

---
**`rust-analyzer.inlayHints.hideNamedConstructorHints`**: `boolean`,   
**Default**: `false`  
**Description**: Whether to hide inlay hints for constructors.  

---
**`rust-analyzer.joinLines.joinElseIf`**: `boolean`,   
**Default**: `true`  
**Description**: Join lines inserts else between consecutive ifs.  

---
**`rust-analyzer.joinLines.removeTrailingComma`**: `boolean`,   
**Default**: `true`  
**Description**: Join lines removes trailing commas.  

---
**`rust-analyzer.joinLines.unwrapTrivialBlock`**: `boolean`,   
**Default**: `true`  
**Description**: Join lines unwraps trivial blocks.  

---
**`rust-analyzer.joinLines.joinAssignments`**: `boolean`,   
**Default**: `true`  
**Description**: Join lines merges consecutive declaration and initialization of an assignment.  

---
**`rust-analyzer.lens.debug`**: `boolean`,   
**Default**: `true`  
**Description**: Whether to show `Debug` lens. Only applies when
`#rust-analyzer.lens.enable#` is set.  

---
**`rust-analyzer.lens.enable`**: `boolean`,   
**Default**: `true`  
**Description**: Whether to show CodeLens in Rust files.  

---
**`rust-analyzer.lens.implementations`**: `boolean`,   
**Default**: `true`  
**Description**: Whether to show `Implementations` lens. Only applies when
`#rust-analyzer.lens.enable#` is set.  

---
**`rust-analyzer.lens.run`**: `boolean`,   
**Default**: `true`  
**Description**: Whether to show `Run` lens. Only applies when
`#rust-analyzer.lens.enable#` is set.  

---
**`rust-analyzer.lens.methodReferences`**: `boolean`,   
**Default**: `false`  
**Description**: Whether to show `Method References` lens. Only applies when
`#rust-analyzer.lens.enable#` is set.  

---
**`rust-analyzer.lens.references`**: `boolean`,   
**Default**: `false`  
**Description**: Whether to show `References` lens for Struct, Enum, Union and Trait.
Only applies when `#rust-analyzer.lens.enable#` is set.  

---
**`rust-analyzer.lens.enumVariantReferences`**: `boolean`,   
**Default**: `false`  
**Description**: Whether to show `References` lens for Enum Variants.
Only applies when `#rust-analyzer.lens.enable#` is set.  

---
**`rust-analyzer.lens.forceCustomCommands`**: `boolean`,   
**Default**: `true`  
**Description**: Internal config: use custom client-side commands even when the
client doesn't set the corresponding capability.  

---
**`rust-analyzer.linkedProjects`**: `array`,   
**Default**: `[]`  
**Description**: Disable project auto-discovery in favor of explicitly specified set
of projects.

Elements must be paths pointing to `Cargo.toml`,
`rust-project.json`, or JSON objects in `rust-project.json` format.  

---
**`rust-analyzer.lruCapacity`**: `null`, `integer`,   
**Default**: `null`  
**Description**: Number of syntax trees rust-analyzer keeps in memory. Defaults to 128.  

---
**`rust-analyzer.notifications.cargoTomlNotFound`**: `boolean`,   
**Default**: `true`  
**Description**: Whether to show `can't find Cargo.toml` error message.  

---
**`rust-analyzer.primeCaches.numThreads`**: `number`,   
**Default**: `0`  
**Description**: How many worker threads to to handle priming caches. The default `0` means to pick automatically.  

---
**`rust-analyzer.procMacro.enable`**: `boolean`,   
**Default**: `true`  
**Description**: Enable support for procedural macros, implies `#rust-analyzer.cargo.runBuildScripts#`.  

---
**`rust-analyzer.procMacro.server`**: `null`, `string`,   
**Default**: `null`  
**Description**: Internal config, path to proc-macro server executable (typically,
this is rust-analyzer itself, but we override this in tests).  

---
**`rust-analyzer.procMacro.ignored`**: `object`,   
**Default**: `{}`  
**Description**: These proc-macros will be ignored when trying to expand them.

This config takes a map of crate names with the exported proc-macro names to ignore as values.  

---
**`rust-analyzer.runnables.overrideCargo`**: `null`, `string`,   
**Default**: `null`  
**Description**: Command to be executed instead of 'cargo' for runnables.  

---
**`rust-analyzer.runnables.cargoExtraArgs`**: `array`,   
**Default**: `[]`  
**Description**: Additional arguments to be passed to cargo for runnables such as
tests or binaries. For example, it may be `--release`.  

---
**`rust-analyzer.rustcSource`**: `null`, `string`,   
**Default**: `null`  
**Description**: Path to the Cargo.toml of the rust compiler workspace, for usage in rustc_private
projects, or "discover" to try to automatically find it if the `rustc-dev` component
is installed.

Any project which uses rust-analyzer with the rustcPrivate
crates must set `[package.metadata.rust-analyzer] rustc_private=true` to use it.

This option does not take effect until rust-analyzer is restarted.  

---
**`rust-analyzer.rustfmt.extraArgs`**: `array`,   
**Default**: `[]`  
**Description**: Additional arguments to `rustfmt`.  

---
**`rust-analyzer.rustfmt.overrideCommand`**: `null`, `array`,   
**Default**: `null`  
**Description**: Advanced option, fully override the command rust-analyzer uses for
formatting.  

---
**`rust-analyzer.rustfmt.enableRangeFormatting`**: `boolean`,   
**Default**: `false`  
**Description**: Enables the use of rustfmt's unstable range formatting command for the
`textDocument/rangeFormatting` request. The rustfmt option is unstable and only
available on a nightly build.  

---
**`rust-analyzer.workspace.symbol.search.scope`**: `string`,   
**Default**: `workspace`  
**Description**: Workspace symbol search scope.  
**Possible Values**
- **workspace**: Search in current workspace only
- **workspace_and_dependencies**: Search in current workspace and dependencies

---
**`rust-analyzer.workspace.symbol.search.kind`**: `string`,   
**Default**: `only_types`  
**Description**: Workspace symbol search kind.  
**Possible Values**
- **only_types**: Search for types only
- **all_symbols**: Search for all symbols kinds

---
