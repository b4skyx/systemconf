-- Lspsaga: kept for hover, peek windows, finder, outline, winbar and the
-- floating terminal. Everything else uses the built-in LSP mappings.
require("lspsaga").setup({
	symbol_in_winbar = {
		enable = true,
		separator = " ",
		show_file = true,
	},
	lightbulb = {
		enable = false,
	},
})

local map = vim.keymap.set
map("n", "K", "<cmd>Lspsaga hover_doc<CR>", { silent = true, desc = "Hover (Lspsaga)" })
map("n", "pd", "<cmd>Lspsaga peek_definition<CR>", { silent = true, desc = "Peek definition" })
map("n", "pt", "<cmd>Lspsaga peek_type_definition<CR>", { silent = true, desc = "Peek type definition" })
-- gF (not gf, which is Vim's built-in "go to file")
map("n", "gF", "<cmd>Lspsaga finder<CR>", { silent = true, desc = "LSP finder" })
map("n", "<leader>o", "<cmd>Lspsaga outline<CR>", { desc = "Symbols outline" })
map({ "n", "t" }, "<leader>t", "<cmd>Lspsaga term_toggle fish<CR>", { desc = "Floating terminal" })
