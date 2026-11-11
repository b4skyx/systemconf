" ███╗   ██╗ ███████╗ ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗
" ████╗  ██║ ██╔════╝██╔═══██╗ ██║   ██║ ██║ ████╗ ████║
" ██╔██╗ ██║ █████╗  ██║   ██║ ██║   ██║ ██║ ██╔████╔██║
" ██║╚██╗██║ ██╔══╝  ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║
" ██║ ╚████║ ███████╗╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║
" ╚═╝  ╚═══╝ ╚══════╝ ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝

let mapleader =" "
let maplocalleader = ";"

" VimWiki Config
let g:vimwiki_list = [{'path': '~/Workspace/VimWiki/',
                      \ 'syntax': 'markdown', 'ext': '.md'}]

let g:vimwiki_listsyms = '✗○◐●✓'
let g:vimwiki_auto_header = 0
let g:vimwiki_diary_caption_level = -1
" let g:clipboard = {
"                         \   'name': 'win32yank-wsl',
"                         \   'copy': {
"                         \      '+': 'win32yank.exe -i --crlf',
"                         \      '*': 'win32yank.exe -i --crlf',
"                         \    },
"                         \   'paste': {
"                         \      '+': 'win32yank.exe -o --lf',
"                         \      '*': 'win32yank.exe -o --lf',
"                         \   },
"                         \   'cache_enabled': 0,
"                         \ }
" " }}}
lua << EOF
require("init")
EOF
