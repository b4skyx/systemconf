-- Statusline + tabline (lualine's built-in buffers/tabs replace tabline.nvim)
vim.opt.sessionoptions:append({ "tabpages", "globals" })

require("lualine").setup({
	options = {
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		theme = "gruvbox-material",
		globalstatus = true,
		disabled_filetypes = {
			statusline = {},
			winbar = {},
		},
	},
	sections = {
		lualine_c = {
			{ "filename" },
			{
				-- Native LSP progress (Neovim 0.10+), no extra plugin needed.
				function()
					return vim.lsp.status()
				end,
			},
		},
	},
	tabline = {
		lualine_a = {
			{
				"buffers",
				show_filename_only = false,
				max_length = function()
					return math.floor(vim.o.columns * 2 / 3)
				end,
				symbols = { modified = " +", alternate_file = "", directory = "" },
			},
		},
		lualine_z = {
			{
				"tabs",
				cond = function()
					return #vim.api.nvim_list_tabpages() > 1
				end,
			},
		},
	},
})

-- Redraw statusline on LSP progress updates.
vim.api.nvim_create_autocmd("LspProgress", {
	group = vim.api.nvim_create_augroup("LualineLspProgress", { clear = true }),
	callback = function()
		require("lualine").refresh({ place = { "statusline" } })
	end,
})
