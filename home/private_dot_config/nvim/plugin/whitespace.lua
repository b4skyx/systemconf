-- Strip trailing whitespace on save, but only on lines you changed.
--
-- In a git repo (gitsigns attached) only added/changed lines are cleaned, so
-- saving a file written by someone else (or an agent) does not produce an
-- unrelated whitespace diff. Outside git the whole buffer is cleaned.
-- Filetypes where trailing whitespace is meaningful are skipped.

local skip_ft = {
	markdown = true,
	vimwiki = true,
	diff = true,
	patch = true,
	gitcommit = true,
	mail = true,
}

local function strip(bufnr, first, last)
	-- first/last are 1-based inclusive
	local lines = vim.api.nvim_buf_get_lines(bufnr, first - 1, last, false)
	for i, line in ipairs(lines) do
		local stripped = line:gsub("%s+$", "")
		if stripped ~= line then
			vim.api.nvim_buf_set_lines(bufnr, first + i - 2, first + i - 1, false, { stripped })
		end
	end
end

vim.api.nvim_create_autocmd("BufWritePre", {
	group = vim.api.nvim_create_augroup("StripTrailingWhitespace", { clear = true }),
	callback = function(args)
		local bufnr = args.buf
		if vim.bo[bufnr].binary or skip_ft[vim.bo[bufnr].filetype] or not vim.bo[bufnr].modifiable then
			return
		end

		local view = vim.fn.winsaveview()
		local ok, gs = pcall(require, "gitsigns")
		local hunks = ok and gs.get_hunks(bufnr) or nil

		if hunks then
			for _, h in ipairs(hunks) do
				if h.added and h.added.count > 0 then
					strip(bufnr, h.added.start, h.added.start + h.added.count - 1)
				end
			end
		else
			strip(bufnr, 1, vim.api.nvim_buf_line_count(bufnr))
		end
		vim.fn.winrestview(view)
	end,
})
