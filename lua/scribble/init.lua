local git = require("git")

-- ---------------------------------------------------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------------------------------------------------

local get_dir = function()
	local dir = vim.g.scribble_dir or vim.fn.stdpath("data") .. "/scribble"
	return vim.fn.expand(dir)
end

---@param str string
local get_user_input = function(str)
	local input = vim.fn.input(str)
	if input == "" or input == nil then
		return
	end

	return input:gsub("%s+", "_")
end

---@return boolean
local is_visual_mode = function()
	local mode = vim.fn.mode()
	return mode == "v" or mode == "V" or mode == "\22"
end

---@class Range
---@field start table
---@field end table

---@param opts vim.api.keyset.create_user_command.command_args
---@return Range | nil
local compute_range = function(opts)
	local start_line_idx, end_line_idx

	-- Check if called from visual mode
	if is_visual_mode() then
		-- Visual mode: use '< and '> marks
		local vstart = vim.fn.getpos("'<'")
		local vend = vim.fn.getpos("'>'")
		start_line_idx = vstart[2] -- 1-indexed line
		end_line_idx = vend[2] -- 1-indexed line
	else
		-- Normal mode: use opts.line1 and opts.line2
		start_line_idx = opts.line1
		end_line_idx = opts.line2
	end

	local range = nil
	if opts.count ~= -1 then
		local end_line = vim.api.nvim_buf_get_lines(0, end_line_idx - 1, end_line_idx, true)[1]
		range = {
			start = { start_line_idx, 0 },
			["end"] = { end_line_idx, end_line:len() },
		}
	end

	return range
end

---@param range Range | nil
---@return string[]
local get_lines = function(range)
	if range == nil then
		return {}
	end
	local start_line = range.start[1]
	local end_line = range["end"][1]
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, true)
	vim.print(lines)
	return lines
end

---@param file_path string
local create_file = function(file_path)
	local parent_dir = vim.fs.dirname(file_path)

	vim.fn.system("mkdir -p " .. parent_dir)
	vim.cmd("edit " .. file_path)
	vim.cmd("write")
end

---@param file_path string
---@param range Range
local write_file = function(file_path, range)
	local lines = get_lines(range)
	vim.cmd("edit " .. file_path)
	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
	vim.cmd("write")
end

-- ---------------------------------------------------------------------------------------------------------------------
-- Exports
-- ---------------------------------------------------------------------------------------------------------------------

local M = {}

M.get_dir = get_dir

---@param range Range | nil
function M.create_branch(range)
	if not git.is_git_repo() then
		vim.notify("Not a git repository", vim.log.levels.ERROR)
		return
	end
	local file_name = get_user_input("File name: ")
	if file_name == "" or file_name == nil then
		return
	end
	local dir = get_dir()

	local repo_name = git.get_repo_name()
	local branch_name = git.get_branch_name()

	local parent_dir = dir .. "/" .. repo_name .. "/" .. branch_name

	local file_path = parent_dir .. "/" .. file_name
	create_file(file_path)
	if range ~= nil and is_visual_mode() then
		write_file(file_path, range)
	end

	return file_path
end

---@param range Range | nil
function M.create_filetype(range)
	if not git.is_git_repo() then
		vim.notify("Not a git repository", vim.log.levels.ERROR)
		return
	end
	local file_name = get_user_input("File name: ")
	if file_name == "" or file_name == nil then
		return
	end
	local dir = get_dir()
	local extension = string.match(file_name, "%.(.+)$")

	if not extension then
		return
	end

	local parent_dir = dir .. "/filetype/" .. extension

	local file_path = parent_dir .. "/" .. file_name
	create_file(file_path)
	if range ~= nil and is_visual_mode() then
		write_file(file_path, range)
	end

	return file_path
end

---@param range Range | nil
function M.create_misc(range)
	if not git.is_git_repo() then
		vim.notify("Not a git repository", vim.log.levels.ERROR)
		return
	end
	local file_name = get_user_input("File name: ")
	if file_name == "" or file_name == nil then
		return
	end
	local dir = get_dir()

	local file_path = dir .. "/misc/" .. file_name
	create_file(file_path)
	if range ~= nil and is_visual_mode() then
		write_file(file_path, range)
	end

	return file_path
end

---@param range Range | nil
function M.create(range)
	require("fzf-lua").fzf_exec({
		"on Branch level",
		"on Filetype level",
		"as Misc.",
	}, {
		prompt = "Create scratch: ",
		winopts = {
			titile = "Create Scratch Files",
			fullscreen = false,
			height = 0.3,
			width = 0.3,
		},
		fzf_opts = {
			["--multi"] = false,
			["--preview-window"] = "up:50%",
		},
		actions = {
			["default"] = function(selected)
				if selected[1] == "on Branch level" then
					M.create_branch(range)
				elseif selected[1] == "on Filetype level" then
					M.create_filetype(range)
				elseif selected[1] == "as Misc." then
					M.create_misc(range)
				end
			end,
		},
	})
end

function M.list_branch_files()
	if not git.is_git_repo() then
		vim.notify("Not a git repository", vim.log.levels.ERROR)
		return
	end
	local dir = get_dir()

	local repo_name = git.get_repo_name()
	local branch_name = git.get_branch_name()

	local parent_dir = dir .. "/" .. repo_name .. "/" .. branch_name

	vim.fn.mkdir(parent_dir, "p")
	require("fzf-lua").files({
		cwd = parent_dir,
		prompt = repo_name .. "/" .. branch_name .. "/",
		winopts = {
			titile = "Scratch Files",
		},
		hidden = true,
	})
end

function M.list_all_files()
	if not git.is_git_repo() then
		vim.notify("Not a git repository", vim.log.levels.ERROR)
		return
	end
	local dir = get_dir()

	require("fzf-lua").files({
		cwd = dir,
		prompt = dir .. "/",
		winopts = {
			titile = "All Scratch Files",
		},
		hidden = true,
	})
end

function M.list_filetype_files()
	if not git.is_git_repo() then
		vim.notify("Not a git repository", vim.log.levels.ERROR)
		return
	end
	local dir = get_dir()
	local extension = get_user_input("Filetype: ")

	if extension == "" or extension == nil then
		vim.notify("Invalid filetype", vim.log.levels.ERROR)
		return
	end

	require("fzf-lua").files({
		cwd = dir .. "/filetype/" .. extension,
		prompt = "filetype/",
		winopts = {
			titile = "Filetype Scratch Files",
		},
		hidden = true,
	})
end

function M.setup_usercmds()
	vim.api.nvim_create_user_command("ScribbleCreateBranch", function(opts)
		local range = compute_range(opts)
		local file_path = M.create_branch(range)
		vim.cmd("edit " .. file_path)
	end, { range = true })
	vim.api.nvim_create_user_command("ScribbleCreateFiletype", function(opts)
		local range = compute_range(opts)
		local file_path = M.create_filetype(range)
		vim.cmd("edit " .. file_path)
	end, { range = true })
	vim.api.nvim_create_user_command("ScribbleCreateMisc", function(opts)
		local range = compute_range(opts)
		local file_path = M.create_misc(range)
		vim.cmd("edit " .. file_path)
	end, { range = true })
	vim.api.nvim_create_user_command("ScribbleCreate", function(opts)
		local range = compute_range(opts)
		M.create(range)
	end, { range = true })

	vim.api.nvim_create_user_command("ScribbleListBranch", function()
		M.list_branch_files()
	end, {})
	vim.api.nvim_create_user_command("ScribbleListAll", function()
		M.list_all_files()
	end, {})
	vim.api.nvim_create_user_command("ScribbleListFiletype", function()
		M.list_filetype_files()
	end, {})
end

function M.setup()
	M.setup_usercmds()
end

return M
