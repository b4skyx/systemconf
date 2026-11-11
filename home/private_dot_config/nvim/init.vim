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
" WSL: use the Windows clipboard (clip.exe / PowerShell), no win32yank needed
if has('wsl')
  let g:clipboard = {
    \   'name': 'WslClipboard',
    \   'copy': {
    \      '+': 'clip.exe',
    \      '*': 'clip.exe',
    \    },
    \   'paste': {
    \      '+': 'powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    \      '*': 'powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    \   },
    \   'cache_enabled': 0,
    \ }
endif
lua << EOF
require("init")
EOF
