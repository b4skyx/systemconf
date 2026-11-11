-- Native LSP setup (Neovim 0.11+ vim.lsp.config / vim.lsp.enable).
--
-- Server configs come from nvim-lspconfig's lsp/*.lua plus overrides in
-- ~/.config/nvim/lsp/*.lua. Mason only installs binaries (PATH prepend).
--
-- Built-in LSP mappings (no setup needed):
--   K hover (overridden by Lspsaga), grn rename, gra code action,
--   grr references, gri implementation, grt type definition,
--   gO document symbols, [d / ]d next/prev diagnostic, <C-s> signature help (insert)

-- Completion capabilities for all servers are registered by blink.cmp
-- (its plugin/ file extends vim.lsp.config("*")).

-- Show diagnostics for the cursor line inline (replaces the CursorHold float).
vim.diagnostic.config({
	virtual_text = false,
	virtual_lines = { current_line = true },
	severity_sort = true,
	float = { border = "rounded", source = true },
})

-- Enable only servers that are actually ours: hand-written configs in
-- ~/.config/nvim/lsp/ plus a whitelist of Mason-installed servers.
-- Everything else bundled with nvim-lspconfig stays disabled.
local mason_servers = {
	pyright = true,
	rust_analyzer = true,
	lemminx = true,
}

local lsp_configs = {}
local config_lsp_dir = vim.fs.joinpath(vim.fn.stdpath("config"), "lsp")

for _, f in pairs(vim.api.nvim_get_runtime_file("lsp/*.lua", true)) do
	local server_name = vim.fn.fnamemodify(f, ":t:r")
	if
		(vim.fs.joinpath(config_lsp_dir, server_name .. ".lua") == f or mason_servers[server_name])
		and not vim.tbl_contains(lsp_configs, server_name)
	then
		table.insert(lsp_configs, server_name)
	end
end

vim.lsp.enable(lsp_configs)

-- Keymaps (personal additions on top of the built-in gr* mappings)
local map = vim.keymap.set
map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "gt", vim.lsp.buf.type_definition, { desc = "Go to type definition" })
map({ "n", "v" }, "<localleader>a", vim.lsp.buf.code_action, { desc = "Code action" })
map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })

-- Diagnostics
map("n", "<localleader>db", function()
	require("telescope.builtin").diagnostics({ bufnr = 0 })
end, { desc = "Buffer diagnostics" })
map("n", "<localleader>dw", function()
	require("telescope.builtin").diagnostics()
end, { desc = "Workspace diagnostics" })
map("n", "<localleader>dl", vim.diagnostic.open_float, { desc = "Line diagnostics" })
-- Error-only jumps ([d / ]d jump through all severities)
map("n", "[D", function()
	vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
end, { desc = "Previous error" })
map("n", "]D", function()
	vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
end, { desc = "Next error" })

-- Inlay hints toggle (native)
map("n", "<localleader>h", function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Toggle inlay hints" })

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client then
			return
		end
		-- LSP-based folding where the server supports it (falls back to indent)
		if client:supports_method("textDocument/foldingRange") then
			for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
				vim.wo[win][0].foldmethod = "expr"
				vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
			end
		end
	end,
})
