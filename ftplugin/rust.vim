command RustStartStandaloneServerForBuffer :lua require('rust-tools.standalone').start_standalone_client()

" Copied from vim
set errorformat=
			\%f:%l:%c:\ %t%*[^:]:\ %m,
			\%f:%l:%c:\ %*\\d:%*\\d\ %t%*[^:]:\ %m,
			\%-G%f:%l\ %s,
			\%-G%*[\ ]^,
			\%-G%*[\ ]^%*[~],
			\%-G%*[\ ]...

" New errorformat (after nightly 2016/08/10)
set errorformat+=
			\%-G,
			\%-Gerror:\ aborting\ %.%#,
			\%-Gerror:\ Could\ not\ compile\ %.%#,
			\%Eerror:\ %m,
			\%Eerror[E%n]:\ %m,
			\%Wwarning:\ %m,
			\%Inote:\ %m,
			\%C\ %#-->\ %f:%l:%c

set errorformat+=
			\%-G%\\s%#Downloading%.%#,
			\%-G%\\s%#Compiling%.%#,
			\%-G%\\s%#Finished%.%#,
			\%-G%\\s%#error:\ Could\ not\ compile\ %.%#,
			\%-G%\\s%#To\ learn\ more\\,%.%#
