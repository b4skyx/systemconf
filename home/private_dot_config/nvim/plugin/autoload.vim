" Augroup to handle autocmds when reloading :source %
augroup RELOAD
	" Remove all autocmds
	autocmd!

	" Don't show linenumber on term
	autocmd TermOpen * setlocal norelativenumber nonumber
	" Pick up changes made to files outside Neovim (other editors, agents, git).
	" Needs `set -g focus-events on` in tmux for FocusGained to fire.
	autocmd FocusGained,BufEnter,CursorHold,TermLeave * if mode() !~# '\v(c|r.?|!|t)' && getcmdwintype() ==# '' | checktime | endif
	autocmd FileChangedShellPost * lua vim.notify("File changed on disk, buffer reloaded", vim.log.levels.INFO)

	autocmd BufEnter term://* setlocal nonumber
	" Disables automatic commenting on newline:
	autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
	" Trailing whitespace stripping lives in plugin/whitespace.lua (changed lines only).
	" Diagnostics for the cursor line are shown via virtual_lines (configs/lsp.lua).
augroup END

if has("autocmd")
  au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
endif
au VimLeave * set guicursor= | call chansend(v:stderr, "\x1b[ q")
