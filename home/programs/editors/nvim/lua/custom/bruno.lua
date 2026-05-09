local M = {}

local bruno_dev_dir = vim.env.BRUNO_NVIM_DEV_DIR

local function bruno_collections_available()
	local ok, cols = pcall(require, "bruno-collections")
	return ok and #cols > 0
end

local function bruno_collection_paths()
	local ok, cols = pcall(require, "bruno-collections")
	return ok and cols or {}
end

function M.spec(source)
	local spec = {
		cond = bruno_collections_available,
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
				collection_paths = bruno_collection_paths(),
				-- picker = "fzf-lua",
			})
		end,
	}

	if bruno_dev_dir ~= nil and bruno_dev_dir ~= "" then
		spec.dir = bruno_dev_dir
		spec.name = "bruno.nvim"
	else
		spec[1] = source
	end

	return spec
end

return M
