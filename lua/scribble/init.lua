local utils = require("utils")
local config = require("scribble.config")

local M = {}

---@class scribble.Config
---@field scope 'branch' | 'repo' | 'global'?
---@field storage_dir string?
---@field previewer 'bat' | 'cat'?

---@class scribble.File
---@field storage_dir string
---@field directory string
---@field path string

---@type scribble.Config
local default_config = {
	scope = "branch",
	storage_dir = "~/.local/share/scribble/storage",
	previewer = "bat",
}

---@class scribble.CreateArgs
---@field filename string

---@param args scribble.CreateArgs
function M.create(args)
	local directory = utils.get_directory(config)

	local cmd = { "scribble", "create", args.filename }

	if directory then
		table.insert(cmd, "--directory")
		table.insert(cmd, directory)
	end

	if config.storage_dir then
		table.insert(cmd, "--storage-dir")
		table.insert(cmd, config.storage_dir)
	end

	utils.exec_cmd(cmd)
end

function M.select()
	local directory = utils.get_directory(config)
	local cmd = { "scribble", "list", "--porcelain" }

	if directory then
		table.insert(cmd, "--directory")
		table.insert(cmd, directory)
	end

	if config.storage_dir then
		table.insert(cmd, "--storage-dir")
		table.insert(cmd, config.storage_dir)
	end

	local actions = require("fzf-lua.actions")
	require("fzf-lua").fzf_exec(utils.format_cmd(cmd), {
		actions = {
			["default"] = actions.file_edit,
			["alt-s"] = actions.file_split,
			["alt-v"] = actions.file_vsplit,
			["alt-t"] = actions.file_tabedit,
		},
		prompt = directory .. "/",
		cwd = config.storage_dir .. "/" .. directory,
		winopts = {
			title = "Scratch files",
		},
		fn_transform = function(item)
			return string.gsub(item, "%s+", "/")
		end,
		previewer = config.previewer,
	})
end

local setup_usercmds = function()
	vim.api.nvim_create_user_command("ScribbleCreate", function(opts)
		local filename = opts.fargs[1] or vim.fn.input("Filename: ")
		M.create({ filename = filename })
	end, { nargs = "?" })

	vim.api.nvim_create_user_command("ScribbleSelect", function()
		M.select()
	end, { nargs = 0 })
end

---@param user_config scribble.Config?
function M.setup(user_config)
	config = vim.tbl_deep_extend("force", default_config, user_config or {})
	setup_usercmds()
end

---@param file_path string
function M.create_scratch_buf(file_path)
	local buf = vim.api.nvim_create_buf(false, true) -- not listed, scratch

	vim.api.nvim_buf_call(buf, function()
		vim.cmd(":edit " .. file_path)
	end)

	local floating_winopts = {
		relative = "editor",
		width = 60,
		height = 10,
		row = 10,
		col = 10,
		style = "minimal",
		border = "rounded",
	}
	vim.api.nvim_open_win(buf, true, floating_winopts)

	local opts = { noremap = true, silent = true, buffer = buf }

	local set = vim.keymap.set
	set("n", "q", ":wq<cr>", opts)
end

return M
