local git = require("git")

local M = {}

---@param args string[]
function M.format_cmd(args)
	return table.concat(args, " ")
end

---@param config scribble.Config
function M.get_directory(config)
	if not git.is_git_repo() and config.scope ~= "global" then
		vim.notify("Not a git repository", vim.log.levels.ERROR)
		return
	end

	local repo_name = git.get_repo_name()
	local branch_name = git.get_branch_name()

	local directory = nil
	if config.scope == "repo" then
		directory = repo_name
	elseif config.scope == "branch" then
		directory = repo_name .. "/" .. branch_name
	end

	return directory
end

---@param cmd string[]
function M.exec_cmd(cmd)
	local output = {}
	local job = vim.fn.jobstart(M.format_cmd(cmd), {
		on_stdout = function(_, data, _)
			vim.list_extend(output, data)
		end,
		on_exit = function(_, exit_code, _)
			--todo: add to log file instead of printing
			print("Exited with code: " .. exit_code)
		end,
	})
	vim.fn.jobwait({ job })

	-- vim.print("cmd: ", M.format_cmd(cmd))
	-- vim.print("output: ", output)
	return output
end

---@param t string[]
function M.filter_empty_strings(t)
	local result = {}
	for _, str in ipairs(t) do
		if str ~= "" then
			table.insert(result, str)
		end
	end
	return result
end

---@param str string
---@param delimiter string
function M.split_string(str, delimiter)
    local t = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(t, vim.trim(match))
    end
    return t
end

---@param output string[]
---@return scribble.File[]
function M.parse_porcelain_output(output)
	local files = {}
	for _, line in ipairs(output) do
		if line == "" then
			goto continue
		end

		local parts = M.split_string(line, " ")
		local storage_dir = parts[1]
		local directory = parts[2]
		local path = parts[3]
		table.insert(files, { storage_dir = storage_dir, path = path, directory = directory })

		::continue::
	end

	return files
end

---@param file scribble.File
M.get_full_path = function(file)
	if file.directory == "" then
		return file.storage_dir .. "/" .. file.path
	end
	return file.storage_dir .. "/" .. file.directory .. "/" .. file.path
end

return M
