require('gitsigns').setup {
  signs = {
    add          = { text = '┃' },
    change       = { text = '┃' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  signs_staged = {
    add          = { text = '┃' },
    change       = { text = '┃' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  signs_staged_enable = true,
  signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
  numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
  linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
  word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
  watch_gitdir = {
    follow_files = true
  },
  auto_attach = true,
  attach_to_untracked = false,
  current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
    delay = 1000,
    ignore_whitespace = false,
    virt_text_priority = 100,
  },
  current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
  sign_priority = 6,
  update_debounce = 100,
  status_formatter = nil, -- Use default
  max_file_length = 40000, -- Disable if file is longer than this (in lines)
  preview_config = {
    -- Options passed to nvim_open_win
    border = 'single',
    style = 'minimal',
    relative = 'cursor',
    row = 0,
    col = 1
  },
}

-- Hunk navigation and review (accept/reject changes hunk by hunk).
-- <leader>g* is used because <leader>h toggles hlsearch.
local gs = require("gitsigns")
local map = vim.keymap.set
map("n", "]c", function()
	if vim.wo.diff then
		vim.cmd.normal({ "]c", bang = true })
	else
		gs.nav_hunk("next")
	end
end, { desc = "Next hunk" })
map("n", "[c", function()
	if vim.wo.diff then
		vim.cmd.normal({ "[c", bang = true })
	else
		gs.nav_hunk("prev")
	end
end, { desc = "Previous hunk" })
map("n", "<leader>gp", gs.preview_hunk, { desc = "Preview hunk" })
map("n", "<leader>gs", gs.stage_hunk, { desc = "Stage hunk (toggle)" })
map("n", "<leader>gr", gs.reset_hunk, { desc = "Reset hunk" })
map("x", "<leader>gs", function()
	gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
end, { desc = "Stage selected lines" })
map("x", "<leader>gr", function()
	gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
end, { desc = "Reset selected lines" })
map("n", "<leader>gS", gs.stage_buffer, { desc = "Stage buffer" })
map("n", "<leader>gR", gs.reset_buffer, { desc = "Reset buffer" })
map("n", "<leader>gb", function()
	gs.blame_line({ full = true })
end, { desc = "Blame line" })
map("n", "<leader>gq", function()
	gs.setqflist("all")
end, { desc = "All hunks to quickfix" })
map({ "o", "x" }, "ih", gs.select_hunk, { desc = "Select hunk" })
