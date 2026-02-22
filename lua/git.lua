local M = {}

function M.is_git_repo()
	local result = vim.system({ "git", "rev-parse", "--is-inside-work-tree" }, { text = true }):wait()
	return result.code == 0
end

function M.get_repo_name()
	local result = vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }):wait()
	return vim.fn.fnamemodify(vim.trim(result.stdout), ":t")
end

function M.get_branch_name()
	local result = vim.system({ "git", "branch", "--show-current" }, { text = true }):wait()
	return vim.trim(result.stdout)
end

return M
