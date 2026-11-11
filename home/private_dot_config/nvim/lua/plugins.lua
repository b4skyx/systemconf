-- Plugin specs (lazy.nvim). Plugin configs live in lua/configs/*.lua.
return {
	-- ======================================================================
	-- UI
	-- ======================================================================
	-- Colorscheme: only the one picked in settings.lua (nord on WSL) is loaded.
	{
		"sainnhe/gruvbox-material",
		cond = vim.g.user_colorscheme == "gruvbox-material",
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("gruvbox-material")
		end,
	},
	{
		"shaunsingh/nord.nvim",
		cond = vim.g.user_colorscheme == "nord",
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("nord")
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("configs.lualine")
		end,
	},
	{ "nvim-tree/nvim-web-devicons", lazy = true },
	{
		"nvim-tree/nvim-tree.lua",
		config = function()
			require("configs.nvimtree")
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		event = { "BufReadPost", "BufNewFile" },
		opts = {},
	},

	-- ======================================================================
	-- Editor
	-- ======================================================================
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},
	{
		"numToStr/Comment.nvim",
		event = { "BufReadPost", "BufNewFile" },
		opts = {},
	},
	{
		"mbbill/undotree",
		cmd = "UndotreeToggle",
		keys = { { "<F5>", "<cmd>UndotreeToggle<CR>", desc = "Undotree" } },
	},
	-- Big-file / fast-macro guard (replaces plugin/bigfile.vim)
	{ "pteroctopus/faster.nvim" },
	{
		"danymat/neogen",
		dependencies = "nvim-treesitter/nvim-treesitter",
		cmd = "Neogen",
		opts = { snippet_engine = "luasnip" },
	},
	{
		-- `main` branch: full rewrite for Neovim 0.12 (master is frozen).
		-- Requires the tree-sitter CLI (cargo install --locked tree-sitter-cli).
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			require("configs.treesitter")
		end,
	},

	-- ======================================================================
	-- Completion
	-- ======================================================================
	{
		"saghen/blink.cmp",
		version = "1.*",
		-- not lazy: its plugin/ file registers LSP capabilities via vim.lsp.config("*")
		-- before servers start; blink lazy-loads its internals itself.
		lazy = false,
		dependencies = { "L3MON4D3/LuaSnip" },
		opts_extend = { "sources.default" },
		config = function()
			require("configs.completions")
		end,
	},
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*",
		build = "make install_jsregexp",
		dependencies = { "rafamadriz/friendly-snippets" },
		config = function()
			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},

	-- ======================================================================
	-- LSP & formatting
	-- ======================================================================
	{
		"mason-org/mason.nvim",
		lazy = false,
		opts = { PATH = "prepend" },
	},
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		dependencies = { "mason-org/mason.nvim" },
		config = function()
			require("configs.lsp")
		end,
	},
	{
		"nvimdev/lspsaga.nvim",
		event = "VeryLazy",
		config = function()
			require("configs.lspsaga")
		end,
	},
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		cmd = { "ConformInfo", "Format", "FormatOnSaveToggle" },
		init = function()
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
		end,
		config = function()
			require("configs.conform")
		end,
	},

	-- ======================================================================
	-- Finder
	-- ======================================================================
	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		keys = {
			{
				"<C-p>",
				function()
					require("telescope").extensions.project.project({})
				end,
				desc = "Projects",
			},
			{ "<leader>fk", "<Cmd>Telescope keymaps<CR>", desc = "Find keymaps (Enter runs it)" },
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-project.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
		init = function()
			-- Route vim.ui.select through telescope (ui-select) on first use,
			-- without loading telescope at startup.
			---@diagnostic disable-next-line: duplicate-set-field
			vim.ui.select = function(...)
				require("lazy").load({ plugins = { "telescope.nvim" } })
				return vim.ui.select(...)
			end
		end,
		config = function()
			require("configs.telescope")
		end,
	},

	-- ======================================================================
	-- Git
	-- ======================================================================
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("configs.gitsigns")
		end,
	},
	{
		-- maintained fork of sindrets/diffview.nvim (abandoned since 2024); same commands
		"dlyongemallo/diffview-plus.nvim",
		cmd = {
			"DiffviewOpen",
			"DiffviewClose",
			"DiffviewToggleFiles",
			"DiffviewFocusFiles",
			"DiffviewFileHistory",
			"DiffviewDiffFiles",
			"DiffviewDiffDirs",
			"DiffviewRefresh",
		},
		keys = {
			{ "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Diffview: working tree changes" },
			{ "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "Diffview: file history" },
			{ "<leader>gD", "<cmd>DiffviewClose<CR>", desc = "Diffview: close" },
		},
		opts = {},
	},

	-- ======================================================================
	-- AI (all three share the Copilot login)
	--   copilot.vim     inline ghost text, <C-J> accepts (Tab stays with blink.cmp)
	--   CopilotChat     <leader>c*  (cc toggle, ce explain, cr review, cf fix, cm models)
	--   codecompanion   <leader>a*  (aa actions, ac chat toggle, ai inline prompt)
	-- ======================================================================
	{
		"github/copilot.vim",
		event = "InsertEnter",
		cmd = "Copilot",
		init = function()
			vim.g.copilot_no_tab_map = true
		end,
		config = function()
			vim.keymap.set("i", "<C-J>", 'copilot#Accept("\\<CR>")', {
				expr = true,
				replace_keycodes = false,
				desc = "Copilot accept",
			})
			-- Lazy-loaded after VimEnter/FileType already fired: run copilot.vim's
			-- startup init and attach to the buffers that are already open.
			vim.fn["copilot#Init"]()
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted and vim.bo[buf].filetype ~= "" then
					vim.api.nvim_buf_call(buf, function()
						vim.fn["copilot#OnFileType"]()
					end)
				end
			end
		end,
	},
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "github/copilot.vim" },
			{ "nvim-lua/plenary.nvim" },
		},
		build = "make tiktoken",
		cmd = {
			"CopilotChat",
			"CopilotChatOpen",
			"CopilotChatClose",
			"CopilotChatToggle",
			"CopilotChatStop",
			"CopilotChatReset",
			"CopilotChatSave",
			"CopilotChatLoad",
			"CopilotChatPrompts",
			"CopilotChatModels",
			"CopilotChatExplain",
			"CopilotChatReview",
			"CopilotChatFix",
			"CopilotChatOptimize",
			"CopilotChatDocs",
			"CopilotChatTests",
			"CopilotChatCommit",
		},
		keys = {
			{ "<leader>cc", "<cmd>CopilotChatToggle<CR>", mode = { "n", "x" }, desc = "CopilotChat toggle" },
			{ "<leader>ce", "<cmd>CopilotChatExplain<CR>", mode = { "n", "x" }, desc = "CopilotChat explain" },
			{ "<leader>cr", "<cmd>CopilotChatReview<CR>", mode = { "n", "x" }, desc = "CopilotChat review" },
			{ "<leader>cf", "<cmd>CopilotChatFix<CR>", mode = { "n", "x" }, desc = "CopilotChat fix" },
			{ "<leader>cm", "<cmd>CopilotChatModels<CR>", desc = "CopilotChat models" },
		},
		config = function()
			require("configs.copilot")
		end,
	},
	{
		"olimorris/codecompanion.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions", "CodeCompanionCmd", "CodeCompanionCLI" },
		keys = {
			{ "<leader>aa", "<cmd>CodeCompanionActions<CR>", mode = { "n", "x" }, desc = "CodeCompanion actions" },
			{ "<leader>ac", "<cmd>CodeCompanionChat Toggle<CR>", mode = { "n", "x" }, desc = "CodeCompanion chat" },
			{ "<leader>ai", ":CodeCompanion ", mode = { "n", "x" }, desc = "CodeCompanion inline prompt" },
		},
		opts = {
			interactions = {
				chat = { adapter = "copilot" },
				inline = { adapter = "copilot" },
			},
			opts = {
				log_level = "ERROR",
			},
		},
	},

	-- ======================================================================
	-- Notes
	-- ======================================================================
	-- vimwiki is configured via g: variables in init.vim (must be set before load)
	{ "vimwiki/vimwiki" },
}
