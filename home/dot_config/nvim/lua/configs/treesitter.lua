-- nvim-treesitter (main branch): parser installer + queries only.
-- Highlighting, folding and (experimental) indent are enabled per buffer below
-- using Neovim's built-in treesitter.
local ts = require("nvim-treesitter")

local ensure_installed = {
	"bash",
	"c",
	"cpp",
	"diff",
	"fish",
	"gitcommit",
	"go",
	"html",
	"json",
	"lua",
	"luadoc",
	"markdown",
	"markdown_inline",
	"python",
	"query",
	"regex",
	"rust",
	"toml",
	"vim",
	"vimdoc",
	"xml",
	"yaml",
}

-- Install missing parsers (async; no-op when everything is present)
local installed = ts.get_installed()
local missing = vim.tbl_filter(function(lang)
	return not vim.tbl_contains(installed, lang)
end, ensure_installed)
if #missing > 0 then
	ts.install(missing)
end

-- Match faster.nvim's big-file threshold (2 MB): leave those buffers alone.
local BIG_FILE = 2 * 1024 * 1024

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
	callback = function(args)
		local buf = args.buf
		local lang = vim.treesitter.language.get_lang(args.match)
		if not lang then
			return
		end

		local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
		if stat and stat.size > BIG_FILE then
			return
		end

		if not pcall(vim.treesitter.start, buf, lang) then
			return -- no parser installed for this language
		end

		-- Treesitter folds (LspAttach upgrades to LSP folds when supported)
		for _, win in ipairs(vim.fn.win_findbuf(buf)) do
			if vim.wo[win][0].foldexpr ~= "v:lua.vim.lsp.foldexpr()" then
				vim.wo[win][0].foldmethod = "expr"
				vim.wo[win][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
			end
		end

		-- Experimental treesitter indent, only where an indents query exists
		local ok, indents = pcall(vim.treesitter.query.get, lang, "indents")
		if ok and indents then
			vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end
	end,
})
