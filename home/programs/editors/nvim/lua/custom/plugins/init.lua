local Path = require("plenary.path")
local workspacePaths = {
	{ name = "personal", path = "/home/romek/notes/personal" },
	{ name = "work", path = "/home/romek/notes/work" },
}
local workspaces = {}
for _, workspaceInfo in ipairs(workspacePaths) do
	local workspacePath = workspaceInfo.path
	if Path:new(workspacePath):exists() then
		table.insert(workspaces, { name = workspaceInfo.name, path = workspacePath })
	end
end

return {
	-- Use `opts = {}` to automatically pass options to a plugin's `setup()` function, forcing the plugin to be loaded.

	-- Alternatively, use `config = function() ... end` for full control over the configuration.
	-- If you prefer to call `setup` explicitly, use:
	--    {
	--        'lewis6991/gitsigns.nvim',
	--        config = function()
	--            require('gitsigns').setup({
	--                -- Your gitsigns configuration here
	--            })
	--        end,
	--    }
	--
	-- Here is a more advanced example where we pass configuration
	-- options to `gitsigns.nvim`.
	--
	-- See `:help gitsigns` to understand what the configuration keys do
	{ -- Adds git related signs to the gutter, as well as utilities for managing changes
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
		},
	},

	-- NOTE: Plugins can also be configured to run Lua code when they are loaded.
	--
	-- This is often very useful to both group configuration, as well as handle
	-- lazy loading plugins that don't need to be loaded immediately at startup.
	--
	-- For example, in the following configuration, we use:
	--  event = 'VimEnter'
	--
	-- which loads which-key before all the UI elements are loaded. Events can be
	-- normal autocommands events (`:help autocmd-events`).
	--
	-- Then, because we use the `opts` key (recommended), the configuration runs
	-- after the plugin has been loaded as `require(MODULE).setup(opts)`.

	{ -- Useful plugin to show you pending keybinds.
		"folke/which-key.nvim",
		event = "VimEnter", -- Sets the loading event to 'VimEnter'
		opts = {
			delay = 250,
			icons = {
				mappings = false,
				keys = {},
				group = "",
				separator = "", -- symbol used between a key and it's label
			},

			preset = "helix",
			spec = {
				{ "<leader>f", group = "[f]ind" },
				{ "<leader>fc", group = "[c]urrent" },
				{ "<leader>ld", group = "[d]iagnostics" },
				{ "<leader>t", group = "[t]oggle" },
				{ "<leader>g", group = "[g]it", mode = { "n", "v" } },
				{ "<leader>b", group = "[b]runo" },
				{ "<leader>o", group = "[o]bsidian" },
				{ "<leader>l", group = "[l]sp" },
				{ "<leader>n", group = "[n]vim" },
			},
		},
	},

	-- NOTE: Plugins can specify dependencies.
	--
	-- The dependencies are proper plugin specifications as well - anything
	-- you do for a plugin at the top level, you can do for a dependency.
	--
	-- Use the `dependencies` key to specify the dependencies of a particular plugin

	{ -- Fuzzy Finder (files, lsp, etc)
		"nvim-telescope/telescope.nvim",
		event = "VimEnter",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ -- If encountering errors, see telescope-fzf-native README for installation instructions
				"nvim-telescope/telescope-fzf-native.nvim",

				-- `build` is used to run some command when the plugin is installed/updated.
				-- This is only run then, not every time Neovim starts up.
				build = "make",

				-- `cond` is a condition used to determine whether this plugin should be
				-- installed and loaded.
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
			{ "nvim-telescope/telescope-ui-select.nvim" },

			-- Useful for getting pretty icons, but requires a Nerd Font.
			{ "nvim-tree/nvim-web-devicons", enabled = true },
		},
		config = function()
			-- Telescope is a fuzzy finder that comes with a lot of different things that
			-- it can fuzzy find! It's more than just a "file finder", it can search
			-- many different aspects of Neovim, your workspace, LSP, and more!
			--
			-- The easiest way to use Telescope, is to start by doing something like:
			--  :Telescope help_tags
			--
			-- After running this command, a window will open up and you're able to
			-- type in the prompt window. You'll see a list of `help_tags` options and
			-- a corresponding preview of the help.
			--
			-- Two important keymaps to use while in Telescope are:
			--  - Insert mode: <c-/>
			--  - Normal mode: ?
			--
			-- This opens a window that shows you all of the keymaps for the current
			-- Telescope picker. This is really useful to discover what Telescope can
			-- do as well as how to actually do it!

			-- [[ Configure Telescope ]]
			-- See `:help telescope` and `:help telescope.setup()`
			require("telescope").setup({
				-- You can put your default mappings / updates / etc. in here
				--  All the info you're looking for is in `:help telescope.setup()`
				--
				-- defaults = {
				--   mappings = {
				--     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
				--   },
				-- },
				-- pickers = {}
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
				},
			})

			-- Enable Telescope extensions if they are installed
			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")
		end,
	},
	-- LSP Plugins
	{
		{
			"folke/lazydev.nvim",
			ft = "lua", -- only load on lua files
			opts = {
				library = {
					-- See the configuration section for more details
					-- Load luvit types when the `vim.uv` word is found
					{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
				},
			},
		},
		{ -- optional cmp completion source for require statements and module annotations
			"hrsh7th/nvim-cmp",
			dependencies = {
				"hrsh7th/cmp-buffer",
				"hrsh7th/cmp-path",
				"hrsh7th/cmp-nvim-lsp",
				"hrsh7th/cmp-nvim-lsp-document-symbol",
				"hrsh7th/cmp-nvim-lsp-signature-help",
				"L3MON4D3/LuaSnip",
				"saadparwaiz1/cmp_luasnip",
				"ray-x/cmp-sql",
			},

			config = function()
				local cmp = require("cmp")
				local luasnip = require("luasnip")
				cmp.setup({
					sources = {
						{ group_index = 0, name = "lazydev" },
						{ name = "nvim_lsp" },
						{ name = "nvim_lsp_document_symbol" },
						{ name = "nvim_lsp_signature_help" },
						{ name = "luasnip" },
						{ name = "path" },
						{ name = "nvim_lsp_signature_help" },
						{ name = "cmp-nvim-lsp" },
						{ name = "sql" },
						{ name = "obsidian.nvim" },
						{ name = "buffer" },
					},
					mapping = {
						["<CR>"] = cmp.mapping.confirm({ select = true }),

						-- Select next/previous item
						-- Smart Tab: completion selection or snippet jump
						["<Tab>"] = cmp.mapping(function(fallback)
							if cmp.visible() then
								cmp.select_next_item()
							elseif luasnip.expand_or_locally_jumpable() then
								luasnip.expand_or_jump()
							else
								fallback()
							end
						end, { "i", "s" }),

						-- Smart S-Tab: completion selection or snippet jump back
						["<S-Tab>"] = cmp.mapping(function(fallback)
							if cmp.visible() then
								cmp.select_prev_item()
							elseif luasnip.locally_jumpable(-1) then
								luasnip.jump(-1)
							else
								fallback()
							end
						end, { "i", "s" }),
						["<Down>"] = cmp.mapping.select_next_item(),
						["<Up>"] = cmp.mapping.select_prev_item(),

						-- Scroll documentation
						["<C-b>"] = cmp.mapping.scroll_docs(-4),
						["<C-f>"] = cmp.mapping.scroll_docs(4),

						-- Accept completion
						["<C-y>"] = cmp.mapping.confirm({ select = true }),

						-- Manual trigger
						["<C-Space>"] = cmp.mapping.complete({}),
					},
					snippet = {
						expand = function(args)
							require("luasnip").lsp_expand(args.body)
						end,
					},
				})
			end,
		},
		-- TODO: Maybe switch to blink.cmp someday
		--{ -- optional blink completion source for require statements and module annotations
		--	"saghen/blink.cmp",
		--	opts = {
		--		sources = {
		--			-- add lazydev to your completion providers
		--			default = { "lazydev", "lsp", "path", "snippets", "buffer" },
		--			providers = {
		--				lazydev = {
		--					name = "LazyDev",
		--					module = "lazydev.integrations.blink",
		--					-- make lazydev completions top priority (see `:h blink.cmp`)
		--					score_offset = 100,
		--				},
		--			},
		--		},
		--	},
		--},
	},

	-- Main LSP Configuration
	{
		"dundalek/lazy-lsp.nvim",
		dependencies = {
			"neovim/nvim-lspconfig",
			{ "VonHeikemen/lsp-zero.nvim", branch = "v3.x" },
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/nvim-cmp",
			"L3MON4D3/LuaSnip",
		},
		config = function()
			local lsp_zero = require("lsp-zero")
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			lsp_zero.on_attach(function(client, bufnr)
				lsp_zero.default_keymaps({
					buffer = bufnr,
					preserve_mappings = false,
				})
			end)

			require("lazy-lsp").setup({
				preferred_servers = {
					-- github.com/phpactor/phpactor/issues/807
					-- github.com/phpactor/phpactor/issues/2420
					-- php = { "phpactor" },
					php = { "intelephense" },
					nix = { "nixd" },
				},
				use_vim_lsp_config = true,
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			-- Useful status updates for LSP.
			{ "j-hui/fidget.nvim", opts = {} },
		},
		config = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc, mode)
						mode = mode or "n"
						vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = desc })
					end

					map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

					-- Fuzzy find all the symbols in your current document.
					--  Symbols are things like variables, functions, types, etc.
					map("gO", require("telescope.builtin").lsp_document_symbols, "Open Document Symbols")

					-- Fuzzy find all the symbols in your current workspace.
					--  Similar to document symbols, except searches over your entire project.
					map("gW", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Open Workspace Symbols")

					-- Jump to the type of the word under your cursor.
					--  Useful when you're not sure what type a variable is and you want to see
					--  the definition of its *type*, not where it was *defined*.
					map("grt", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype Definition")

					-- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
					---@param client vim.lsp.Client
					---@param method vim.lsp.protocol.Method
					---@param bufnr? integer some lsp support methods only in specific files
					---@return boolean
					local function client_supports_method(client, method, bufnr)
						if vim.fn.has("nvim-0.11") == 1 then
							return client:supports_method(method, bufnr)
						else
							return client.supports_method(method, { bufnr = bufnr })
						end
					end

					-- The following two autocommands are used to highlight references of the
					-- word under your cursor when your cursor rests there for a little while.
					--    See `:help CursorHold` for information about when this is executed
					--
					-- When you move your cursor, the highlights will be cleared (the second autocommand).
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if
						client
						and client_supports_method(
							client,
							vim.lsp.protocol.Methods.textDocument_documentHighlight,
							event.buf
						)
					then
						local highlight_augroup =
							vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.document_highlight,
						})

						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						})

						vim.api.nvim_create_autocmd("LspDetach", {
							group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
							callback = function(event2)
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
							end,
						})
					end

					-- The following code creates a keymap to toggle inlay hints in your
					-- code, if the language server you are using supports them
					--
					-- This may be unwanted, since they displace some of your code
					if
						client
						and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf)
					then
						map("<leader>ti", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
						end, "[i]nlay hints")
					end
				end,
			})

			-- Diagnostic Config
			-- See :help vim.diagnostic.Opts
			-- Toggle states
			local show_errors = true
			local show_others = true -- warn, info, hint

			-- Function to update diagnostic config
			local function update_diagnostics()
				local severities = {}

				if show_errors then
					table.insert(severities, vim.diagnostic.severity.ERROR)
				end

				if show_others then
					table.insert(severities, vim.diagnostic.severity.WARN)
					table.insert(severities, vim.diagnostic.severity.INFO)
					table.insert(severities, vim.diagnostic.severity.HINT)
				end

				vim.diagnostic.config({
					severity_sort = true,
					float = { border = "rounded", source = "if_many" },
					underline = { severity = vim.diagnostic.severity.ERROR },
					signs = {
						text = {
							[vim.diagnostic.severity.ERROR] = "󰅚 ",
							[vim.diagnostic.severity.WARN] = "󰀪 ",
							[vim.diagnostic.severity.INFO] = "󰋽 ",
							[vim.diagnostic.severity.HINT] = "󰌶 ",
						},
					},
					virtual_text = #severities > 0 and {
						source = "if_many",
						spacing = 2,
						severity = severities,
						format = function(diagnostic)
							return diagnostic.message
						end,
					} or false,
				})
			end

			-- Toggle functions
			function ToggleErrorDiagnostics()
				show_errors = not show_errors
				update_diagnostics()
				print("Error diagnostics: " .. (show_errors and "ON" or "OFF"))
			end

			function ToggleOtherDiagnostics()
				show_others = not show_others
				update_diagnostics()
				print("Other diagnostics: " .. (show_others and "ON" or "OFF"))
			end

			-- Keymaps
			vim.keymap.set("n", "<leader>te", ToggleErrorDiagnostics, { desc = "[e]rror diagnostics" })
			vim.keymap.set("n", "<leader>to", ToggleOtherDiagnostics, { desc = "[o]ther diagnostics" })

			-- Initial setup
			update_diagnostics()

			-- LSP servers and clients are able to communicate to each other what features they support.
			--  By default, Neovim doesn't support everything that is in the LSP specification.
			--  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
			--  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.

			-- Enable the following language servers
			--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
			--
			--  Add any additional override configuration in the following tables. Available keys are:
			--  - cmd (table): Override the default command used to start the server
			--  - filetypes (table): Override the default list of associated filetypes for the server
			--  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
			--  - settings (table): Override the default settings passed when initializing the server.
			--        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
			local servers = {
				-- clangd = {},
				-- gopls = {},
				-- pyright = {},
				-- rust_analyzer = {},
				-- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
				--
				-- Some languages (like typescript) have entire language plugins that can be useful:
				--    https://github.com/pmizio/typescript-tools.nvim
				--
				-- But for many setups, the LSP (`ts_ls`) will work just fine
				-- ts_ls = {},
				--

				lua_ls = {
					settings = {
						Lua = {
							completion = {
								callSnippet = "Replace",
							},
							-- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
							-- diagnostics = { disable = { 'missing-fields' } },
						},
					},
				},
			}
		end,
	},

	{ -- Autoformat
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {},
		opts = {
			notify_on_error = false,
			--format_on_save = function(bufnr)
			-- Disable "format_on_save lsp_fallback" for languages that don't
			-- have a well standardized coding style. You can add additional
			-- languages here or re-enable it for the disabled ones.
			--	local disable_filetypes = { c = true, cpp = true }
			--	if disable_filetypes[vim.bo[bufnr].filetype] then
			--		return nil
			--	else
			--		return {
			--			timeout_ms = 500,
			--			lsp_format = "fallback",
			--		}
			--	end
			--	end,
			format_after_save = function(bufnr)
				if vim.g.disable_autoformat then
					return nil
				end
				-- Disable "format_on_save lsp_fallback" for languages that don't
				-- have a well standardized coding style. You can add additional
				-- languages here or re-enable it for the disabled ones.
				local disable_filetypes = { c = true, cpp = true }
				if disable_filetypes[vim.bo[bufnr].filetype] then
					return nil
				else
					return {
						timeout_ms = 500,
						lsp_format = "fallback",
						async = true,
					}
				end
			end,

			formatters_by_ft = {
				bash = { "shfmt" },
				blade = { "blade-formatter", "rustywind" },
				html = { "prettierd", "rustywind" },
				javascript = { "prettierd" },
				json = { "prettierd" },
				lua = { "stylua" },
				-- github.com/obsidian-nvim/obsidian.nvim/issues/358
				-- mdformat causes weird frontmatter issue
				-- markdown = { "mdformat", "injected" },
				markdown = { "injected" },
				nix = { "nixfmt" },
				php = { "pint" },
				python = { "black", "isort" },
			},
		},
	},

	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			-- Evil lualine example
			local lualine = require("lualine")
			local conditions = {
				buffer_not_empty = function()
					return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
				end,
				hide_in_width = function()
					return vim.fn.winwidth(0) > 80
				end,
				check_git_workspace = function()
					local filepath = vim.fn.expand("%:p:h")
					local gitdir = vim.fn.finddir(".git", filepath .. ";")
					return gitdir and #gitdir > 0 and #gitdir < #filepath
				end,
			}

			-- Config
			local config = {
				options = {
					always_show_tabline = true,
					component_separators = "",
					section_separators = "",
					theme = {
						normal = { c = { fg = colors.fg, bg = colors.bg } },
						inactive = { c = { fg = colors.fg, bg = colors.bg } },
					},
				},
				sections = {
					lualine_a = {},
					lualine_b = {},
					lualine_c = {},
					lualine_y = {},
					lualine_x = {},
					lualine_z = {},
				},
				inactive_sections = {
					lualine_a = {},
					lualine_b = {},
					lualine_c = {},
					lualine_x = {},
					lualine_y = {},
					lualine_z = {},
				},
				winbar = {
					lualine_a = {
						{
							"filename",
							cond = conditions.buffer_not_empty,
							color = { fg = colors.fg },
							path = 4,
						},
					},
				},
				inactive_winbar = {
					lualine_a = {
						{
							"filename",
							cond = conditions.buffer_not_empty,
							color = { fg = colors.fg },
							path = 4,
						},
					},
				},
			}

			local function ins_left(component)
				table.insert(config.sections.lualine_c, component)
			end

			local function ins_right(component)
				table.insert(config.sections.lualine_x, component)
			end

			ins_left({
				function()
					return vim.fn.mode()
				end,
				color = function()
					local mode_color = {
						n = colors.fg,
						i = colors.blue,
						v = colors.green,
						[""] = colors.blue,
						V = colors.blue,
						c = colors.magenta,
						no = colors.red,
						s = colors.orange,
						S = colors.orange,
						[""] = colors.orange,
						ic = colors.yellow,
						R = colors.violet,
						Rv = colors.violet,
						cv = colors.red,
						ce = colors.red,
						r = colors.cyan,
						rm = colors.cyan,
						["r?"] = colors.cyan,
						["!"] = colors.red,
						t = colors.red,
					}
					return { fg = mode_color[vim.fn.mode()] }
				end,
				padding = { right = 1 },
			})

			ins_left({
				"filename",
				cond = conditions.buffer_not_empty,
				color = { fg = colors.blue },
			})

			ins_left({
				"location",
				icon = "",
				color = { fg = colors.fg },
			})

			ins_left({
				"branch",
				icon = "",
				color = { fg = colors.fg },
			})

			ins_left({
				function()
					local msg = ""
					local buf_ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })
					local clients = vim.lsp.get_clients()
					if next(clients) == nil then
						return msg
					end
					for _, client in ipairs(clients) do
						local filetypes = client.config.filetypes
						if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
							return client.name
						end
					end
					return msg
				end,
				icon = " lsp:",
				color = { fg = colors.fg },
			})

			ins_left({
				function()
					local reg = vim.fn.reg_recording()
					if reg == "" then
						return ""
					end -- not recording
					return " @" .. reg
				end,
				color = { fg = colors.fg },
			})

			ins_right({
				"diff",
				symbols = { added = " ", modified = "󰝤 ", removed = " " },
				diff_color = {
					added = { fg = colors.green },
					modified = { fg = colors.orange },
					removed = { fg = colors.red },
				},
				cond = conditions.hide_in_width,
			})

			ins_right({
				"diagnostics",
				sources = { "nvim_diagnostic" },
				symbols = { error = " ", warn = " ", info = " " },
				diagnostics_color = {
					error = { fg = colors.red },
					warn = { fg = colors.yellow },
					info = { fg = colors.cyan },
				},
			})
			lualine.setup(config)
		end,
	},
	{
		"obsidian-nvim/obsidian.nvim",
		version = "*",
		opts = {
			workspaces = workspaces,
			legacy_commands = false,
			-- ui = { enable = false },
			-- disable_frontmatter = true,
		},
		lazy = false,
		ft = "markdown",
		dependencies = { "nvim-lua/plenary.nvim" },
	},
	{
		"goolord/alpha-nvim",
		event = "VimEnter",
		-- Cool random ascii art, might be interesting if you want a different header.
		-- dependencies = {
		-- 	"nhattVim/alpha-ascii.nvim",
		-- 	opts = { header = "random" },
		-- },
		config = function()
			local alpha = require("alpha")
			local dashboard = require("alpha.themes.dashboard")

			dashboard.section.buttons.val = {
				dashboard.button("SPC", "Get shit done.", ""),
			}

			-- Font: ANSI Shadow
			-- dashboard.section.header.val = {
			-- 	[[██████╗  ██████╗ ███╗   ███╗███████╗██╗  ██╗    ██████╗ ██████╗ ██████╗ ███████╗███████╗]],
			-- 	[[██╔══██╗██╔═══██╗████╗ ████║██╔════╝██║ ██╔╝   ██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔════╝]],
			-- 	[[██████╔╝██║   ██║██╔████╔██║█████╗  █████╔╝    ██║     ██║   ██║██║  ██║█████╗  ███████╗]],
			-- 	[[██╔══██╗██║   ██║██║╚██╔╝██║██╔══╝  ██╔═██╗    ██║     ██║   ██║██║  ██║██╔══╝  ╚════██║]],
			-- 	[[██║  ██║╚██████╔╝██║ ╚═╝ ██║███████╗██║  ██╗██╗╚██████╗╚██████╔╝██████╔╝███████╗███████║]],
			-- 	[[╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝╚══════╝]],
			-- }

			-- # From: https://github.com/Chick2D/neofetch-themes/
			dashboard.section.header.val = {
				"███╗   ██╗██╗   ██╗██╗███╗   ███╗",
				"████╗  ██║██║   ██║██║████╗ ████║",
				"██╔██╗ ██║██║   ██║██║██╔████╔██║",
				"██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║",
				"██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║",
				"╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝",
				"",
				" ⣇⣿⠘⣿⣿⣿⡿⡿⣟⣟⢟⢟⢝⠵⡝⣿⡿⢂⣼⣿⣷⣌⠩⡫⡻⣝⠹⢿⣿⣿⣿",
				" ⡆⣿⣆⠱⣝⡵⣝⢅⠙⣿⢕⢕⢕⢕⢝⣥⢒⠅⣿⣿⣿⡿⣳⣌⠪⡪⣡⢑⢝⢝⣿",
				" ⡆⣿⣿⣦⠹⣳⣳⣕⢅⠈⢗⢕⢕⢕⢕⢕⢈⢆⠟⠋⠉⠁⠉⠉⠁⠈⠼⢐⢕⢕⢽",
				" ⡗⢰⣶⣶⣦⣝⢝⢕⢕⠅⡆⢕⢕⢕⢕⢕⣴⠏⣠⡶⠛⡉⡉⡛⢶⣦⡀⠐⣕⣕⢕",
				" ⡝⡄⢻⢟⣿⣿⣷⣕⣕⣅⣿⣔⣕⣵⣵⣿⣿⢠⣿⢠⣮⡈⣌⠨⠅⠹⣷⡀⢱⢕⢕",
				" ⡝⡵⠟⠈⢀⣀⣀⡀⠉⢿⣿⣿⣿⣿⣿⣿⣿⣼⣿⢈⡋⠴⢿⡟⣡⡇⣿⡇⡀⢕⢕",
				" ⡝⠁⣠⣾⠟⡉⡉⡉⠻⣦⣻⣿⣿⣿⣿⣿⣿⣿⣿⣧⠸⣿⣦⣥⣿⡇⡿⣰⢗⢄⢄",
				" ⠁⢰⣿⡏⣴⣌⠈⣌⠡⠈⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣬⣉⣉⣁⣄⢖⢕⢕⢕⢕",
				" ⡀⢻⣿⡇⢙⠁⠴⢿⡟⣡⡆⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣵⣵⣿⣿",
				" ⡻⣄⣻⣿⣌⠘⢿⣷⣥⣿⠇⣿⣿⣿⣿⣿⣿⠛⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
				" ⣷⢄⠻⣿⣟⠿⠦⠍⠉⣡⣾⣿⣿⣿⣿⣿⣿⢸⣿⣦⠙⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟",
				" ⡕⡑⣑⣈⣻⢗⢟⢞⢝⣻⣿⣿⣿⣿⣿⣿⣿⠸⣿⠿⠃⣿⣿⣿⣿⣿⣿⣿⡿⠁⣠",
				" ⡝⡵⡈⢟⢕⢕⢕⢕⣵⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣿⣿⣿⣿⣿⣿⠿⠋⣀⣈⠙",
				" ⡝⡵⡕⡀⠑⠳⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⢉⡠⡲⡫⡪⡪⡣",
			}

			vim.api.nvim_create_autocmd("User", {
				once = true,
				pattern = "LazyVimStarted",
				callback = function()
					local stats = require("lazy").stats()
					local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
					dashboard.section.footer.val = {
						" ",
						" Loaded " .. stats.loaded .. "/" .. stats.count .. " plugins  in " .. ms .. " ms ",
					}
					pcall(vim.cmd.AlphaRedraw)
				end,
			})

			alpha.setup(dashboard.opts)
		end,
	},
	{
		url = "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
		config = function()
			require("lsp_lines").setup()
		end,
	},
	{
		"danymat/neogen",
		config = true,
		version = "*",
	},
	{
		-- For development
		-- dir = "~/Workspace/bruno.nvim",
		"romek-codes/bruno.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			-- "ibhagwan/fzf-lua",
			-- {
			-- 	"folke/snacks.nvim",
			-- 	opts = { picker = { enabled = true } },
			-- },
		},
		config = function()
			require("bruno").setup({
				collection_paths = {
					{ name = "Nix", path = "/home/romek/Bruno" },
					{ name = "Nix-work", path = "/home/romek/notes/work/Bruno" },
				},
				-- picker = "fzf-lua",
			})
		end,
	},
	{
		"stevearc/oil.nvim",
		opts = {},
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("oil").setup()
		end,
	},
	{ "brenoprata10/nvim-highlight-colors" },
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		opts = {},
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
		config = function()
			require("noice").setup({
				lsp = {
					override = {
						["vim.lsp.util.convert_input_to_markdown_lines"] = true,
						["vim.lsp.util.stylize_markdown"] = true,
						["cmp.entry.get_documentation"] = true,
					},
				},
				presets = {
					bottom_search = true, -- use a classic bottom cmdline for search
					long_message_to_split = true, -- long messages will be sent to a split
					inc_rename = false, -- enables an input dialog for inc-rename.nvim
					lsp_doc_border = false, -- add a border to hover docs and signature help
				},
			})
		end,
		keys = {
			{
				"<leader>nn",
				"<cmd>Noice history<cr>",
				desc = "[n]otifications",
			},
			{
				"<leader>ne",
				"<cmd>Noice errors<cr>",
				desc = "[e]rrors",
			},
		},
	},
	{ "nvim-lua/plenary.nvim" },
	{ "nvim-pack/nvim-spectre" },
	{
		"echasnovski/mini.files",
		config = function()
			require("mini.files").setup()
		end,
	},
	{
		"nvim-telescope/telescope-live-grep-args.nvim",
		config = function()
			local telescope = require("telescope")
			local lga_actions = require("telescope-live-grep-args.actions")
			telescope.setup({
				extensions = {
					live_grep_args = {
						auto_quoting = true,
						mappings = {
							i = {
								["<C-k>"] = lga_actions.quote_prompt(),
								["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
								-- freeze the current list and start a fuzzy search in the frozen list
								["<C-f>"] = lga_actions.to_fuzzy_refine,
							},
						},
					},
				},
			})
		end,
	},
	{
		"andymass/vim-matchup",
		setup = function()
			vim.g.matchup_matchparen_offscreen = { method = "popup" }
		end,
	},
	{
		"sphamba/smear-cursor.nvim",
		opts = {},
	},
	{
		"karb94/neoscroll.nvim",
		opts = {},
	},
	{
		"adalessa/laravel.nvim",
		dependencies = {
			"tpope/vim-dotenv",
			"nvim-telescope/telescope.nvim",
			"MunifTanjim/nui.nvim",
			"kevinhwang91/promise-async",
		},
		cmd = { "Laravel" },
		keys = {
			{
				"<leader>L",
				function()
					Laravel.pickers.laravel()
				end,
				desc = "[L]aravel",
			},
		},
		event = "VeryLazy",
		opts = {},
		config = true,
	},
	{
		"kdheepak/lazygit.nvim",
		lazy = true,
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		keys = {
			{ "<leader>gg", "<cmd>LazyGit<cr>", desc = "lazy[g]it" },
		},
	},
	{
		"folke/trouble.nvim",
		opts = {}, -- for default options, refer to the configuration section for custom setup.
		cmd = "Trouble",
		keys = {

			{
				"<leader>lq",
				"<cmd>Trouble qflist toggle<cr>",
				desc = "[q]uickfix",
			},
			{
				"<leader>lda",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "[a]ll",
			},
			{
				"<leader>ldc",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "[c]urrent",
			},
			--{
			--	"<leader>cs",
			--	"<cmd>Trouble symbols toggle focus=false<cr>",
			--	desc = "Symbols (Trouble)",
			--},
			--{
			--	"<leader>cl",
			--	"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
			--	desc = "LSP Definitions / references / ... (Trouble)",
			--},
			--{
			--	"<leader>xL",
			--	"<cmd>Trouble loclist toggle<cr>",
			--	desc = "Location List (Trouble)",
			--},
		},
	},
	{ "akinsho/toggleterm.nvim", version = "*", config = true },
	{
		"dmtrKovalenko/fff.nvim",
		build = "nix run .#release",
		opts = {},
		keys = {
			{
				"<leader>ff",
				function()
					require("fff").find_files() -- or find_in_git_root() if you only want git files
				end,
				desc = "[f]ile",
			},
		},
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},
	{ -- Add indentation guides even on blank lines
		"lukas-reineke/indent-blankline.nvim",
		-- Enable `lukas-reineke/indent-blankline.nvim`
		-- See `:help ibl`
		main = "ibl",
		config = function()
			require("ibl").setup({
				whitespace = {
					highlight = highlight,
					remove_blankline_trail = false,
				},
				scope = { enabled = true },
			})
		end,
	},
	{ "NMAC427/guess-indent.nvim" }, -- Detect tabstop and shiftwidth automatically

	-- Highlight todo, notes, etc in comments
	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},

	{ -- Collection of various small independent plugins/modules
		"echasnovski/mini.nvim",
		config = function()
			-- Better Around/Inside textobjects
			--
			-- Examples:
			--  - va)  - [V]isually select [A]round [)]paren
			--  - yinq - [Y]ank [I]nside [N]ext [Q]uote
			--  - ci'  - [C]hange [I]nside [']quote
			require("mini.ai").setup({ n_lines = 500 })

			-- Add/delete/replace surroundings (brackets, quotes, etc.)
			--
			-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
			-- - sd'   - [S]urround [D]elete [']quotes
			-- - sr)'  - [S]urround [R]eplace [)] [']
			require("mini.surround").setup()
		end,
	},
	{ -- Highlight, edit, and navigate code
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		main = "nvim-treesitter.configs", -- Sets main module to use for opts
		-- [[ Configure Treesitter ]] See `:help nvim-treesitter`
		opts = {
			highlight = {
				enable = true,
				-- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
				--  If you are experiencing weird indenting issues, add the language to
				--  the list of additional_vim_regex_highlighting and disabled languages for indent.
				additional_vim_regex_highlighting = { "ruby" },
			},
			indent = { enable = true, disable = { "ruby" } },
		},
		-- There are additional nvim-treesitter modules that you can use to interact
		-- with nvim-treesitter. You should go explore a few and see what interests you:
		--
		--    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
		--    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
		--    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
	},
	-- {
	-- 	"m4xshen/hardtime.nvim",
	-- 	lazy = false,
	-- 	dependencies = { "MunifTanjim/nui.nvim" },
	-- 	opts = {},
	-- },
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		---@type Flash.Config
		opts = {},
	    -- stylua: ignore
	    keys = {
	      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
	      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
	      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
	      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
	      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
	      { "<leader>j", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "[j]ump" },
	      { "<leader>s", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "[s]elect (treesitter)" },
	    },
	},
	{
		"vyfor/cord.nvim",
		build = ":Cord update",
		-- opts = {}
	},
	{
		"tpope/vim-eunuch",
	},
	{
		"nvim-neotest/nvim-nio",
		lazy = true,
	},
	-- require 'kickstart.plugins.debug',
	-- require 'kickstart.plugins.lint',
}
