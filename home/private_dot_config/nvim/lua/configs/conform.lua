-- Formatting via conform.nvim (replaces none-ls / mason-null-ls).
-- Formatters are looked up on PATH (Mason bin is prepended). Missing
-- formatters are skipped; LSP formatting is used as a fallback.
local conform = require("conform")

conform.setup({
	formatters_by_ft = {
		lua = { "stylua" },
		json = { "jq" },
		jsonc = { "jq" },
		rust = { "rustfmt" },
		python = { "ruff_format", "black", stop_after_first = true },
		c = { "clang_format" },
		cpp = { "clang_format" },
	},
	default_format_opts = {
		lsp_format = "fallback",
	},
	-- Opt-in: does not reformat files on save unless enabled
	-- (globally with :FormatOnSaveToggle, or per buffer with :FormatOnSaveToggle!).
	format_on_save = function(bufnr)
		local enabled = vim.b[bufnr].format_on_save
		if enabled == nil then
			enabled = vim.g.format_on_save
		end
		if not enabled then
			return
		end
		return { timeout_ms = 1000 }
	end,
})

vim.api.nvim_create_user_command("Format", function(args)
	local range = nil
	if args.count ~= -1 then
		local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
		range = {
			start = { args.line1, 0 },
			["end"] = { args.line2, end_line:len() },
		}
	end
	conform.format({ async = true, range = range })
end, { range = true, desc = "Format buffer or range" })

vim.api.nvim_create_user_command("FormatOnSaveToggle", function(args)
	if args.bang then
		local cur = vim.b.format_on_save
		if cur == nil then
			cur = vim.g.format_on_save
		end
		vim.b.format_on_save = not cur
		vim.notify("Format on save (buffer): " .. tostring(vim.b.format_on_save))
	else
		vim.g.format_on_save = not vim.g.format_on_save
		vim.notify("Format on save (global): " .. tostring(vim.g.format_on_save))
	end
end, { bang = true, desc = "Toggle format on save (! = current buffer)" })
