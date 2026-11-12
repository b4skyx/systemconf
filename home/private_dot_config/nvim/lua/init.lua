-- Load Defaults
require('settings')
require('keymappings')

-- Machine-local overrides (untracked by chezmoi), e.g. vim.g.user_colorscheme.
-- Loaded before lazy so plugin conds/colorscheme see the override. A missing
-- file is fine; real errors inside it are still reported.
local ok, err = pcall(require, 'usersettings')
if not ok and not tostring(err):match("module 'usersettings' not found") then
	vim.notify(err, vim.log.levels.ERROR)
end

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
