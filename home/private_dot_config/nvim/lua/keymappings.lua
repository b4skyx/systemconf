-- GLOBAL KEYMAPPINGS
-- Every mapping has a `desc` so it shows up readably in :Telescope keymaps
-- (<leader>fk) and any keymap-help plugin.
--
-- Visual-mode mappings use "x" (not "v"/"" which also cover Select mode):
-- Select mode is used by snippet placeholders, where typed characters like
-- <, >, S or <Space> must insert text instead of triggering a mapping.
local map = vim.keymap.set

-- Clipboard (system "+ register)
map("x", "<leader>y", '"+y', { desc = "Yank selection to system clipboard" })
map("n", "<leader>y", '"+y', { desc = "Yank {motion} to system clipboard" })
map("n", "<leader>yy", '"+yy', { desc = "Yank line to system clipboard" })
map("n", "<leader>Y", '"+yg_', { desc = "Yank to end of line (no newline) to system clipboard" })
map({ "n", "x" }, "<leader>p", '"+p', { desc = "Paste from system clipboard after cursor" })
map({ "n", "x" }, "<leader>P", '"+P', { desc = "Paste from system clipboard before cursor" })

-- Window navigation
map({ "n", "x" }, "<C-h>", "<C-w>h", { desc = "Go to left window" })
map({ "n", "x" }, "<C-j>", "<C-w>j", { desc = "Go to window below" })
map({ "n", "x" }, "<C-k>", "<C-w>k", { desc = "Go to window above" })
map({ "n", "x" }, "<C-l>", "<C-w>l", { desc = "Go to right window" })
map({ "n", "x" }, "<C-Up>", "<C-w><Up>", { desc = "Go to window above" })
map({ "n", "x" }, "<C-Down>", "<C-w><Down>", { desc = "Go to window below" })
map({ "n", "x" }, "<C-Left>", "<C-w><Left>", { desc = "Go to left window" })
map({ "n", "x" }, "<C-Right>", "<C-w><Right>", { desc = "Go to right window" })

-- Window resizing
map("n", "<C-S-Up>", "<Cmd>resize -2<CR>", { desc = "Decrease window height" })
map("n", "<C-S-Down>", "<Cmd>resize +2<CR>", { desc = "Increase window height" })
map("n", "<C-S-Left>", "<Cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<C-S-Right>", "<Cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- Editing
map("n", "c", '"_c', { desc = "Change without overwriting the unnamed register" })
map("n", "S", ":%s//g<Left><Left>", { desc = "Substitute in whole file (:%s//g)" })
map("x", "S", ":s//g<Left><Left>", { desc = "Substitute in selection (:s//g)" })
map("x", "<", "<gv", { desc = "Indent left and keep selection" })
map("x", ">", ">gv", { desc = "Indent right and keep selection" })
map({ "n", "x" }, "<leader>D", ":put =strftime('# %a %b %d, %Y - %I:%M %p')<CR>", {
	silent = true,
	desc = "Insert date/time heading below",
})

-- Buffers / UI toggles
map("n", "<leader>x", "<Cmd>bdelete!<CR>", { desc = "Delete buffer (discard changes)" })
map("n", "<leader>h", "<Cmd>set hlsearch!<CR>", { desc = "Toggle search highlighting" })
-- (<leader>o is Lspsaga outline)
map("n", "<leader>s", "<Cmd>setlocal spell! spelllang=en_us<CR>", { desc = "Toggle spell check (en_us)" })

-- Terminal
map("n", "<C-\\>", "<Cmd>belowright split | terminal<CR>", { desc = "Open terminal in split below" })

-- UndoTree toggle: <F5> (defined in lua/plugins/editor.lua)

-- Descriptions for global mappings that plugins define without one.
-- Applied on VimEnter, after all plugin/ and after/plugin/ files have run.
local plugin_mapping_descs = {
	{ "n", "@", "Execute macro (faster.nvim pauses slow features while it runs)" },
	{ "n", "<leader>ww", "Wiki: open index" },
	{ "n", "<leader>wt", "Wiki: open index in new tab" },
	{ "n", "<leader>ws", "Wiki: select wiki" },
	{ "n", "<leader>wi", "Wiki: open diary index" },
	{ "n", "<leader>w<leader>w", "Wiki: today's diary note" },
	{ "n", "<leader>w<leader>t", "Wiki: today's diary note in new tab" },
	{ "n", "<leader>w<leader>y", "Wiki: yesterday's diary note" },
	{ "n", "<leader>w<leader>m", "Wiki: tomorrow's diary note" },
	{ "n", "<leader>w<leader>i", "Wiki: regenerate diary links" },
}

vim.api.nvim_create_autocmd("VimEnter", {
	group = vim.api.nvim_create_augroup("PluginMappingDescs", { clear = true }),
	once = true,
	callback = function()
		for _, m in ipairs(plugin_mapping_descs) do
			local mode, lhs, desc = m[1], m[2], m[3]
			local d = vim.fn.maparg(lhs, mode, false, true)
			if d.lhs and (d.desc == nil or d.desc == "") then
				d.desc = desc
				vim.fn.mapset(d)
			end
		end
	end,
})
