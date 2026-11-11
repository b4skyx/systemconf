-- Completion: blink.cmp (replaces nvim-cmp + cmp-* sources + lspkind + lsp_signature)
-- Keymaps mirror the previous nvim-cmp setup:
--   <Tab>/<S-Tab>  next/prev item, else snippet jump, else open menu after a word
--   <CR>           accept only an explicitly selected item
--   <C-o>          open menu, <C-e> cancel, <C-b>/<C-f> scroll docs, <C-k> signature
--   <C-J>          is left free for copilot.vim ghost-text accept
local function has_words_before()
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

require("blink.cmp").setup({
	keymap = {
		preset = "none",
		["<C-o>"] = { "show", "show_documentation", "hide_documentation" },
		["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
		["<C-e>"] = { "cancel", "fallback" },
		["<CR>"] = { "accept", "fallback" },
		["<C-y>"] = { "select_and_accept", "fallback" },
		["<Tab>"] = {
			"select_next",
			"snippet_forward",
			function(cmp)
				if has_words_before() then
					return cmp.show()
				end
			end,
			"fallback",
		},
		["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
		["<Up>"] = { "select_prev", "fallback" },
		["<Down>"] = { "select_next", "fallback" },
		["<C-p>"] = { "select_prev", "fallback_to_mappings" },
		["<C-n>"] = { "select_next", "fallback_to_mappings" },
		["<C-b>"] = { "scroll_documentation_up", "fallback" },
		["<C-f>"] = { "scroll_documentation_down", "fallback" },
		["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
	},

	appearance = { nerd_font_variant = "mono" },

	completion = {
		list = { selection = { preselect = false, auto_insert = true } },
		documentation = { auto_show = true, auto_show_delay_ms = 200 },
		menu = { border = "rounded" },
	},

	snippets = { preset = "luasnip" },

	sources = {
		default = { "lsp", "path", "snippets", "buffer" },
	},

	-- Signature help while typing (replaces lsp_signature.nvim)
	signature = { enabled = true, window = { border = "rounded" } },

	cmdline = {
		completion = { menu = { auto_show = true } },
	},

	fuzzy = { implementation = "prefer_rust_with_warning" },
})
