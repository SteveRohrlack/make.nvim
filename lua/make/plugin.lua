local Path = require("plenary.path")

local function isEOF(any)
	return #any == 1 and any[1] == ""
end

local M = {}

function M.setup() end

function M.run_command(opts)
	local cmd = "make " .. opts.fargs[1]
	local didErr = false

	vim.fn.jobstart(cmd, {
		stderr_buffered = true,
		on_stderr = function(_, data)
			if isEOF(data) then
				return
			end
			didErr = true
			vim.notify(data[1], vim.log.levels.ERROR, {
				title = cmd,
			})
		end,
		on_exit = function()
			if didErr then
				return
			end
			vim.notify("✅🔔📯", vim.log.levels.INFO, {
				title = cmd,
			})
		end,
	})
end

function M.find_targets(searchTerm)
	local searchResults = {}
	local file_path = Path:new("Makefile")

	local iterate = function(line)
		local target = line:match("^([%w-_]+):")
		if not target then
			return
		end

		if #searchTerm == 0 then
			table.insert(searchResults, target)
			return
		end

		local searchMatch = not (string.find(target, searchTerm) == nil)
		if searchMatch then
			table.insert(searchResults, target)
		end
	end

	for line in file_path:iter() do
		iterate(line)
	end

	return searchResults
end

return M
