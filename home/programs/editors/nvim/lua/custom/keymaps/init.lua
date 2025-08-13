vim.keymap.set("n", "<leader>fR", "<cmd>Telescope oldfiles<cr>", { desc = "[R]ecent" })
vim.keymap.set("n", "<leader>fa", "<cmd>Telescope resume<cr>", { desc = "[a]gain" })
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "[b]uffers" })
vim.keymap.set("n", "<leader>fcw", "<cmd>Telescope grep_string<cr>", { desc = "[w]ord" })
-- vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "[f]ile" })
vim.keymap.set("n", "<leader>fw", "<cmd>Telescope live_grep_args<cr>", { desc = "[w]ord" })
-- vim.keymap.set("n", "<leader>fh", function()
-- 	require("telescope.builtin").find_files({ hidden = true })
-- end, { desc = "[h]idden files" })

vim.keymap.set("n", "<leader>nh", "<cmd>Telescope help_tags<cr>", { desc = "[h]elp" })
vim.keymap.set("n", "<leader>nk", "<cmd>Telescope keymaps<cr>", { desc = "[k]eymap" })
vim.keymap.set("n", "<leader>ft", "<cmd>Telescope builtin<cr>", { desc = "[t]elescope" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", {})
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })
vim.keymap.set("", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", { desc = "LSP Hover" })
vim.keymap.set("", "<C-tab>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
vim.keymap.set("", "<Up>", "<Nop>", { desc = "Disable Up Arrow" })
vim.keymap.set("", "<Down>", "<Nop>", { desc = "Disable Down Arrow" })
vim.keymap.set("", "<Left>", "<Nop>", { desc = "Disable Left Arrow" })
vim.keymap.set("", "<Right>", "<Nop>", { desc = "Disable Right Arrow" })
vim.keymap.set("", "<leader>Q", "<cmd>qa<cr>", { desc = "[Q]uit" })
vim.keymap.set("", "<leader>q", "<cmd>q<cr>", { desc = "[q]uit window" })
vim.keymap.set("", "<leader>w", "<cmd>write<cr>", { desc = "[w]rite / save" })
vim.keymap.set("n", "<leader>fcb", function()
	require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
		winblend = 10,
		previewer = false,
	}))
end, { desc = "[b]uffer" })
vim.keymap.set("", "<Leader>fr", "<cmd>Spectre<cr>", { desc = "[r]eplace" })
vim.keymap.set("", "<Leader>lg", "<cmd>Neogen<cr>", { desc = "[g]enerate" })
vim.keymap.set("", "<leader>tf", function()
	vim.g.disable_autoformat = not vim.g.disable_autoformat
	if vim.g.disable_autoformat then
		print("Auto-format disabled")
	else
		print("Auto-format enabled")
	end
end, { desc = "[f]ormat on save" })
vim.keymap.set("", "<Leader>e", "<cmd>lua MiniFiles.open()<cr>", { desc = "[e]xplorer" })
vim.keymap.set("", "<Leader>of", "<cmd>ObsidianSearch<cr>", { desc = "[f]ind" })
vim.keymap.set("", "<Leader>oo", "<cmd>ObsidianOpen<cr>", { desc = "[o]pen" })
vim.keymap.set("", "<Leader>ot", "<cmd>ObsidianTags<cr>", { desc = "[t]ags" })
vim.keymap.set("", "<Leader>on", "<cmd>ObsidianNew<cr>", { desc = "[n]ew note" })
vim.keymap.set("", "<Leader>og", "<cmd>ObsidianFollowLink<cr>", { desc = "[g]o to note" })
vim.keymap.set("", "<Leader>br", "<cmd>BrunoRun<cr>", { desc = "[r]un" })
vim.keymap.set("", "<Leader>be", "<cmd>BrunoEnv<cr>", { desc = "[e]nvironment" })
vim.keymap.set("", "<Leader>bs", "<cmd>BrunoSearch<cr>", { desc = "[s]earch" })
vim.keymap.set("n", "<Leader>tt", "<cmd>ToggleTerm direction=float<cr>", { desc = "[t]erminal" })
vim.keymap.set("n", "<Leader>tc", "<cmd>TSContext toggle<cr>", { desc = "[c]ontext (treesitter)" })
vim.keymap.set({ "n", "x" }, "<leader>lc", vim.lsp.buf.code_action, { desc = "[c]ode action", silent = false })
vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, { desc = "[r]ename", silent = false })
vim.keymap.set("n", "<leader>li", "<cmd>LspInfo<cr>", { desc = "[i]nfo", silent = false })
vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "[g]oto [D]eclaration", silent = false })
vim.keymap.set("n", "gd", require("telescope.builtin").lsp_definitions, { desc = "[g]oto [d]efinition" })
vim.keymap.set("n", "gr", require("telescope.builtin").lsp_references, { desc = "[g]oto [r]eferences" })
vim.keymap.set("n", "gI", require("telescope.builtin").lsp_implementations, { desc = "[g]oto [I]mplementation" })
vim.keymap.set("n", "<leader>lt", require("telescope.builtin").lsp_type_definitions, { desc = "[t]ype definition" })
vim.keymap.set("n", "<leader>ls", require("telescope.builtin").lsp_document_symbols, { desc = "[s]ymbols" })
vim.keymap.set(
	"n",
	"<leader>lw",
	require("telescope.builtin").lsp_dynamic_workspace_symbols,
	{ desc = "[w]orkspace symbols" }
)

vim.keymap.set({ "v", "n", "o", "x" }, "<leader>/", function()
	local count = vim.v.count
	vim.cmd.norm((count > 0 and count or "") .. "gcc")
end, { desc = "toggle comment" })

-- Make sure that '//' comments are used for php files.
vim.api.nvim_create_autocmd("FileType", {
	pattern = "php",
	callback = function()
		vim.bo.commentstring = "// %s"
	end,
})

vim.keymap.set("n", "<leader>gb", require("gitsigns").blame_line, { desc = "[b]lame line" })
vim.keymap.set("n", "<leader>gd", function()
	require("gitsigns").diffthis("@")
end, { desc = "[d]iff" })

vim.keymap.set("n", "<Leader>np", "<cmd>Lazy<cr>", { desc = "[p]lugins" })

return {}
