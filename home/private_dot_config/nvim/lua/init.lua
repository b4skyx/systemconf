-- Load Defaults
require('settings')
require('keymappings')

if vim.g.neovide then
	vim.o.guifont = "Comic Code:h14"
	vim.g.neovide_refresh_rate = 120
	vim.g.neovide_scroll_animation_length = 0
end

-- Lazypath Plugin Manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {
	install = { colorscheme = { vim.g.user_colorscheme } },
	change_detection = { notify = false },
	rocks = { enabled = false }, -- no plugin needs luarocks
})
