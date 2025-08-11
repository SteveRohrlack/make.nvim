local Path = require("plenary.path")

local MAX_INT = 2 ^ 53 - 1

local function is_eof(any)
	return #any == 1 and any[1] == ""
end

local function is_makefile()
	return vim.bo.filetype == "make"
end

local function parse_make_target(any)
	return any:match("^([%w-_]+):")
end

local function find_buffer_targets()
	local targets = {}

	local bufnr = vim.api.nvim_get_current_buf()
	local last_line = vim.api.nvim_buf_line_count(bufnr)
	local file_lines = vim.api.nvim_buf_get_lines(bufnr, 0, last_line, true)

	local iterate = function(line_nr, line)
		local target = parse_make_target(line)
		if not target then
			return
		end

		targets[line_nr] = target
	end

	for i, line in ipairs(file_lines) do
		iterate(i, line)
	end

	return targets
end

local function find_nearest_buffer_target(targets)
	if not is_makefile() then
		return
	end

	if not targets then
		targets = find_buffer_targets()
	end

	local cursor = vim.api.nvim_win_get_cursor(0)
	local current_line, _ = unpack(cursor)

	local closest_to_cursor = MAX_INT
	local nearest_target = {}
	local target_line = 0

	local function iterate(line_nr, target)
		local diff = math.abs(current_line - line_nr)
		if diff < closest_to_cursor then
			closest_to_cursor = diff
			nearest_target = target
			target_line = line_nr
		end
		if diff == 0 then
			return
		end
	end

	for line_nr, target in pairs(targets) do
		iterate(line_nr, target)
	end

	return nearest_target, target_line
end

local M = {}

function M.setup() end

function M.run_nearest()
	local target, _ = find_nearest_buffer_target()
	M.run_target(target)
end

function M.run_selected(opts)
	M.run_target(opts.fargs[1])
end

function M.run_target(target)
	if not target then
		return
	end

	local cmd = "make " .. target
	local didErr = false

	vim.fn.jobstart(cmd, {
		stderr_buffered = true,
		on_stderr = function(_, data)
			if is_eof(data) then
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

	if not file_path:exists() then
		return
	end

	local iterator = function(line)
		local target = parse_make_target(line)
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
		iterator(line)
	end

	return searchResults
end

function M.decorate_makefile(opts)
	if not opts.file or not is_makefile() then
		return
	end

	local targets = find_buffer_targets()
	local _, nearest_target_line = find_nearest_buffer_target(targets)
	local bufnr = vim.api.nvim_get_current_buf()

	vim.fn.sign_unplace("MakeTarget", {
		buffer = bufnr,
	})

	for line_nr, _ in pairs(targets) do
		local name = "MakeTarget"
		if line_nr == nearest_target_line then
			name = "MakeTargetHighlight"
		end
		vim.fn.sign_place(line_nr, "MakeTarget", name, bufnr, {
			lnum = line_nr,
		})
	end
end

return M
