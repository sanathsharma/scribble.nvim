local git = require("git")

local M = {}

local get_dir = function()
	return vim.g.scribble_dir or vim.fn.stdpath("data") .. "/scribble"
end

---@param str string
local get_user_input = function(str)
	local input = vim.fn.input(str)
	if input == "" or input == nil then
		return
	end

	return input:gsub("%s+", "_")
end

M.get_dir = get_dir

function M.create_branch()
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
	vim.cmd("write! ++p " .. file_path)

	return file_path
end

function M.create_filetype()
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
	vim.cmd("write! ++p " .. file_path)

	return file_path
end

function M.create_misc()
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
	vim.cmd("write! ++p " .. file_path)

	return file_path
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
	vim.api.nvim_create_user_command("ScribbleCreateBranch", function()
		local file_path = M.create_branch()
		vim.cmd("edit " .. file_path)
	end, {})
	vim.api.nvim_create_user_command("ScribbleCreateFiletype", function()
		local file_path = M.create_filetype()
		vim.cmd("edit " .. file_path)
	end, {})
	vim.api.nvim_create_user_command("ScribbleCreateMisc", function()
		local file_path = M.create_misc()
		vim.cmd("edit " .. file_path)
	end, {})

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
