require("nvim-tree").setup({
	sort_by = "case_sensitive",
	renderer = {
		group_empty = true,
	},
	filters = {
		dotfiles = true,
	},
})
vim.api.nvim_create_autocmd("BufEnter", {
	nested = true,
	callback = function()
		-- Only 1 window with nvim-tree left: we probably closed a file buffer
		if #vim.api.nvim_list_wins() == 1 and require("nvim-tree.utils").is_nvim_tree_buf() then
			local api = require("nvim-tree.api")
			-- Required to let the close event complete. An error is thrown without this.
			vim.defer_fn(function()
				-- close nvim-tree: will go to the last buffer used before closing
				api.tree.toggle({ find_file = true, focus = true })
				-- re-open nivm-tree
				api.tree.toggle({ find_file = true, focus = true })
				-- nvim-tree is still the active window. Go to the previous window.
				vim.cmd("wincmd p")
			end, 0)
		end
	end,
})
vim.keymap.set("n", "<C-n>", "<Cmd>NvimTreeToggle<CR>", { desc = "Toggle file tree (nvim-tree)" })
